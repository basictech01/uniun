// Real-device verification of the modelSwitch scheduler tier (issue #160
// follow-on — see docs/SHIVA/scheduling.md §3, "Model switch tier").
//
// What it verifies:
//   1. A gentle model-switch operation (forcePreempt:false) waits for a
//      real, currently-streaming generation to finish before running —
//      it must NOT call stopGeneration() on the in-flight session.
//   2. A forced model-switch operation (forcePreempt:true) cancels a
//      real, currently-streaming generation immediately, the same way
//      chat already does (scheduler_preemption_test.dart).
//
// The first test (below) does not require a second downloaded model — the
// coordination being verified (wait-vs-preempt against the scheduler) is
// orthogonal to which model the `action` closure actually activates. Its
// `action` closures are trivial no-ops standing in for
// `AIModelRepositoryImpl.activateModel`/`deleteModel`'s real work, which
// is already covered by `test/data/repositories/ai_model_repository_impl_test.dart`
// (mocked `AIModelRunner`) — that test's job is only to prove the
// scheduler coordination itself holds against a REAL native generation,
// not to re-verify the native install/uninstall calls.
//
// The SECOND test needs two already-downloaded local models (via Shiv →
// AI Model Selection). It drives the REAL `AIModelRepositoryImpl.
// activateModel()` — the actual production entry point, not a stand-in —
// switching between them while a real generation is in flight on the
// first, and confirms flutter_gemma's active model identity
// (`FlutterGemma.activeModelSpec`) genuinely changes afterward. It does
// NOT test the forced/delete path with real models — deleting one of your
// downloaded models is destructive and not worth risking just for this
// test; the forced-preemption *scheduling* logic is already fully proven
// by the first test's dummy-action version.
//
// PASS path: result starts with `OK:` → both gentle and forced ordering
//            held on the real native engine (test 1); the real swap
//            actually changed flutter_gemma's active model (test 2).
// SKIP path: result starts with `SKIP:` → no model installed yet (test 1)
//            or fewer than 2 downloaded models (test 2). Install more via
//            Shiv → AI Model Selection, then re-run.
// FAIL path: assertion fires — the modelSwitch tier's ordering guarantee,
//            or the real swap itself, broke.
//
// How to run:
//
//   flutter test integration_test/scheduler_model_switch_test.dart -d <device-id>

import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';

import 'support/test_model.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> doOneShot(
    String prompt,
    CancelToken cancel, {
    int maxTokens = 256,
  }) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
    final chat = await model.openChat(temperature: 0.8, topK: 40);
    try {
      await chat.addQueryChunk(Message.text(text: prompt));
      final buf = StringBuffer();
      await for (final r in chat.generateChatResponseAsync()) {
        if (cancel.isCancelled) {
          await chat.stopGeneration();
          break;
        }
        if (r is TextResponse) buf.write(r.token);
      }
      return buf.toString();
    } finally {
      await chat.close();
    }
  }

  testWidgets(
    'gentle model switch waits for a real generation to finish, forced '
    'switch preempts it immediately',
    (tester) async {
      if (!FlutterGemma.hasActiveModel() &&
          !await provisionTestModel(AIModelId.gemma4E2b)) {
        // ignore: avoid_print
        print('SKIP: no active model on device — install one via Shiv first');
        return;
      }

      final scheduler = InferenceScheduler();
      scheduler.notifyLoadedModel('integration_test_model');
      final settings = AppSettingsStore(await SharedPreferences.getInstance());
      final runner = AIModelRunner(scheduler, settings, FlutterGemmaGatewayImpl());

      // ── Part 1: gentle switch waits ──────────────────────────────────
      final order = <String>[];
      final natarajFuture = scheduler.run<String?>(
        kind: LlmTaskKind.nataraj,
        modelId: 'integration_test_model',
        work: (cancel) async {
          final r = await doOneShot(
            'Write a 200-word paragraph about the history of maps.',
            cancel,
            maxTokens: 400,
          );
          order.add('nataraj');
          return r;
        },
      );
      await Future.delayed(const Duration(milliseconds: 500));
      expect(scheduler.runningKind, equals(LlmTaskKind.nataraj),
          reason: 'nataraj should be running before the gentle switch arrives');

      final gentleSwitch = runner.runExclusiveModelOperation<void>(
        forcePreempt: false,
        action: () async => order.add('gentle-switch'),
      );
      await Future.wait([natarajFuture, gentleSwitch]);

      expect(order, ['nataraj', 'gentle-switch'],
          reason: 'gentle switch must not preempt the real generation');

      // ── Part 2: forced switch preempts ───────────────────────────────
      order.clear();
      final natarajFuture2 = scheduler.run<String?>(
        kind: LlmTaskKind.nataraj,
        modelId: 'integration_test_model',
        work: (cancel) async {
          final r = await doOneShot(
            'Write a 200-word paragraph about the history of bridges.',
            cancel,
            maxTokens: 400,
          );
          // A preempted run unwinds before the switch runs; only a finished
          // one counts as "completed after the switch".
          if (!cancel.isCancelled) order.add('nataraj2');
          return r;
        },
      );
      await Future.delayed(const Duration(milliseconds: 500));
      expect(scheduler.runningKind, equals(LlmTaskKind.nataraj));

      final forcedSwitch = runner.runExclusiveModelOperation<void>(
        forcePreempt: true,
        action: () async => order.add('forced-switch'),
      );
      await forcedSwitch;
      await natarajFuture2; // re-queued run completes after the switch

      expect(order.first, equals('forced-switch'),
          reason: 'forced switch must preempt the real generation immediately');
      expect(order, contains('nataraj2'),
          reason: 're-queued nataraj must still complete after the switch');

      // ignore: avoid_print
      print('OK: gentle switch waited for the real generation to finish; '
          'forced switch preempted it immediately');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    'a real activateModel() switch between two downloaded models waits '
    'for an in-flight generation, then genuinely changes the active model',
    (tester) async {
      await configureDependencies();
      final catalog = getIt<AIModelRepository>();
      final settings = getIt<AppSettingsStore>();
      final scheduler = getIt<InferenceScheduler>();

      final downloaded = await catalog.getDownloadedModelIds();
      if (downloaded.length < 2) {
        // ignore: avoid_print
        print('SKIP: only ${downloaded.length} model(s) downloaded — need '
            '2 (Shiv → AI Model Selection) to test a real swap');
        return;
      }
      final modelA = downloaded.elementAt(0);
      final modelB = downloaded.elementAt(1);
      // ignore: avoid_print
      print('using modelA=$modelA, modelB=$modelB');

      // Establish a known starting point: A active for real.
      await settings.setActiveModelId(modelA);
      final activatedA = await catalog.activateModel(modelA);
      expect(activatedA.isRight(), isTrue,
          reason: 'failed to activate modelA: $activatedA');
      expect(FlutterGemma.hasActiveModel(), isTrue);
      final specBefore = FlutterGemma.activeModelSpec;

      // Real generation running against A.
      final order = <String>[];
      final natarajFuture = scheduler.run<String?>(
        kind: LlmTaskKind.nataraj,
        modelId: modelA.name,
        work: (cancel) async {
          final model = await FlutterGemma.getActiveModel(maxTokens: 400);
          final chat = await model.openChat(temperature: 0.8, topK: 40);
          try {
            await chat.addQueryChunk(Message.text(
                text: 'Write a 200-word paragraph about the history of clocks.'));
            final buf = StringBuffer();
            await for (final r in chat.generateChatResponseAsync()) {
              if (cancel.isCancelled) {
                await chat.stopGeneration();
                break;
              }
              if (r is TextResponse) buf.write(r.token);
            }
            order.add('nataraj');
            return buf.toString();
          } finally {
            await chat.close();
          }
        },
      );
      await Future.delayed(const Duration(milliseconds: 500));
      expect(scheduler.runningKind, equals(LlmTaskKind.nataraj),
          reason: 'nataraj should be running before the switch to B arrives');

      // The REAL production entry point — same call setActiveModel() makes.
      await settings.setActiveModelId(modelB);
      final switchFuture = catalog.activateModel(modelB);

      final natarajResult = await natarajFuture;
      final switched = await switchFuture;

      expect(order, ['nataraj'],
          reason: 'the real generation on A must complete untouched, not '
              'be cancelled by the switch to B');
      expect(natarajResult, isNotNull);
      expect(natarajResult, isNotEmpty);
      expect(switched.isRight(), isTrue,
          reason: 'failed to activate modelB: $switched');

      final specAfter = FlutterGemma.activeModelSpec;
      expect(specAfter?.name, isNot(equals(specBefore?.name)),
          reason: 'flutter_gemma\'s active model identity should have '
              'genuinely changed from A to B, not just our app settings');

      // ignore: avoid_print
      print('OK: real generation on modelA completed untouched '
          '(${natarajResult?.length} chars), then the switch to modelB '
          'genuinely changed flutter_gemma\'s active model '
          '(${specBefore?.name} -> ${specAfter?.name})');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
