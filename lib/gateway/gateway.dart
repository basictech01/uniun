import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/note_model.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:uniun/gateway/central_relay_manager.dart';
import 'package:uniun/gateway/gateway_init_message.dart';

/// Entry point for the Gateway isolate (Isolate 2).
///
/// Spawned once at app launch:
/// ```dart
/// await Isolate.spawn(gatewayEntryPoint, GatewayInitMessage(
///   isarDirectory: (await getApplicationDocumentsDirectory()).path,
///   myPubkey: currentUserPubkey,
/// ));
/// ```
///
/// The isolate stays alive for the lifetime of the app because
/// [CentralRelayManager] holds active [Timer]s and stream subscriptions.
/// No [SendPort] is needed — Isar is the shared message bus between isolates.
Future<void> gatewayEntryPoint(GatewayInitMessage init) async {
  // Open a separate Isar handle pointing at the same DB file as Isolate 1.
  // isar_community supports concurrent access from multiple isolates.
  final isar = await Isar.open(
    [NoteModelSchema, EventQueueModelSchema, RelayModelSchema],
    directory: init.isarDirectory,
    // Use the same instance name so it shares the same on-disk file.
    name: Isar.defaultName,
  );

  final manager = CentralRelayManager(
    isar: isar,
    myPubkey: init.myPubkey,
  );

  await manager.start();

  // The isolate's event loop is kept running by the timers and
  // stream subscriptions held by [manager]. Nothing more to do here.
}
