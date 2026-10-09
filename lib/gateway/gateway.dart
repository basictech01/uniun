import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/gateway/cleanup/cleanup_manager.dart';
import 'package:uniun/gateway/gateway_init_message.dart';
import 'package:uniun/gateway/orchestrator/gateway_orchestrator.dart';
import 'package:uniun/gateway/subscriptions/sync_window.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/domain/services/nip17_encryption_service.dart';

/// Entry point for the Gateway isolate (Isolate 2).
///
/// Spawned once at app launch:
/// ```dart
/// await Isolate.spawn(gatewayEntryPoint, GatewayInitMessage(
///   isarDirectory: (await getApplicationDocumentsDirectory()).path,
/// ));
/// ```
///
/// The isolate stays alive for the lifetime of the app because
/// [CentralRelayManager] holds active [Timer]s and stream subscriptions.
Future<void> gatewayEntryPoint(GatewayInitMessage init) async {
  try {
    // 2. Attempt to open Isar
    final isar = await Isar.open(
      isarSchemas,
      directory: init.isarDirectory,
      name: Isar.defaultName,
    );

    final recentSyncWindow = init.recentSyncWindowDays != null
        ? Duration(days: init.recentSyncWindowDays!)
        : kRecentSyncWindow;

    final orchestrator = GatewayOrchestrator(
      isar: isar,
      activePubkey: init.pubkeyHex,
      activePrivkey: init.privkeyHex,
      recentSyncWindow: recentSyncWindow,
    );
    final nip17Service = Nip17EncryptionService(
      isar,
      NoteRelationRepositoryImpl(isar: isar),
      privkeyHex: init.privkeyHex,
    );

    await orchestrator.start();
    nip17Service.start();

    final retention = init.autoDeleteOldNotesDays != null
        ? Duration(days: init.autoDeleteOldNotesDays!)
        : null;
    CleanupManager(
      isar: isar,
      activePubkey: init.pubkeyHex,
      retention: retention,
    ).start();

    debugPrint("Gateway isolate fully started!");
  } catch (e, stackTrace) {
    // 4. Catch and print any silent crashes
    throw Exception("$e\n$stackTrace");
  }
}

/// Bootstrap the Gateway isolate.
class GatewayBootstrap {
  static Isolate? _isolate;
  static Future<void>? _starting;

  static Future<void> start() async {
    if (_isolate != null) return;
    if (_starting != null) return _starting;
    final starting = _spawn();
    _starting = starting;
    try {
      await starting;
    } finally {
      _starting = null;
    }
  }

  static Future<void> _spawn() async {
    final dir = await getApplicationDocumentsDirectory();

    // Resolve the active user's keys in the main isolate. FlutterSecureStorage
    // and SharedPreferences are unavailable in background isolates, so we hand
    // off the raw hex values via [GatewayInitMessage]. Returns null when no
    // user is logged in yet.
    final keys = await getIt<UserRepository>().getActiveKeysHex();
    final autoDeleteDays = getIt<AppSettingsStore>().autoDeleteOldNotesDays;
    final recentSyncWindowDays = getIt<AppSettingsStore>().recentSyncWindowDays;

    _isolate = await Isolate.spawn(
      gatewayEntryPoint,
      GatewayInitMessage(
        isarDirectory: dir.path,
        privkeyHex: keys?.privkeyHex,
        pubkeyHex: keys?.pubkeyHex,
        autoDeleteOldNotesDays: autoDeleteDays,
        recentSyncWindowDays: recentSyncWindowDays,
      ),
    );
  }

  /// Stop the old account's relay and DM subscriptions before clearing Isar.
  static Future<void> stop() async {
    await _starting;
    final isolate = _isolate;
    if (isolate != null) {
      final exited = ReceivePort();
      isolate.addOnExitListener(exited.sendPort);
      isolate.kill(priority: Isolate.immediate);
      try {
        await exited.first.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // The isolate may have already exited before the listener was added.
      } finally {
        exited.close();
      }
    }
    _isolate = null;
  }
}
