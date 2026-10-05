// Full end-to-end verification of a LOCAL (on-device) Gana run, run against
// the REAL app — the local-backend counterpart to
// `gana_cloud_engine_e2e_test.dart`. Real DI (`configureDependencies`), the
// real on-device Isar, the real `GanaEngine`, the real `GatewayBootstrap`
// sync isolate, and a real on-device `flutter_gemma` inference call.
//
// This is the ONLY way to verify local-model Gana generation for real:
// `FlutterGemma.hasActiveModel()` is a static gate from the third-party
// plugin that always reads false in a plain `flutter test` unit test (no
// platform channel involved outside a real device), so
// `test/features/shiv/gana/engine/gana_engine_test.dart` can only prove the
// "no model → skip" branch, never a real local generate+publish.
//
// Precondition this test does NOT set up: a downloaded on-device model
// (open Shiv → Select AI model → download one first) — matches
// `flutter_gemma_bg_isolate_test.dart`'s own precondition. Missing it → SKIP.
// An active identity IS self-provisioned if missing, same as the cloud e2e
// test, and never touches the device's globally active LLM backend.
//
// `FlutterGemma.initialize()` IS called here (same engine list as
// `main.dart`) — `configureDependencies()` alone never touches the plugin.
// A SECOND step is also required: `AIModelRepository.getActiveModel()` (via
// `GetActiveAIModelUseCase`) is what actually restores flutter_gemma's
// in-memory "active model" registration from the persisted preference +
// on-disk file on a cold process start (see
// `ai_model_repository_impl.dart`'s `getActiveModel()` — it calls
// `FlutterGemma.installModel(...).install()` again, which is a no-op re-link
// when the file is already there). `main.dart` never calls this eagerly
// either — it only happens the first time any Shiv screen touches it in a
// real app session. Without both steps, `hasActiveModel()` reads false on
// EVERY device regardless of whether a model is actually downloaded.
//
// Side effect on success: publishes one real, permanent Kind-1 note (Feed
// Freedom, no delete) to the relay. By request, no local cleanup either —
// the Gana definition, its run log, and the note all stay in local Isar,
// so the test post is actually visible in the app afterward.
//
//   flutter test integration_test/gana_local_engine_e2e_test.dart -d <device-id>

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';

import 'support/test_model.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/models/gana_run_model.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/features/shiv/gana/engine/gana_engine.dart';
import 'package:uniun/gateway/gateway.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('a local (on-device) standalone Gana runs end-to-end and reaches a real relay',
      () async {
    await configureDependencies();
    final isar = getIt<Isar>();

    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    // Rehydrates flutter_gemma's in-memory active-model state from the
    // persisted preference + on-disk file — see the file header.
    await getIt<GetActiveAIModelUseCase>().call();

    if (!FlutterGemma.hasActiveModel() &&
        !await provisionTestModel(AIModelId.qwen25_05b)) {
      // ignore: avoid_print
      print('SKIP: no active on-device model — open Shiv → Select AI model → '
          'download one first');
      return;
    }

    var keys = await getIt<UserRepository>().getActiveKeysHex();
    if (keys == null) {
      final generated = await getIt<UserRepository>().generateKey();
      final ok = generated.fold((f) {
        // ignore: avoid_print
        print('SKIP: no active identity and generating one failed: $f');
        return false;
      }, (_) => true);
      if (!ok) return;
      keys = await getIt<UserRepository>().getActiveKeysHex();
      // ignore: avoid_print
      print('provisioned a fresh identity for this run: '
          'pubkey=${keys?.pubkeyHex}');
    }

    await GatewayBootstrap.start();

    final ganaId = 'e2e-local-test-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.ganaModels.put(
        GanaModel()
          ..ganaId = ganaId
          ..name = 'E2E local-model test Gana (auto-deleted)'
          ..taskPrompt = 'Write one short, friendly sentence (max 20 words) '
              'announcing that this note was posted by a Gana AI agent '
              'running on an on-device (local) model, as a test of that '
              'feature. Clearly say it is a test post.'
          ..outputType = GanaOutputType.feed
          // desiredBackend/desiredModelId left null — "use whichever
          // on-device model is currently active", so this never
          // model-mismatch-skips regardless of which model is installed.
          ..triggerMode = GanaTriggerMode.oneShot
          ..enabled = true
          ..createdAt = now
          ..updatedAt = now,
      );
    });

    String? publishedEventId;
    final engine = getIt<GanaEngine>();
    await engine.start();

    GanaRunStatus? status;
    // Local generation is much slower than cloud (cold model load +
    // decode) — give it a generous budget.
    final runDeadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(runDeadline)) {
      final run =
          await isar.ganaRunModels.filter().ganaIdEqualTo(ganaId).findFirst();
      if (run != null) {
        status = run.status;
        publishedEventId = run.outputEventId;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await engine.stop();

    expect(status, isNotNull,
        reason: 'no GanaRunModel appeared within 90s — engine never fired');
    expect(status, GanaRunStatus.succeeded,
        reason: 'expected the local run to succeed');
    expect(publishedEventId, isNotNull);

    final eventId = publishedEventId!;
    var acked = false;
    final ackDeadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(ackDeadline)) {
      final queued = await isar.eventQueueModels
          .filter()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (queued != null && queued.sentCount > 0) {
        acked = true;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    if (!acked) {
      // ignore: avoid_print
      print('FAIL: eventId=$eventId generated + enqueued locally but no '
          'relay OK ack arrived within 30s — check relay connectivity');
      fail('event never reached a relay (no OK ack)');
    }
    // ignore: avoid_print
    print('OK: local Gana published + relay-acked eventId=$eventId');
  }, timeout: const Timeout(Duration(seconds: 150)));
}
