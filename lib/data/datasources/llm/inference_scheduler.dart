import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';

/// The UNIUN Scheduling Algorithm.
///
/// Five strict-priority tiers above a CFS-style fair pool, with EDF-style
/// deadline promotion, foreground-driven tier hoisting, and model-affinity
/// batching to amortize the ~10 s `flutter_gemma` model-swap cost. One GPU,
/// one loaded model at a time.
///
/// Full spec — including HLD/LLD diagrams, literature references, and the
/// eight verification scenarios — lives at `docs/SHIVA/scheduling.md`.
///
///   T-1 modelSwitch        activating/deleting the local model; ignores
///                          affinity; never re-queued; see `forcePreempt`
///                          on [run] for the gentle-vs-forced distinction
///   T0  chat              user typed; always wins, ignores model affinity
///   T1  foreground        kind matches `_foreground`, OR `foregroundHint`
///   T2  extract           any extract; soft-capped at 60 % over 5-min window
///   T3  deadline          job past its scheduled fire time (Gana cron)
///   T4  fair pool         nataraj / gana — picked by smallest vruntime
///
/// Embedding is NOT scheduled here — it runs on a separate model and chip
/// path via `EmbeddingQueue`.
@lazySingleton
class InferenceScheduler {
  final List<_Job> _q = [];
  final Map<LlmTaskKind, double> _vruntime = {};
  final Queue<_BudgetSample> _t2Samples = Queue();

  /// Uses `package:clock`'s zone-scoped [clock] instead of a raw [Stopwatch]
  /// so both this decay window and the per-job timing below respond to
  /// `package:fake_async` in tests — a real [Stopwatch] reads VM ticks and
  /// cannot be faked, which made the 5-minute decay/budget-window logic
  /// untestable without actually waiting real minutes.
  DateTime _lastVruntimeDecayAt = clock.now();

  LlmTaskKind? _foreground;
  String? _loadedModelId;
  _Job? _running;
  CancelToken? _runningCancel;
  DateTime? _runningStartedAt;
  bool _runningCancelledByScheduler = false;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Submit work to the scheduler. Returns when the work completes
  /// successfully, or with whatever error/cancel the work signals.
  ///
  /// [kind]            — the producer; drives tier selection.
  /// [modelId]         — the model the work expects to run on. Drives
  ///                     model-affinity batching.
  /// [deadline]        — only for cron-fired jobs; T3 boost when `now >=
  ///                     deadline`.
  /// [foregroundHint]  — set true when the caller knows the user is
  ///                     actively waiting (e.g. "extract for the note I
  ///                     just opened"). Hoists to T1 even when
  ///                     `_foreground != kind`.
  /// [work]            — receives a [CancelToken]. The work MUST check it
  ///                     between tokens / loop iterations and stop ASAP
  ///                     when `isCancelled` flips.
  /// [forcePreempt]    — only meaningful for [LlmTaskKind.modelSwitch].
  ///                     `false` (default): never interrupts whatever is
  ///                     running — waits for it to finish naturally, then
  ///                     is picked next (tier -1 always wins the pick).
  ///                     `true`: cancels the running job immediately,
  ///                     regardless of tier — used when the active model
  ///                     is being deleted and can't wait.
  Future<T> run<T>({
    required LlmTaskKind kind,
    required String modelId,
    required Future<T> Function(CancelToken) work,
    DateTime? deadline,
    bool foregroundHint = false,
    bool forcePreempt = false,
  }) {
    final job = _Job(
      kind: kind,
      modelId: modelId,
      deadline: deadline,
      foregroundHint: foregroundHint,
      forcePreempt: forcePreempt,
      work: (t) => work(t),
    );
    _seedNewcomer(kind);
    _q.add(job);
    _onJobArrived(job);
    return job.completer.future.then((v) => v as T);
  }

  /// Set the foreground LLM task kind. Pass `null` to clear.
  ///
  /// Hoists matching queued/running jobs to T1. If the new tier of the
  /// currently-running job becomes lower-priority than something queued,
  /// preempts at the next token boundary.
  void setForeground(LlmTaskKind? kind) {
    if (_foreground == kind) return;
    debugPrint('🎯 InferenceScheduler: foreground=$kind '
        '(was $_foreground, queue=${_q.length}, running=${_running?.kind})');
    _foreground = kind;
    _maybePreempt();
    _pump();
  }

  /// Called by [AIModelRunner] whenever it (un)loads a model. The scheduler
  /// uses this to evaluate same-model affinity inside the picker.
  void notifyLoadedModel(String? modelId) {
    if (_loadedModelId == modelId) return;
    _loadedModelId = modelId;
    // A swap could open up a same-model candidate; re-evaluate.
    _pump();
  }

  // ── Submission internals ───────────────────────────────────────────────

  void _onJobArrived(_Job j) {
    if (_running == null) {
      _pump();
      return;
    }
    // A gentle model-switch never interrupts what's running — it only gets
    // picked once the current job finishes on its own (tier -1 guarantees
    // it's picked next, ahead of anything else queued in the meantime).
    if (j.kind == LlmTaskKind.modelSwitch && !j.forcePreempt) return;
    if (j.forcePreempt || _tier(j) < _tier(_running!)) {
      _signalPreempt();
    } else {
      // Nothing to do — picker will see the job when current finishes.
    }
  }

  void _maybePreempt() {
    if (_running == null) return;
    // User is on the chat surface → preempt any background work (T2+) outright
    // even if no chat job is queued yet. Without this, an in-flight extract
    // can hold the runner for minutes while the user stares at an empty chat
    // tab — exactly the #118 / #7-foreground-toggling complaint. Matches the
    // semantic the old `pauseLowPriority` had before the scheduler rewrite.
    if (_foreground == LlmTaskKind.chat &&
        _tier(_running!) >= 2 &&
        _isReQueueable(_running!)) {
      _signalPreempt();
      return;
    }
    final best = _peekBest();
    if (best == null) return;
    // A gentle model-switch sitting in the queue must not get pulled into
    // running just because a foreground toggle re-evaluated priority — its
    // tier -1 would otherwise always "win" this generic check.
    if (best.kind == LlmTaskKind.modelSwitch && !best.forcePreempt) return;
    if (_tier(best) < _tier(_running!)) _signalPreempt();
  }

  void _signalPreempt() {
    final c = _runningCancel;
    if (c == null || c.isCancelled) return;
    _runningCancelledByScheduler = true;
    c.cancel();
  }

  // ── Tier classification ────────────────────────────────────────────────

  int _tier(_Job j) {
    if (j.kind == LlmTaskKind.modelSwitch) return -1;
    if (j.kind == LlmTaskKind.chat) return 0;
    if (j.kind == LlmTaskKind.translate) return 1;
    if (j.foregroundHint || _foreground == j.kind) return 1;
    if (j.kind == LlmTaskKind.extract) return 2;
    if (j.deadline != null && clock.now().isAfter(j.deadline!)) return 3;
    return 4;
  }

  // ── Picker ─────────────────────────────────────────────────────────────

  /// Like [_pickBest] but does not remove from the queue. Used for
  /// preemption checks.
  _Job? _peekBest() {
    final picked = _pickBestInternal(removeFromQueue: false);
    return picked;
  }

  _Job? _pickBest() {
    return _pickBestInternal(removeFromQueue: true);
  }

  _Job? _pickBestInternal({required bool removeFromQueue}) {
    _decayVruntimeIfDue();
    final t2BudgetBlown = _t2BudgetExceeded();
    // While the user is on the chat surface, never start new background work.
    // T0 (chat) and T1 (foreground=chat ⇒ chat-kind ⇒ still T0) are the only
    // dispatchable tiers. Resumed when [setForeground] clears.
    final blockBackground = _foreground == LlmTaskKind.chat;

    for (int tier = -1; tier <= 4; tier++) {
      if (tier == 2 && t2BudgetBlown) continue;
      if (tier >= 2 && blockBackground) continue;

      final inTier = _q.where((j) => _tier(j) == tier).toList();
      if (inTier.isEmpty) continue;

      // Tier -1 (model switch) and T0 chat both ignore affinity — neither
      // is "for" a particular loaded model.
      if (tier <= 0) {
        final pick = _resolveWithinTier(inTier, tier);
        if (removeFromQueue) _q.remove(pick);
        return pick;
      }

      // Below T0: prefer same-model candidates.
      final sameModel = _loadedModelId == null
          ? inTier
          : inTier.where((j) => j.modelId == _loadedModelId).toList();

      final candidates = sameModel.isNotEmpty ? sameModel : inTier;
      final pick = _resolveWithinTier(candidates, tier);
      if (removeFromQueue) _q.remove(pick);
      return pick;
    }
    return null;
  }

  _Job _resolveWithinTier(List<_Job> jobs, int tier) {
    if (tier != 4 || jobs.length == 1) return jobs.first;
    jobs.sort((a, b) =>
        (_vruntime[a.kind] ?? 0.0).compareTo(_vruntime[b.kind] ?? 0.0));
    return jobs.first;
  }

  // ── Pump + finish ──────────────────────────────────────────────────────

  void _pump() {
    if (_running != null) return;
    final next = _pickBest();
    if (next == null) return;

    _running = next;
    _runningCancel = CancelToken();
    _runningCancelledByScheduler = false;
    _runningStartedAt = clock.now();

    debugPrint('▶️ InferenceScheduler: dispatch ${next.kind} '
        '(model=${next.modelId}, queue=${_q.length})');

    final cancel = _runningCancel!;
    Future(() => next.work(cancel)).then(
      (v) => _finishRunning(next, value: v),
      onError: (e, st) => _finishRunning(next, error: e, stack: st as StackTrace?),
    );
  }

  void _finishRunning(
    _Job j, {
    Object? value,
    Object? error,
    StackTrace? stack,
  }) {
    final secs = _runningStartedAt == null
        ? 0.0
        : clock.now().difference(_runningStartedAt!).inMilliseconds / 1000.0;
    _vruntime[j.kind] = (_vruntime[j.kind] ?? 0.0) + secs;
    _recordT2Sample(j.kind, secs);

    final wasCancelled = _runningCancelledByScheduler;
    _running = null;
    _runningCancel = null;
    _runningStartedAt = null;
    _runningCancelledByScheduler = false;

    if (wasCancelled && _isReQueueable(j)) {
      // Cancelled by the scheduler to let a higher-tier job in. Re-queue
      // from scratch; the work's prefill is lost (acceptable cost — see
      // docs/SHIVA/scheduling.md §9 "Cancel accounting").
      debugPrint('🔁 InferenceScheduler: re-queue ${j.kind} after preempt');
      _q.add(j);
    } else if (error != null) {
      j.completer.completeError(error, stack);
    } else {
      j.completer.complete(value);
    }
    _pump();
  }

  bool _isReQueueable(_Job j) =>
      j.kind == LlmTaskKind.extract ||
      j.kind == LlmTaskKind.nataraj ||
      j.kind == LlmTaskKind.gana ||
      // Translation is a pure function of (note, language), so re-running it
      // is always safe. Without this a chat message preempting a translation
      // would surface as "the model couldn't translate this note", blaming
      // the model for what was only a scheduling decision.
      j.kind == LlmTaskKind.translate;
  // chat is never re-queued — T0 only loses to itself, which signals a bug,
  // so the cancel propagates as an error.

  // ── CFS bookkeeping ────────────────────────────────────────────────────

  void _seedNewcomer(LlmTaskKind kind) {
    if (_vruntime.containsKey(kind)) return;
    _vruntime[kind] = _vruntime.values.isEmpty
        ? 0.0
        : _vruntime.values.reduce(math.min);
  }

  /// Every 5 minutes, halve all vruntime entries so history doesn't
  /// permanently penalise a producer. Mirrors Linux CFS min_vruntime
  /// behaviour on long-idle wake.
  void _decayVruntimeIfDue() {
    if (clock.now().difference(_lastVruntimeDecayAt) <
        const Duration(minutes: 5)) {
      return;
    }
    _lastVruntimeDecayAt = clock.now();
    for (final k in _vruntime.keys.toList()) {
      _vruntime[k] = (_vruntime[k] ?? 0.0) * 0.5;
    }
  }

  // ── T2 soft budget (60 % over rolling 5 min) ───────────────────────────

  void _recordT2Sample(LlmTaskKind kind, double secs) {
    _t2Samples.add(_BudgetSample(
      at: clock.now(),
      t2Seconds: kind == LlmTaskKind.extract ? secs : 0.0,
      totalSeconds: secs,
    ));
  }

  bool _t2BudgetExceeded() {
    _trimT2Window();
    if (_t2Samples.isEmpty) return false;
    final t2Used = _t2Samples.fold<double>(0, (a, s) => a + s.t2Seconds);
    final total = _t2Samples.fold<double>(0, (a, s) => a + s.totalSeconds);
    if (total <= 0) return false;
    return (t2Used / total) > 0.60;
  }

  void _trimT2Window() {
    final cutoff = clock.now().subtract(const Duration(minutes: 5));
    while (_t2Samples.isNotEmpty && _t2Samples.first.at.isBefore(cutoff)) {
      _t2Samples.removeFirst();
    }
  }

  /// True while a Shiv chat reply is being generated. Background work that is
  /// heavy on the CPU (note embedding) stands down while this is true.
  bool get isChatRunning => _running?.kind == LlmTaskKind.chat;

  // ── Debug introspection ────────────────────────────────────────────────

  @visibleForTesting
  int get queueLength => _q.length;
  @visibleForTesting
  LlmTaskKind? get runningKind => _running?.kind;
  @visibleForTesting
  Map<LlmTaskKind, double> get vruntimeSnapshot => Map.of(_vruntime);
}

/// Cooperative cancellation handed to scheduled work. The work polls
/// [isCancelled] between tokens / loop iterations and stops ASAP when the
/// scheduler flips it.
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class _Job {
  _Job({
    required this.kind,
    required this.modelId,
    required this.work,
    this.deadline,
    this.foregroundHint = false,
    this.forcePreempt = false,
  });

  final LlmTaskKind kind;
  final String modelId;
  final DateTime? deadline;
  final bool foregroundHint;
  final bool forcePreempt;
  final Future<dynamic> Function(CancelToken) work;
  final Completer<dynamic> completer = Completer<dynamic>();
}

class _BudgetSample {
  _BudgetSample({
    required this.at,
    required this.t2Seconds,
    required this.totalSeconds,
  });
  final DateTime at;
  final double t2Seconds;
  final double totalSeconds;
}
