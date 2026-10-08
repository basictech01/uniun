import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';

/// Verification scenarios for [InferenceScheduler] — one test per scenario
/// listed in `docs/SHIVA/scheduling.md` §10.
///
/// The scheduler is async (work is dispatched via `Future(...)` microtasks),
/// so each test yields control with `Future.delayed(Duration.zero)` between
/// steps to let the scheduler pump.
void main() {
  // Helper: build a work closure that records its dispatch + completion in
  // [trace] and polls the cancel token between simulated "tokens".
  Future<void> Function(CancelToken) recordingWork({
    required List<String> trace,
    required String label,
    int tokens = 4,
    Duration perToken = const Duration(milliseconds: 10),
  }) =>
      (cancel) async {
        trace.add('start:$label');
        for (var i = 0; i < tokens; i++) {
          if (cancel.isCancelled) {
            trace.add('cancel:$label@$i');
            return;
          }
          await Future.delayed(perToken);
        }
        trace.add('finish:$label');
      };

  // Helper: a "blocker" closure used to make sure other jobs are already
  // queued when the scheduler's picker runs (otherwise the first-submitted
  // job is dispatched synchronously before subsequent siblings even exist).
  Future<void> Function(CancelToken) blockerFor(Duration d) =>
      (_) => Future.delayed(d);

  // Helper: cancel marker matcher that accepts cancel at any token index.
  bool cancelledAtAnyTokenFor(List<String> trace, String label) =>
      trace.any((s) => s.startsWith('cancel:$label@'));

  group('isChatRunning', () {
    test('is false when idle, true during a chat job, false after', () async {
      final s = InferenceScheduler()..notifyLoadedModel('m');
      expect(s.isChatRunning, isFalse);

      final job = s.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 60)),
      );
      await Future.delayed(const Duration(milliseconds: 20));
      expect(s.isChatRunning, isTrue);

      await job;
      expect(s.isChatRunning, isFalse);
    });

    test('is false while a job of another kind runs', () async {
      final s = InferenceScheduler()..notifyLoadedModel('m');
      final jobs = [
        for (final kind in [
          LlmTaskKind.extract,
          LlmTaskKind.gana,
          LlmTaskKind.nataraj,
        ])
          s.run<void>(
            kind: kind,
            modelId: 'm',
            work: blockerFor(const Duration(milliseconds: 40)),
          ),
      ];
      await Future.delayed(const Duration(milliseconds: 15));

      expect(s.isChatRunning, isFalse);
      await Future.wait(jobs);
    });
  });

  group('Scenario 1 — chat preempts nataraj at the next token boundary', () {
    test('chat (T0) cancels running nataraj and runs first', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // Long nataraj job — 20 tokens × 10 ms = 200 ms.
      final natarajFuture = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'nataraj', tokens: 20),
      );

      // Let the scheduler pick it up.
      await Future.delayed(const Duration(milliseconds: 30));
      expect(trace.first, 'start:nataraj');

      // Chat arrives; should preempt.
      final chatFuture = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'chat', tokens: 3),
      );

      // Give the scheduler a beat to deliver the cancel + dispatch chat.
      await chatFuture;
      // Nataraj was cancelled — it should NOT complete (because it gets
      // re-queued). Wait for the re-queued run to finish before asserting.
      await natarajFuture;

      // Cancel signal landed at SOME token boundary (exact index depends on
      // microtask timing; doesn't matter — what matters is preemption happened).
      expect(cancelledAtAnyTokenFor(trace, 'nataraj'), isTrue);
      // Chat finished before nataraj's eventual finish (re-queued run).
      final chatFinishIdx = trace.indexOf('finish:chat');
      final natarajFinishIdx = trace.indexOf('finish:nataraj');
      expect(chatFinishIdx, isNonNegative);
      expect(natarajFinishIdx, isNonNegative);
      expect(chatFinishIdx, lessThan(natarajFinishIdx));
    });
  });

  group('Scenario 2 — vruntime alternates nataraj/gana inside T4', () {
    test('after nataraj burns time, gana wins next pick', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // First nataraj completes — accumulates vruntime[nataraj] ≈ 40 ms.
      await scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n1', tokens: 4),
      );

      // Now both nataraj and gana queued at the same time, no foreground.
      // gana's vruntime is 0 (newcomer seeded from min); nataraj's is ~40 ms.
      // Picker should pick gana first.
      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'g1', tokens: 2),
      );
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n2', tokens: 2),
      );
      await Future.wait([g, n]);

      expect(trace.indexOf('start:g1'), lessThan(trace.indexOf('start:n2')));
    });
  });

  group('Scenario 3 — Gana cron deadline promotes to T3', () {
    test('past-due deadline beats a T4 nataraj', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // Block the scheduler so both jobs are queued before the picker runs.
      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 50)),
      );

      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 2),
      );
      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        deadline: DateTime.now().subtract(const Duration(seconds: 1)),
        work: recordingWork(trace: trace, label: 'g', tokens: 2),
      );

      await Future.wait([blocker, n, g]);

      // After the blocker finishes the picker sees [n at T4, g at T3] →
      // T3 wins, g starts first.
      expect(trace.indexOf('start:g'), lessThan(trace.indexOf('start:n')));
    });
  });

  group('Scenario 4 — Nataraj page focus hoists nataraj to T1', () {
    test('foreground=nataraj makes a queued nataraj win over a queued gana',
        () async {
      final scheduler = InferenceScheduler();
      scheduler.setForeground(LlmTaskKind.nataraj);
      final trace = <String>[];

      // Blocker so both queue up before picker runs.
      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 50)),
      );

      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'g', tokens: 2),
      );
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 2),
      );
      await Future.wait([blocker, n, g]);

      // After blocker finishes: queue [g at T4, n at T1] → n wins.
      expect(trace.indexOf('start:n'), lessThan(trace.indexOf('start:g')));
    });
  });

  group('Scenario 5 — T2 soft budget is recorded per job', () {
    // The 60% rule lives over a 5-minute window of real wall time; rather
    // than time-travelling, just verify that an extract job advances its
    // vruntime (the same field the budget sampler reads from). The full
    // sliding-window assertion is covered by the explicit budget pseudocode
    // in scheduling.md §4 and the scheduler's _t2BudgetExceeded helper.
    test('extract jobs accumulate vruntime in the kind table', () async {
      final scheduler = InferenceScheduler();
      expect(scheduler.vruntimeSnapshot[LlmTaskKind.extract], isNull);

      await scheduler.run<void>(
        kind: LlmTaskKind.extract,
        modelId: 'm',
        work: (_) async => await Future.delayed(const Duration(milliseconds: 30)),
      );
      expect(scheduler.vruntimeSnapshot[LlmTaskKind.extract], greaterThan(0.0));
    });
  });

  group('Scenario 6 — model affinity prefers same-model', () {
    test('with loadedModelId=A, A is picked over B at the same tier',
        () async {
      final scheduler = InferenceScheduler();
      scheduler.notifyLoadedModel('A');
      final trace = <String>[];

      // Blocker so both candidates are queued before the picker runs.
      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'A',
        work: blockerFor(const Duration(milliseconds: 50)),
      );

      final b = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'B', tokens: 2),
      );
      final a = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'A',
        work: recordingWork(trace: trace, label: 'A', tokens: 2),
      );
      await Future.wait([blocker, a, b]);

      // After blocker, queue is [B (model B), A (model A)] both at T4.
      // _loadedModelId=A → same-model filter keeps [A] → A wins.
      expect(trace.indexOf('start:A'), lessThan(trace.indexOf('start:B')));
    });
  });

  group('Scenario 7 — foregroundHint:true promotes extract to T1', () {
    test('extract with foregroundHint preempts running nataraj', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 30));

      final e = scheduler.run<void>(
        kind: LlmTaskKind.extract,
        modelId: 'm',
        foregroundHint: true,
        work: recordingWork(trace: trace, label: 'e', tokens: 2),
      );

      await e; // extract finishes
      await n; // nataraj re-queued, eventually finishes

      expect(cancelledAtAnyTokenFor(trace, 'n'), isTrue);
      expect(trace.indexOf('finish:e'), lessThan(trace.indexOf('finish:n')));
    });
  });

  group('Scenario 8 — out-of-scope: gana_workmanager isolate', () {
    // The background isolate (`lib/features/shiv/gana/engine/gana_workmanager
    // .dart`) cannot use this scheduler — no DI, separate Isar handle. By
    // design. There is nothing to unit-test here; the assertion is doc-only.
    test('isolate exemption is doc-only', () {
      expect(true, isTrue);
    });
  });

  group('Cancel accounting — cancelled jobs still pay vruntime', () {
    test('preempted nataraj keeps its partial vruntime', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 25));

      final c = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: (_) async {},
      );
      await c;
      await n;

      // After the preempt + re-queue + eventual finish, vruntime is positive.
      expect(
        scheduler.vruntimeSnapshot[LlmTaskKind.nataraj],
        greaterThan(0.0),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Additional coverage beyond §10 — robustness scenarios.
  // ────────────────────────────────────────────────────────────────────────

  group('Sequential chats — scheduler stays available across turns', () {
    test('three sequential chats all complete in order', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      for (final label in ['c1', 'c2', 'c3']) {
        await scheduler.run<void>(
          kind: LlmTaskKind.chat,
          modelId: 'm',
          work: recordingWork(trace: trace, label: label, tokens: 2),
        );
      }
      expect(
        trace.where((s) => s.startsWith('finish:')).toList(),
        equals(['finish:c1', 'finish:c2', 'finish:c3']),
      );
    });
  });

  group('Foreground clear — setForeground(null) drops kind back to fair pool',
      () {
    test('after clear, nataraj no longer hoists past gana', () async {
      final scheduler = InferenceScheduler();
      scheduler.setForeground(LlmTaskKind.nataraj);
      scheduler.setForeground(null); // immediately cleared
      final trace = <String>[];

      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 50)),
      );

      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'g', tokens: 2),
      );
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 2),
      );
      await Future.wait([blocker, g, n]);

      // Both T4. vruntime ties (both 0). FIFO → g first (queued first).
      expect(trace.indexOf('start:g'), lessThan(trace.indexOf('start:n')));
    });
  });

  group('Newcomer vruntime seeding — `min` of existing on first appearance',
      () {
    test('new kind seeded to min vruntime, runs immediately', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // Build up vruntime[nataraj] first.
      for (var i = 0; i < 3; i++) {
        await scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: recordingWork(trace: trace, label: 'n$i', tokens: 3),
        );
      }
      final natarajVr = scheduler.vruntimeSnapshot[LlmTaskKind.nataraj]!;
      expect(natarajVr, greaterThan(0.0));

      // Submit a gana for the first time. Seeded to min(existing) = natarajVr.
      // Since both are now tied (gana seeded == nataraj.vruntime AT seed
      // time), the gana shouldn't be penalised on its first appearance.
      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 30)),
      );
      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'g', tokens: 2),
      );
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'nLast', tokens: 2),
      );
      await Future.wait([blocker, g, n]);

      // gana was seeded to ~natarajVr; nataraj continues accumulating.
      // After blocker, gana's vruntime ≈ natarajVr (seeded), nataraj's is
      // larger from accumulated history → gana picked first.
      expect(trace.indexOf('start:g'),
          lessThan(trace.indexOf('start:nLast')));
    });
  });

  group('Re-queue policy — chat is NOT re-queued on preempt', () {
    test('a chat that loses the cancel race surfaces an error', () async {
      // Building this scenario requires submitting two chats and forcing the
      // first to be cancelled by the second. T0 doesn't preempt T0, so this
      // can't happen in normal operation. Asserted by code path: chat is
      // explicitly excluded from _isReQueueable.
      final scheduler = InferenceScheduler();
      // Submit a chat — runs to completion uneventfully.
      await scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: (_) async {},
      );
      expect(scheduler.queueLength, 0);
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Foreground preempt — clearing the foreground does not re-pick a job',
      () {
    test('setting then clearing foreground is a no-op when queue is empty',
        () async {
      final scheduler = InferenceScheduler();
      scheduler.setForeground(LlmTaskKind.nataraj);
      scheduler.setForeground(null);
      expect(scheduler.queueLength, 0);
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Affinity falls through — different-model picked when same-model empty',
      () {
    test('with loaded=A and only B queued, B runs', () async {
      final scheduler = InferenceScheduler();
      scheduler.notifyLoadedModel('A');
      final trace = <String>[];

      await scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'B', tokens: 2),
      );
      // B ran (no same-model A candidate to prefer).
      expect(trace, contains('finish:B'));
    });
  });

  group('Vruntime snapshot — exposed for instrumentation', () {
    test('snapshot is a stable copy of internal state', () async {
      final scheduler = InferenceScheduler();
      await scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: (_) async => Future.delayed(const Duration(milliseconds: 20)),
      );
      final snap1 = scheduler.vruntimeSnapshot;
      expect(snap1, isNotEmpty);
      // Mutating the snapshot does not affect the scheduler.
      snap1[LlmTaskKind.gana] = 999.0;
      expect(scheduler.vruntimeSnapshot[LlmTaskKind.gana],
          isNot(equals(999.0)));
    });
  });

  group('Concurrent chat + nataraj submission — chat wins regardless of order',
      () {
    test('chat submitted after nataraj still completes first', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // Long nataraj.
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 30),
      );
      // Wait one event-loop tick so nataraj is "running".
      await Future.delayed(const Duration(milliseconds: 15));

      final c = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'c', tokens: 2),
      );

      await c; // chat finishes
      await n; // nataraj re-queued + eventually finishes

      expect(trace.indexOf('finish:c'),
          lessThan(trace.indexOf('finish:n')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Edge cases — rigid coverage for the algorithm's failure modes.
  // ────────────────────────────────────────────────────────────────────────

  group('Edge A — work that throws surfaces the error to the caller', () {
    test('throwing chat propagates as a Future error', () async {
      final scheduler = InferenceScheduler();
      Object? caught;
      try {
        await scheduler.run<void>(
          kind: LlmTaskKind.chat,
          modelId: 'm',
          work: (_) async => throw StateError('engine misconfigured'),
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<StateError>());
      // Scheduler must recover and accept the next job.
      final ok =
          await scheduler.run<int>(kind: LlmTaskKind.chat, modelId: 'm', work: (_) async => 7);
      expect(ok, equals(7));
    });

    test('throwing fair-pool nataraj does NOT re-queue (errors are terminal)',
        () async {
      final scheduler = InferenceScheduler();
      Object? caught;
      try {
        await scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: (_) async => throw Exception('boom'),
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      expect(scheduler.queueLength, 0); // not re-queued
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Edge B — foreground change preempts a running job', () {
    test('setForeground(nataraj) cancels a running gana', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'g', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 25));
      expect(trace.first, equals('start:g'));

      // Hoist nataraj. There's no nataraj queued yet — but immediately
      // submit one. The running gana (T4) loses to the new nataraj (T1).
      scheduler.setForeground(LlmTaskKind.nataraj);
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 2),
      );

      await n;
      await g;

      expect(cancelledAtAnyTokenFor(trace, 'g'), isTrue);
      expect(trace.indexOf('finish:n'), lessThan(trace.indexOf('finish:g')));
    });
  });

  group('Edge C — generic return types are propagated correctly', () {
    test('Future<int>, Future<String>, Future<List<int>> all work', () async {
      final scheduler = InferenceScheduler();
      final iResult =
          await scheduler.run<int>(kind: LlmTaskKind.chat, modelId: 'm', work: (_) async => 42);
      final sResult = await scheduler.run<String>(
          kind: LlmTaskKind.chat, modelId: 'm', work: (_) async => 'hello');
      final lResult = await scheduler.run<List<int>>(
          kind: LlmTaskKind.chat, modelId: 'm', work: (_) async => [1, 2, 3]);

      expect(iResult, equals(42));
      expect(sResult, equals('hello'));
      expect(lResult, equals([1, 2, 3]));
    });

    test('null return is allowed for nullable T', () async {
      final scheduler = InferenceScheduler();
      final result = await scheduler.run<String?>(
          kind: LlmTaskKind.extract, modelId: 'm', work: (_) async => null);
      expect(result, isNull);
    });
  });

  group('Edge D — foreground transitions A → B', () {
    test('switching foreground from nataraj to gana hoists gana instead',
        () async {
      final scheduler = InferenceScheduler();
      scheduler.setForeground(LlmTaskKind.nataraj);
      scheduler.setForeground(LlmTaskKind.gana); // transition
      final trace = <String>[];

      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 40)),
      );
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 2),
      );
      final g = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'g', tokens: 2),
      );
      await Future.wait([blocker, n, g]);

      // gana is current foreground → T1. nataraj is T4. gana wins.
      expect(trace.indexOf('start:g'), lessThan(trace.indexOf('start:n')));
    });
  });

  group('Edge E — notifyLoadedModel mid-stream changes affinity for next pick',
      () {
    test('switching loaded model between picks changes which queued job wins',
        () async {
      final scheduler = InferenceScheduler();
      scheduler.notifyLoadedModel('A');
      final trace = <String>[];

      // Blocker on model A — runs first.
      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'A',
        work: blockerFor(const Duration(milliseconds: 30)),
      );

      // Two queued nataraj jobs on different models.
      final a = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'A',
        work: recordingWork(trace: trace, label: 'A', tokens: 2),
      );
      final b = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'B', tokens: 2),
      );

      // BEFORE blocker finishes, flip loaded model to B.
      scheduler.notifyLoadedModel('B');

      await Future.wait([blocker, a, b]);

      // Picker now prefers B (same-model with the freshly-loaded model).
      expect(trace.indexOf('start:B'), lessThan(trace.indexOf('start:A')));
    });
  });

  group('Edge F — future deadline does NOT promote prematurely', () {
    test('gana with deadline 1 hour from now stays at T4', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final blocker = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: blockerFor(const Duration(milliseconds: 30)),
      );
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'n', tokens: 2),
      );
      final gFuture = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        // Far-future deadline — should stay at T4, NOT get T3 promotion.
        deadline: DateTime.now().add(const Duration(hours: 1)),
        work: recordingWork(trace: trace, label: 'g', tokens: 2),
      );

      await Future.wait([blocker, n, gFuture]);

      // Both at T4. vruntime tied (both newcomers). FIFO → n queued first.
      expect(trace.indexOf('start:n'), lessThan(trace.indexOf('start:g')));
    });
  });

  group('Edge G — work that ignores cancel still completes (cooperative cancel)',
      () {
    test('a work closure that never polls cancel still runs to completion',
        () async {
      final scheduler = InferenceScheduler();
      var ranToCompletion = false;

      // Submit "uncooperative" nataraj — never checks `cancel.isCancelled`.
      final n = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          ranToCompletion = true;
        },
      );

      // Try to preempt with chat. Scheduler signals cancel, but the work
      // doesn't poll it — so it runs to natural completion before chat
      // gets the slot. This is the documented "cooperative cancel" model.
      await Future.delayed(const Duration(milliseconds: 5));
      final c = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: (_) async {},
      );

      await c;
      await n;

      expect(ranToCompletion, isTrue);
    });
  });

  group('Edge H — newcomer seeding on the very first job', () {
    test('first-ever job starts with vruntime = 0 (empty map case)', () async {
      final scheduler = InferenceScheduler();
      expect(scheduler.vruntimeSnapshot, isEmpty);

      await scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: (_) async {},
      );

      // After one run, the kind should be present with non-negative vruntime.
      expect(scheduler.vruntimeSnapshot[LlmTaskKind.nataraj], isNotNull);
      expect(
          scheduler.vruntimeSnapshot[LlmTaskKind.nataraj]!, greaterThanOrEqualTo(0.0));
    });
  });

  group('Edge J — runningKind reflects state while a job is in flight', () {
    test('runningKind is the current job mid-stream, null when idle', () async {
      final scheduler = InferenceScheduler();
      expect(scheduler.runningKind, isNull);

      final fut = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: (_) async => Future.delayed(const Duration(milliseconds: 40)),
      );

      // Wait a beat so the work is actually dispatched.
      await Future.delayed(const Duration(milliseconds: 10));
      expect(scheduler.runningKind, equals(LlmTaskKind.nataraj));

      await fut;
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Edge K — setForeground(same) is idempotent', () {
    test('calling setForeground with the same kind twice is harmless',
        () async {
      final scheduler = InferenceScheduler();
      scheduler.setForeground(LlmTaskKind.nataraj);
      scheduler.setForeground(LlmTaskKind.nataraj); // no-op
      // No assertion needed — just no exception.
      expect(true, isTrue);
    });
  });

  group('Edge L — chat still wins over T1 foreground', () {
    test('chat preempts a T1 foreground-hinted extract', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // Long extract at T1 (foregroundHint).
      final e = scheduler.run<void>(
        kind: LlmTaskKind.extract,
        modelId: 'm',
        foregroundHint: true,
        work: recordingWork(trace: trace, label: 'e', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 25));
      expect(trace.first, equals('start:e'));

      final c = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'c', tokens: 2),
      );

      await c;
      await e;

      expect(cancelledAtAnyTokenFor(trace, 'e'), isTrue);
      expect(trace.indexOf('finish:c'), lessThan(trace.indexOf('finish:e')));
    });
  });

  group('Edge — long-run vruntime stays sane after many jobs', () {
    test('30 consecutive nataraj jobs do not explode vruntime accounting',
        () async {
      final scheduler = InferenceScheduler();
      for (var i = 0; i < 30; i++) {
        await scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: (_) async {},
        );
      }
      final vr = scheduler.vruntimeSnapshot[LlmTaskKind.nataraj]!;
      // Each job consumes ~zero ms; vruntime is small + finite.
      expect(vr, greaterThanOrEqualTo(0.0));
      expect(vr.isFinite, isTrue);
      expect(scheduler.queueLength, 0);
    });
  });

  // ── modelSwitch (issue #160 follow-on) ─────────────────────────────────

  group('Scenario 9 — gentle model switch waits for the running job, then '
      'jumps ahead of anything queued after it', () {
    test('nataraj runs to completion untouched; switch then wins over a '
        'gana job that arrived while it was waiting', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      // Nataraj and gana share T4 — gana arriving does NOT preempt nataraj,
      // isolating this test to the modelSwitch behavior only (a real chat
      // job legitimately preempts nataraj on its own, which would confound
      // the "untouched" assertion below).
      final natarajFuture = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'nataraj', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 30));
      expect(trace.first, 'start:nataraj');

      final switchFuture = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch', tokens: 2),
      );
      final ganaFuture = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'gana', tokens: 2),
      );

      await natarajFuture;
      await switchFuture;
      await ganaFuture;

      // Nataraj was never interrupted.
      expect(cancelledAtAnyTokenFor(trace, 'nataraj'), isFalse);
      expect(trace, contains('finish:nataraj'));

      final natarajFinishIdx = trace.indexOf('finish:nataraj');
      final switchStartIdx = trace.indexOf('start:switch');
      final switchFinishIdx = trace.indexOf('finish:switch');
      final ganaStartIdx = trace.indexOf('start:gana');

      // Switch only starts after nataraj is done...
      expect(switchStartIdx, greaterThan(natarajFinishIdx));
      // ...and finishes before gana gets its turn, even though gana arrived
      // before the current job (nataraj) had finished.
      expect(switchFinishIdx, lessThan(ganaStartIdx));
    });
  });

  group('Scenario 10 — gentle model switch on an idle scheduler', () {
    test('runs immediately with nothing to wait for', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      await scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch', tokens: 1),
      );

      expect(trace, ['start:switch', 'finish:switch']);
      expect(scheduler.queueLength, 0);
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Scenario 11 — forced model switch preempts a running chat', () {
    test('chat is cancelled immediately and is NOT re-queued', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final chatFuture = scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'chat', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 30));
      expect(trace.first, 'start:chat');

      final switchFuture = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch', tokens: 1),
        forcePreempt: true,
      );

      await chatFuture;
      await switchFuture;

      expect(cancelledAtAnyTokenFor(trace, 'chat'), isTrue);
      // Chat is never re-queued — only one start, never a second attempt.
      expect(trace.where((s) => s == 'start:chat').length, 1);
      expect(trace, contains('finish:switch'));
      expect(scheduler.queueLength, 0);
    });
  });

  group('Scenario 12 — forced model switch preempts a running nataraj/gana, '
      'which auto-recovers via the existing re-queue policy', () {
    test('nataraj is cancelled, then re-queued and completes AFTER the '
        'switch — no work is permanently lost', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final natarajFuture = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'nataraj', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 30));
      expect(trace.first, 'start:nataraj');

      final switchFuture = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch', tokens: 1),
        forcePreempt: true,
      );

      await switchFuture;
      // Nataraj was cancelled but re-queued — awaiting it drains the
      // eventual, successful re-run.
      await natarajFuture;

      expect(cancelledAtAnyTokenFor(trace, 'nataraj'), isTrue);
      // Re-queued: the SAME job runs its work closure a second time.
      expect(trace.where((s) => s == 'start:nataraj').length, 2);
      expect(trace, contains('finish:nataraj'));

      final switchFinishIdx = trace.indexOf('finish:switch');
      final natarajFinishIdx = trace.lastIndexOf('finish:nataraj');
      expect(switchFinishIdx, lessThan(natarajFinishIdx));
    });
  });

  // ── Negative / edge cases ───────────────────────────────────────────────

  group('Negative — a queued gentle switch is never pulled forward by a '
      'foreground toggle', () {
    test('setForeground() while a gentle switch is queued does not cancel '
        'the running nataraj job', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final natarajFuture = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'nataraj', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 30));

      final switchFuture = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch', tokens: 1),
      );

      // Without the _maybePreempt guard, this would wrongly force-preempt
      // nataraj — the queued switch's tier (-1) always looks "best".
      scheduler.setForeground(LlmTaskKind.gana);

      await natarajFuture;
      await switchFuture;

      expect(cancelledAtAnyTokenFor(trace, 'nataraj'), isFalse);
      expect(trace, contains('finish:nataraj'));
      expect(trace, contains('finish:switch'));
    });
  });

  group('Negative — two queued gentle switches run in submission order, no '
      'starvation', () {
    test('switch1 finishes before switch2 starts', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final f1 = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'A',
        work: recordingWork(trace: trace, label: 'switch1', tokens: 10),
      );
      // Arrives while switch1 is already running.
      await Future.delayed(const Duration(milliseconds: 20));
      final f2 = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch2', tokens: 1),
      );

      await f1;
      await f2;

      expect(trace.indexOf('finish:switch1'),
          lessThan(trace.indexOf('start:switch2')));
      expect(scheduler.queueLength, 0);
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Negative — a model-switch action that throws propagates as a '
      'normal Future error', () {
    test('caller sees the exception, scheduler recovers cleanly', () async {
      final scheduler = InferenceScheduler();

      final future = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: (_) async => throw Exception('activation failed'),
      );

      await expectLater(future, throwsA(isA<Exception>()));
      expect(scheduler.queueLength, 0);
      expect(scheduler.runningKind, isNull);
    });
  });

  group('Negative — model-switch tier ignores model affinity', () {
    test('two queued switches run in submission order even when the loaded '
        'model matches the SECOND one, not the first', () async {
      final scheduler = InferenceScheduler();
      final trace = <String>[];

      final natarajFuture = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: recordingWork(trace: trace, label: 'nataraj', tokens: 20),
      );
      await Future.delayed(const Duration(milliseconds: 30));

      final f1 = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'A',
        work: recordingWork(trace: trace, label: 'switch1', tokens: 1),
      );
      final f2 = scheduler.run<void>(
        kind: LlmTaskKind.modelSwitch,
        modelId: 'B',
        work: recordingWork(trace: trace, label: 'switch2', tokens: 1),
      );
      // If affinity applied at tier -1, this would make switch2 (model B)
      // jump ahead of switch1 (model A), submitted first.
      scheduler.notifyLoadedModel('B');

      await natarajFuture;
      await f1;
      await f2;

      expect(trace.indexOf('start:switch1'),
          lessThan(trace.indexOf('start:switch2')));
    });
  });

  group('_maybePreempt', () {
    test('setForeground(chat) preempts an in-flight background job even '
        'when no chat job is queued yet', () async {
      final scheduler = InferenceScheduler();
      var cancelled = false;
      final ganaFuture = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: (cancel) async {
          for (var i = 0; i < 50; i++) {
            if (cancel.isCancelled) {
              cancelled = true;
              return;
            }
            await Future.delayed(const Duration(milliseconds: 5));
          }
        },
      );
      await Future.delayed(const Duration(milliseconds: 20));
      expect(scheduler.runningKind, LlmTaskKind.gana);

      scheduler.setForeground(LlmTaskKind.chat);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(cancelled, isTrue);
      scheduler.setForeground(null);
      await ganaFuture; // re-queued gana eventually completes without cancel
    });

    test('a queued job hoisted to foreground preempts a running job of a '
        'genuinely lower tier (not the chat-specific branch)', () async {
      final scheduler = InferenceScheduler();
      var ganaCancelled = false;
      final ganaFuture = scheduler.run<void>(
        kind: LlmTaskKind.gana,
        modelId: 'm',
        work: (cancel) async {
          for (var i = 0; i < 50; i++) {
            if (cancel.isCancelled) {
              ganaCancelled = true;
              return;
            }
            await Future.delayed(const Duration(milliseconds: 5));
          }
        },
      );
      await Future.delayed(const Duration(milliseconds: 20));
      expect(scheduler.runningKind, LlmTaskKind.gana);

      // Queue a nataraj job, then hoist nataraj to foreground (T1) —
      // strictly higher priority than the running gana (T4 fair pool).
      final natarajFuture = scheduler.run<void>(
        kind: LlmTaskKind.nataraj,
        modelId: 'm',
        work: (_) async {},
      );
      scheduler.setForeground(LlmTaskKind.nataraj);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(ganaCancelled, isTrue);
      scheduler.setForeground(null);
      await Future.wait([ganaFuture, natarajFuture]);
    });
  });

  // `InferenceScheduler` times itself via `package:clock`'s zone-scoped
  // `clock.now()` rather than a raw `Stopwatch` specifically so these two
  // groups below can drive it through `fakeAsync` — a real `Stopwatch`
  // reads VM/wall-clock ticks and cannot be faked, which is why this
  // 5-minute-scale logic used to be untestable without a real wait.
  group('vruntime decay (5-minute window)', () {
    test('halves accumulated vruntime once 5 minutes elapse', () {
      fakeAsync((async) {
        final scheduler = InferenceScheduler();

        // Run two same-tier jobs so both kinds seed a vruntime entry, then
        // let the fake clock elapse past the 5-minute decay threshold via
        // a third job's dispatch (decay is only checked inside `_pump`).
        scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: (_) => Future.delayed(const Duration(seconds: 10)),
        );
        async.elapse(const Duration(seconds: 10));

        scheduler.run<void>(
          kind: LlmTaskKind.gana,
          modelId: 'm',
          work: (_) => Future.delayed(const Duration(seconds: 20)),
        );
        async.elapse(const Duration(seconds: 20));

        final before = scheduler.vruntimeSnapshot;
        expect(before[LlmTaskKind.nataraj], closeTo(10.0, 0.01));
        // `_seedNewcomer` seeds a first-seen kind to the current minimum
        // vruntime (10.0, nataraj's), not zero, so gana starts at 10 and
        // accrues its own 20s run on top: 10 + 20 = 30.
        expect(before[LlmTaskKind.gana], closeTo(30.0, 0.01));

        // Elapse past the 5-minute decay window (measured from scheduler
        // construction, t=0), then dispatch one more job —
        // `_decayVruntimeIfDue` is only evaluated from `_pump`.
        async.elapse(const Duration(minutes: 5, seconds: 1));
        scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: (_) async {},
        );
        // The zero-delay dispatch runs via a `Timer.run`-scheduled Future,
        // not a bare microtask — `elapse(Duration.zero)` fires it.
        async.elapse(Duration.zero);

        final after = scheduler.vruntimeSnapshot;
        // nataraj: (10 halved to 5) + the new zero-duration run.
        expect(after[LlmTaskKind.nataraj], closeTo(5.0, 0.01));
        // gana: 30 halved to 15, untouched otherwise.
        expect(after[LlmTaskKind.gana], closeTo(15.0, 0.01));
      });
    });

    test('does not decay before 5 minutes have elapsed', () {
      fakeAsync((async) {
        final scheduler = InferenceScheduler();

        scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: (_) => Future.delayed(const Duration(seconds: 10)),
        );
        async.elapse(const Duration(seconds: 10));

        // Total elapsed since construction (t=0) stays under 5 minutes:
        // 10s + 4:45 = 4:55.
        async.elapse(const Duration(minutes: 4, seconds: 45));
        scheduler.run<void>(
          kind: LlmTaskKind.nataraj,
          modelId: 'm',
          work: (_) async {},
        );
        async.elapse(Duration.zero);

        // Still un-decayed: 10 (original) + 0 (instant second run).
        expect(scheduler.vruntimeSnapshot[LlmTaskKind.nataraj],
            closeTo(10.0, 0.01));
      });
    });
  });

  group('T2 soft budget window (rolling 5 minutes)', () {
    test('a job blocked by an exceeded 60% budget dispatches once the '
        'offending sample ages out of the rolling window', () {
      fakeAsync((async) {
        final scheduler = InferenceScheduler();
        // Re-evaluates the picker (decay + budget + tiers) without adding
        // or disturbing any queued job — `setForeground` calls `_pump()`
        // as a side effect, and toggling it back to null in the same tick
        // leaves `_foreground` exactly as it was.
        void poke() {
          scheduler.setForeground(LlmTaskKind.chat);
          scheduler.setForeground(null);
        }

        // Blow the budget: one sample where 100% of recorded time was
        // extract work (100/100 > the 60% cap).
        scheduler.run<void>(
          kind: LlmTaskKind.extract,
          modelId: 'm',
          work: (_) => Future.delayed(const Duration(seconds: 100)),
        );
        async.elapse(const Duration(seconds: 100));

        var ran = false;
        scheduler.run<void>(
          kind: LlmTaskKind.extract,
          modelId: 'm',
          work: (_) async => ran = true,
        );
        async.elapse(Duration.zero);
        expect(ran, isFalse,
            reason: 'tier 2 must be skipped while the budget is exceeded');

        // Just under 5 minutes since the offending sample — still blocked.
        async.elapse(const Duration(minutes: 4, seconds: 55));
        poke();
        async.elapse(Duration.zero);
        expect(ran, isFalse);

        // Cross the 5-minute mark: `_trimT2Window` drops the offending
        // sample, the budget check sees an empty window (not exceeded),
        // and the queued job finally dispatches.
        async.elapse(const Duration(seconds: 10));
        poke();
        async.elapse(Duration.zero);
        expect(ran, isTrue);
      });
    });
  });
}
