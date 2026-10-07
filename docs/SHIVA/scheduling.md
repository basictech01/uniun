# UNIUN Scheduling Algorithm

How on-device LLM work is prioritized inside the app. Replaces the
two-lane `ModelTaskQueue` described historically in
[`SHIV_AI.md`](SHIV_AI.md) and [`Ganas.md`](Ganas.md).

> **TL;DR** — One GPU. One model loaded at a time. Many producers
> (chat, knowledge extraction, Nataraj, Gana). A 5-tier strict-priority
> queue with a CFS-style fair pool at the bottom, EDF-style deadline
> promotion in the middle, foreground-driven tier hoisting, and
> model-affinity batching. Embedding runs on a separate chip and lane;
> it is intentionally outside this scheduler.

---

## 1. Why

GitHub issue [#118](https://github.com/basictech01/uniun/issues/118)
documents the user-visible bug: opening Shiv chat while Nataraj is
filling its deck makes chat wait 30–110 s before the first token. Root
cause was a coarse two-lane queue (`runHigh` / `runLow` +
`pauseLowPriority`) in `lib/data/datasources/llm/local_inference_queue.dart`.
Nataraj was submitting with `highPriority: true` to bypass the
Shiv-tab pause — which put it on the **same lane as chat**, so chat
waited FIFO behind it.

We considered the obvious fixes:

- **More lanes** (kind-tagged FIFO) — works for the immediate bug but
  doesn't handle Nataraj-vs-Gana fairness, foreground hoisting on the
  Nataraj page, or Gana cron deadlines.
- **One queue, dynamic priorities** — closer, but pure priority causes
  starvation; CFS / EDF / SCHED_FIFO each solve a piece but none solves
  all of it.

The combination of mechanisms in this doc is what we ship.

---

## 2. Mental model

```
                  ┌──────────────────────────────────────┐
                  │           ONE GPU / NPU              │
                  │   one active chat-model loaded       │
                  │   one inference at a time            │
                  └────────────────┬─────────────────────┘
                                   │ run() / stopGeneration()
                                   │
   ┌───────────────────────────────┴──────────────────────────────┐
   │                    InferenceScheduler                        │
   │                  (lib/data/datasources/llm/)                 │
   │                                                              │
   │   ┌──────────────────────────────────────────────────────┐   │
   │   │  T-1 modelSwitch (activating/deleting the local model)│   │
   │   │  T0 chat                                             │   │
   │   │  T1 foreground (whichever page is open)              │   │
   │   │  T2 extract                                          │   │
   │   │  T3 deadline (Gana cron past due)                    │   │
   │   │  T4 fair pool — nataraj / gana   ← CFS vruntime      │   │
   │   └──────────────────────────────────────────────────────┘   │
   └───────────────────────────────┬──────────────────────────────┘
                                   │
   ▲ Chat, Nataraj, Gana, Extract submit here via use cases.
   │ Every call passes a LlmTaskKind + target modelId.
   │
   │
   ┌───────────────────────────────────────────────────────┐
   │  Parallel & unscheduled — EmbeddingQueue (different    │
   │  model, different chip path):                          │
   │      EmbeddingService ──► one at a time, questions first│
   │                                                        │
   │  Never blocks the LLM scheduler. Never preempted.      │
   └───────────────────────────────────────────────────────┘
```

The scheduler is purely a **dispatch policy**. The actual inference,
streaming, and cancel primitives live in `AIModelRunner`
(`lib/data/datasources/llm/local_llm_runner.dart`). The scheduler tells
it *what* to run next; the runner knows *how*.

---

## 3. Algorithm — high-level (HLD)

### Tier table

| Tier  | Kind admitted                                                         | Reason it's at this rank                                                                                                                |
| ----- | --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| T-1   | `modelSwitch` (activating a newly-picked local model, or deleting the active one) | The user's own explicit action. Never affinity-filtered. Two modes via `forcePreempt` — see "Model switch tier" below.       |
| T0    | `chat`                                                                | User typed. Must respond now. Always preempts.                                                                                          |
| T1    | the kind whose surface is currently foreground (`_foreground`)        | Whatever the user is staring at deserves priority while they're there. NatarajDeck → nataraj. GanaForm preview → gana. Opened note → extract. |
| T2    | `extract` (any)                                                       | Knowledge extraction builds the graph that powers RAG and Shiv quality. Infrastructure beats entertainment.                              |
| T3    | any job whose `deadline != null && now >= deadline`                   | Gana cron ticks: their `triggerIntervalMinutes` defines a fire time; once past, the tick gets a deadline boost. EDF semantics.          |
| T4    | `nataraj`, `gana` (cron-fired but pre-deadline, or interactive)        | The fair pool. CFS-style vruntime ensures neither producer starves.                                                                     |

### Model switch tier (issue #160 follow-on)

Activating or deleting a local model touches flutter_gemma's native
engine directly (`FlutterGemma.installModel()`/`.uninstallModel()`).
Before this tier existed, that call raced whatever generation job was
currently running against the same engine — nothing in
`AIModelRepositoryImpl.activateModel()`/`deleteModel()` checked the
scheduler first. `run()` takes a `forcePreempt` flag for this tier only:

- **`forcePreempt: false`** (a plain switch, via the model picker): never
  cancels the running job on arrival — it waits for it to finish
  naturally, then wins the next pick (tier -1 always sorts first). If a
  higher-priority job arrives while it's queued (e.g. the user starts
  typing), that job still runs first; the switch keeps waiting.
- **`forcePreempt: true`** (deleting the currently-active model): cancels
  the running job immediately, same as any other tier-based preemption.
  Nataraj/Gana recover for free through the existing re-queue policy
  below; a cancelled chat turn finalizes with partial content, same as
  the Stop button.

One guard exists specifically for the gentle case: `setForeground()`'s
preemption check (`_maybePreempt`) re-evaluates the best queued job on
every foreground toggle. Without an explicit exception, a queued gentle
switch — always tier -1, so it always looks "best" — would get pulled
into running on the next unrelated foreground change, contradicting
"never interrupts." Both `_onJobArrived` and `_maybePreempt` special-case
`modelSwitch` jobs with `forcePreempt: false` to skip preemption
entirely; the tier ordering alone still guarantees it's picked next.

`AIModelRunner.runExclusiveModelOperation()` is the call site both
`AIModelRepositoryImpl.activateModel()` and `deleteModel()` (when
deleting the active model) route through.

### Picker rule

> Pick the lowest-numbered tier with a job whose target model is the
> currently-loaded model **OR** whose tier outranks the cost of
> swapping. Inside T4, smallest `vruntime[kind]` wins.

### Soft budget

T2 is capped at ~60 % of cumulative LLM time over each rolling 5-minute
window. If T2 overruns, the picker pretends T2 is empty until the
window rolls. This stops a 500-note backfill from monopolizing the
chip.

### Preemption rule

When a new job arrives whose tier < the running job's tier:

1. Call `InferenceChat.stopGeneration()` on the runner — flutter_gemma
   honours this between tokens (typically <100 ms).
2. The cancelled job, if it was in the fair pool, is **re-queued at
   the front of its tier** so it runs again later from scratch.
3. The picker re-runs.

### Model affinity rule

Each job carries a `modelId` (the model it expects to run on). Model
swap is expensive — ~10 s to unload + load on flutter_gemma 1.1.x.

- **T0 chat** ignores affinity; it preempts even across a swap. User-
  facing latency wins.
- **Below T0**, the picker prefers candidates whose `modelId ==
  currentLoadedModelId`. When the same-model queue is empty for the
  tier, it picks the next-tier same-model job, falling through tiers
  before incurring a swap.
- When a swap IS unavoidable, the picker first drains every other
  queued job of the target `modelId` it can find (within tiers ≥ the
  swap-trigger), so one swap services a batch.

### Picker decision tree (ASCII)

```
                        Job submitted / foreground changed
                                       │
                                       ▼
                        ┌─────────────────────────────┐
                        │ Is anything running?        │
                        └──────────┬──────────────────┘
                          Yes      │      No
                                   ▼
                  ┌────────────────────────────────┐
                  │ Tier(new job) < Tier(running)? │
                  └─────┬────────────────┬─────────┘
                    Yes │            No  │
                        ▼                ▼
              stopGeneration()      let it finish
              re-queue running      then call _pickBest()
              _pickBest()
                        │
                        ▼
              ┌──────────────────────────────┐
              │           _pickBest          │
              │                              │
              │  for tier in 0..4:           │
              │    candidates = jobs in tier │
              │    skip T2 if budget blown   │
              │    if candidates is empty:   │
              │      continue                │
              │    same-model = filter ==    │
              │      currentModelId          │
              │    if same-model non-empty:  │
              │      tier-resolve & return   │
              │    if affinity allows swap:  │
              │      tier-resolve & return   │
              │  return nothing              │
              └──────────────────────────────┘
```

`tier-resolve` = "if tier == 4 pick smallest vruntime; else FIFO".

---

## 4. Algorithm — low-level (LLD)

Pseudocode. The real implementation in
`lib/data/datasources/llm/inference_scheduler.dart` follows this
shape; comments map back to these names.

### State

```dart
class InferenceScheduler {
  final List<_Job> _q = [];
  final Map<LlmTaskKind, double> _vruntime = {};   // CFS counters
  final Queue<_BudgetSample> _t2Samples = Queue();  // 5-min sliding window

  LlmTaskKind? _foreground;       // null when no AI surface is open
  String? _loadedModelId;          // mirrors AIModelRunner state
  _Job? _running;
  CancelToken? _runningCancel;
  Stopwatch? _runningTimer;
}

class _Job {
  final LlmTaskKind kind;
  final String modelId;
  final DateTime? deadline;        // only set for cron-fired Gana
  final bool foregroundHint;       // true for "extract for opened note"
  final bool forcePreempt;         // modelSwitch only — see §3 "Model switch tier"
  final Future<dynamic> Function(CancelToken) work;
  final Completer<dynamic> completer = Completer();
}
```

### Tier classification

```dart
int _tier(_Job j) {
  if (j.kind == LlmTaskKind.modelSwitch) return -1;
  if (j.kind == LlmTaskKind.chat) return 0;

  final foregroundMatch =
      _foreground == j.kind || (j.foregroundHint && _foreground == j.kind);
  if (foregroundMatch) return 1;

  if (j.kind == LlmTaskKind.extract) return 2;

  if (j.deadline != null && DateTime.now().isAfter(j.deadline!)) return 3;

  return 4;
}
```

### Budget bookkeeping

```dart
bool _t2BudgetExceeded() {
  _trimT2Window();
  final t2Used = _t2Samples.fold<double>(0, (a, s) => a + s.t2Seconds);
  final total  = _t2Samples.fold<double>(0, (a, s) => a + s.totalSeconds);
  return total > 0 && (t2Used / total) > 0.60;
}

void _trimT2Window() {
  final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
  while (_t2Samples.isNotEmpty && _t2Samples.first.at.isBefore(cutoff)) {
    _t2Samples.removeFirst();
  }
}
```

### Picker

```dart
_Job? _pickBest() {
  final t2BudgetBlown = _t2BudgetExceeded();

  for (int tier = -1; tier <= 4; tier++) {   // -1 first: modelSwitch
    if (tier == 2 && t2BudgetBlown) continue;

    final inTier = _q.where((j) => _tier(j) == tier).toList();
    if (inTier.isEmpty) continue;

    // Tier -1 (modelSwitch) and T0 (chat) both ignore model affinity —
    // neither is "for" a particular loaded model.
    if (tier <= 0) return _resolveWithinTier(inTier, tier);

    // Same-model first.
    final sameModel = inTier
        .where((j) => j.modelId == _loadedModelId)
        .toList();

    if (sameModel.isNotEmpty) {
      return _resolveWithinTier(sameModel, tier);
    }

    // Different model — accept the swap.
    return _resolveWithinTier(inTier, tier);
  }
  return null;
}

_Job _resolveWithinTier(List<_Job> jobs, int tier) {
  if (tier == 4) {
    jobs.sort((a, b) =>
        (_vruntime[a.kind] ?? 0).compareTo(_vruntime[b.kind] ?? 0));
  }
  return jobs.first;
}
```

### Submission

```dart
Future<T> run<T>({
  required LlmTaskKind kind,
  required String modelId,
  bool foregroundHint = false,
  bool forcePreempt = false,     // modelSwitch only
  DateTime? deadline,
  required Future<T> Function(CancelToken) work,
}) {
  final job = _Job(kind, modelId, deadline, foregroundHint, forcePreempt, work);
  _q.add(job);
  _onJobArrived(job);
  return job.completer.future.then((v) => v as T);
}

void _onJobArrived(_Job j) {
  if (_running == null) {
    _pump();
    return;
  }
  // A gentle modelSwitch never interrupts what's running — tier -1
  // guarantees it's picked next once the current job finishes on its own.
  if (j.kind == LlmTaskKind.modelSwitch && !j.forcePreempt) return;
  if (j.forcePreempt || _tier(j) < _tier(_running!)) {
    _runningCancel?.cancel();    // _finishRunning will re-queue.
  }
}
```

### Pump + finish

```dart
void _pump() {
  if (_running != null) return;
  final next = _pickBest();
  if (next == null) return;

  _q.remove(next);
  _running = next;
  _runningCancel = CancelToken();
  _runningTimer = Stopwatch()..start();

  // Model swap if necessary (delegated to AIModelRunner).
  next.work(_runningCancel!).then(
    (v) => _finishRunning(next, value: v),
    onError: (e) => _finishRunning(next, error: e),
  );
}

void _finishRunning(_Job j, {Object? value, Object? error}) {
  final secs = (_runningTimer?.elapsed.inMilliseconds ?? 0) / 1000.0;
  _vruntime[j.kind] = (_vruntime[j.kind] ?? 0) + secs;
  _recordT2Sample(j, secs);

  final cancelled = _runningCancel?.isCancelled ?? false;
  _running = null;
  _runningCancel = null;
  _runningTimer = null;

  if (cancelled && _isReQueueable(j)) {
    _q.add(j);                   // re-queued from scratch
  } else if (error != null) {
    j.completer.completeError(error);
  } else {
    j.completer.complete(value);
  }
  _pump();
}

bool _isReQueueable(_Job j) =>
    j.kind == LlmTaskKind.nataraj ||
    j.kind == LlmTaskKind.gana    ||
    j.kind == LlmTaskKind.extract;   // chat is never re-queued
```

### Foreground change

```dart
void setForeground(LlmTaskKind? kind) {
  if (_foreground == kind) return;
  _foreground = kind;
  if (_running != null) {
    final best = _peekBest();
    // A gentle modelSwitch sitting in the queue must not get pulled into
    // running just because a foreground toggle re-evaluated priority —
    // its tier -1 would otherwise always "win" this check. See §3.
    if (best?.kind == LlmTaskKind.modelSwitch && !best!.forcePreempt) return;
    final pickedTier = best == null
        ? _tier(_running!) + 1
        : _tier(best);
    if (pickedTier < _tier(_running!)) _runningCancel?.cancel();
  } else {
    _pump();
  }
}
```

### CFS newcomer seeding

When a kind first appears (or returns after being absent for > 5 min),
seed it:

```dart
_vruntime[newKind] = _vruntime.values.isEmpty
    ? 0.0
    : _vruntime.values.reduce(math.min);
```

This is `min_vruntime` from Linux CFS — prevents a long-idle producer
from monopolizing as soon as it returns (because its accumulated
vruntime is much smaller than everyone else's).

---

## 5. Architecture

The scheduler honours UNIUN's data → domain → presentation layering
(see [`SHIV_AI.md` §Architecture](SHIV_AI.md)). No widget imports
`lib/data/`; no BLoC imports the scheduler directly.

```
PRESENTATION                                       (lib/features/shiv/)
  ShivPage / NatarajDeckPage / GanaFormPage
    └─ SetForegroundKindUseCase                    (page lifecycle)

  ShivAIBloc.send / ComposerChatCubit.send / NatarajGenerator / GanaEngine
    └─ SendChatStreamUseCase / GenerateOneShotUseCase   (already exist;
                                                         caller passes
                                                         kind in input)

                          │
                          ▼

DOMAIN                                              (lib/domain/)
  LlmTaskKind enum                                  entities/llm/
  GenerateOneShotInput.kind  (replaces .highPriority)
  SchedulerCoordinator interface                    repositories/
  SetForegroundKindUseCase                          usecases/scheduler_usecases.dart

                          │
                          ▼

DATA                                                (lib/data/)
  SchedulerCoordinatorImpl                          repositories/
    @Injectable(as: SchedulerCoordinator)           — thin adapter

  InferenceScheduler                                datasources/llm/
    inference_scheduler.dart                        — the algorithm
                                                      (~250 LOC)
  AIModelRunner                                     datasources/llm/
    local_llm_runner.dart                           — InferenceChat
                                                      .stopGeneration()

  EmbeddingQueue                                    datasources/llm/
    embedding_queue.dart                            — one embed at a time, priorities
```

`SchedulerCoordinator` mirrors the existing pattern set by
`LlmRepository` / `LlmRepositoryImpl`
(`lib/domain/repositories/llm_repository.dart`,
`lib/data/repositories/llm_repository_impl.dart`). The use case
`SetForegroundKindUseCase` is the existing analogue of
`PreemptBackgroundWorkUseCase` (`lib/domain/usecases/llm_usecases.dart`).

---

## 6. Call site mapping

| Submission site                                                                  | Kind passed         | Sets foreground? | Model affinity                                  |
| -------------------------------------------------------------------------------- | ------------------- | ---------------- | ----------------------------------------------- |
| `ShivAIBloc.send` (`lib/features/shiv/chat/bloc/shiv_ai_bloc.dart`)              | `chat`              | yes (via ShivPage) | active chat model                              |
| `ComposerChatCubit.send` (`lib/features/shiv/composer_chat/cubit/`)              | `chat`              | yes (panel open) | active chat model                              |
| `NatarajGenerator.fillBuffer` (`.../nataraj/engine/nataraj_generator.dart:108`)  | `nataraj`           | yes (NatarajDeckPage) | active chat model                          |
| `GanaEngine.processGana` (`.../gana/engine/gana_engine.dart`) — interactive       | `gana`              | yes (GanaFormPage) | `GanaEntity.desiredModelId`                   |
| `GanaEngine.processGana` — cron fire                                              | `gana` + `deadline` | no               | `GanaEntity.desiredModelId`                   |
| `ExtractKnowledgeUseCase` — note just opened                                      | `extract`, `foregroundHint:true` | yes (note detail) | active chat model                |
| `ExtractKnowledgeUseCase` — backfill loop                                         | `extract`           | no               | active chat model                              |
| `EmbeddingService.embed` (`.../rag/embedding/embedding_service.dart`)            | n/a (separate queue) | n/a             | embedder model — separate chip                 |
| `gana_workmanager.dart` (background isolate)                                     | n/a (out of scope)  | n/a             | own direct `FlutterGemma` — see §9             |
| `AIModelRepositoryImpl.activateModel` (`.../repositories/ai_model_repository_impl.dart`) | `modelSwitch`, `forcePreempt:false` | no | ignored (tier -1) |
| `AIModelRepositoryImpl.deleteModel` — deleting the active model                   | `modelSwitch`, `forcePreempt:true` | no | ignored (tier -1) |

---

## 7. Embedding side queue

How notes reach this queue (the pending table and the worker) is in [`embedding.md`](embedding.md).

```
EmbeddingService.embed(text)
   │   isDocument:false → interactive (a question)
   │   isDocument:true  → background (a note, a PDF/DOCX chunk)
   ▼
EmbeddingQueue ─► one in flight; interactive waiters first ─► flutter_gemma_embeddings
                                    (separate model, separate context)
```

The embedder is a small dedicated model (~110 M params, INT8) that
ships in `flutter_gemma_embeddings`. It is not the chat model — it
runs through its own MediaPipe graph and does not occupy the chat
runner's `InferenceChat` slot.

Why a separate queue, not just unbounded concurrency:

- On a relay flood (200 new notes / second), unbounded embedder calls
  spike CPU and battery for no benefit — the consumer (RAG vector
  store) batches anyway.
- The cap is now **1** (it was 2): the plugin serves embeds one at a time in
  a single worker isolate, and two at a time measured no faster than one
  (11.55 s per note both ways on a Snapdragon 710). Interactive requests are
  served ahead of queued background ones.

Why this is **not** wired into `InferenceScheduler`:

- Embedding cannot block, preempt, or be preempted by the chat path.
- Calls are short on a fast phone. On a Snapdragon 710 (vivo 1933) one embed measured **~11.5 s** (CPU/XNNPACK, constant per call, same for
  one at a time, 2 at a time and `generateEmbeddings`), so on weak devices a call is
  not short; it still runs in the plugin's own worker isolate and cannot be
  preempted. Notes are embedded one at a time by `NoteEmbeddingWorker` from
  the persistent `PendingEmbedding` table (see `rag.md`), not through this
  scheduler.
- Adding it would mean two queues need to know about each other's
  load, which is harder to reason about than two independent ones.

Future work: detect device class (`system_info_plus`) and raise the
semaphore to 3 on flagships.

---

## 8. Cloud one-shot concurrency

`RemoteLlmDataSource` (the `uniunCloud` backend) is not wired into
`InferenceScheduler` at all — correctly so. There is no shared native
resource to protect: every call is an independent HTTP request, so
concurrent `generateOneShot` calls (Nataraj's background buffer top-up
overlapping a foreground fill; Nataraj and Gana both firing around the
same time) are meant to just run in parallel, not queue.

```
generateOneShot(A) ──┐
                      ├─► both run concurrently, tracked independently
generateOneShot(B) ──┘     in _extractions (Set<_InFlightExtraction>)

sendChat(...) / preemptBackgroundWork()
   └─► cancels every entry in _extractions
        (chat still gets priority over background cloud generation —
         same intent as the scheduler's T0, just enforced differently
         since there's no scheduler here to enforce it)
```

Each entry pairs one subscription with its own completer. `generateOneShot`
never cancels a sibling entry on arrival — only `sendChat`/
`preemptBackgroundWork` cancel all of them, and doing so now resolves
each cancelled entry (`Right(null)`) instead of leaving it hanging.
Before this, a single shared subscription field meant a second call
arriving mid-generation would cancel the first one's subscription without
ever resolving its `Completer` — the first caller hung forever.

A genuine stream error (network/API failure) resolves as `Left(Failure)`,
distinct from a cooperative cancel (`Right(null)`) — this lets
`GanaEngine`'s existing `failed`-vs-`skipped(modelSwapped)` branching
read an accurate signal instead of both cases looking identical.

Source: `lib/data/datasources/llm/remote_llm_data_source.dart`. Tests:
`test/data/datasources/llm/remote_llm_data_source_test.dart`.

---

## 9. `gana_workmanager` asymmetry

`lib/features/shiv/gana/engine/gana_workmanager.dart` is a top-level
`@pragma('vm:entry-point')` function the OS calls when the app is
backgrounded. It:

- runs in its **own isolate**,
- has **no DI** (`get_it` is not bootstrapped),
- opens its **own Isar**,
- calls `FlutterGemma.initialize()` and `openChat()` directly.

It therefore cannot share `InferenceScheduler`. By design — the
scheduler is a foreground-isolate concept, and when the app is
backgrounded there is no chat, no Nataraj page, no foreground hint to
respect, so the algorithm has nothing to schedule against.

The asymmetry is intentional and documented here so a future
contributor doesn't try to "fix" it by smuggling DI across isolates.

---

## 10. Edge cases

### Mid-stream model swap

A T0 chat arrives with `modelId == X` while a T4 Nataraj is running on
`modelId == Y`. The scheduler:

1. cancels Nataraj at the next token boundary (via `stopGeneration()`),
2. asks `AIModelRunner` to swap to model `X` (~10 s),
3. dispatches chat on `X`,
4. when chat finishes, returns to the picker — if Nataraj is the
   highest-tier candidate again it re-loads `Y` (one more swap).

Nataraj's lost prefill is the cost paid for instant chat. Acceptable.

### Cancel accounting (charging time fairly)

Even when a job is cancelled mid-flight, its consumed time is
charged to its `vruntime`. This matches CFS — "you ran, you pay". It
prevents a kind from gaming the scheduler by submitting jobs it knows
will be cancelled.

### Newcomer seeding

When a `kind` first appears (or returns after >5 min absence), set
`vruntime[kind] = min(_vruntime.values)`. Without this, a long-idle
producer would have `vruntime[kind] == 0` and monopolize the fair pool
on return until everyone else catches up.

### Long-idle decay

Every 5 minutes a sweeper halves all `vruntime` entries (`val *= 0.5`).
This keeps the counters bounded and ensures history doesn't
permanently penalize a producer.

### `_isReQueueable` exclusion list

Chat jobs are never re-queued on cancel — if a chat send is preempted,
something is very wrong (T0 only loses to itself), so the cancel
propagates as an error to the BLoC.

`modelSwitch` jobs are also absent from this list, for the opposite
reason: tier -1 is never preempted by anything, so re-queueability never
comes up. A gentle switch simply waits for its turn; a forced switch is
itself the thing doing the cancelling.

---

## 11. Verification scenarios

Scenarios 1–8 map to `test(...)` in
`test/data/datasources/llm/inference_scheduler_test.dart`. Scenarios
9–12 (added for the model-switch tier, issue #160 follow-on) map to the
same file's `Scenario 9`–`12` groups; the negative/edge cases below them
map to that file's `Negative — ...` groups. Scenarios 13–14 (cloud
concurrency) map to `test/data/datasources/llm/
remote_llm_data_source_test.dart`'s `concurrency` group.

| # | Scenario                                                                                              | Expected behavior                                                                                                                  |
| - | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1 | Nataraj running. User opens Shiv chat and types.                                                       | Within ≤1 token boundary (<500 ms), Nataraj cancelled, chat starts. Nataraj re-queued.                                              |
| 2 | Two Ganas at T4, FIFO would have Gana-A finish before Gana-B starts.                                   | vruntime alternation: Gana-A runs for ~30 s, then Gana-B starts, alternating; neither monopolizes.                                  |
| 3 | Gana cron fires past its scheduled time.                                                               | That Gana enters at T3, preempts any T4 Nataraj currently running.                                                                  |
| 4 | User navigates to NatarajDeckPage. A Gana is running.                                                  | Gana cancelled, Nataraj runs (T1). Gana re-queued; resumes when user leaves NatarajDeckPage.                                        |
| 5 | 500-note extract backfill loop submits one job per second.                                             | T2 ramps; after 60 % of a 5-min window is consumed by T2, picker skips T2 and dispatches T4 instead. Nataraj/Gana get the remaining 40 %. |
| 6 | Chat on model X. Two Gana jobs queued: one on X, one on Y.                                              | Picker prefers the X Gana (same model). Y Gana waits for a foreground signal or a chat idle gap before triggering a swap.            |
| 7 | User opens a note → extract triggered with `foregroundHint:true`. Nataraj running.                     | Extract promoted to T1, preempts Nataraj.                                                                                           |
| 8 | App backgrounded → `gana_workmanager` ticks.                                                           | Scheduler is dormant (no foreground); workmanager runs unaffected with its own direct `FlutterGemma` path.                          |
| 9 | Nataraj running. User picks a different, already-downloaded local model.                               | Nataraj runs to completion untouched. The switch runs immediately after, ahead of any job that arrived while it waited.             |
| 10 | User picks a different model while nothing is running.                                                | Switch runs immediately.                                                                                                            |
| 11 | Chat running. User deletes the currently-active model.                                                | Chat is cancelled immediately (not re-queued); the delete proceeds right away.                                                      |
| 12 | Nataraj/Gana running. User deletes the currently-active model.                                        | The job is cancelled and re-queued via the existing policy; it completes normally after the delete, against whatever model ends up active. |
| — | Negative: a gentle switch is queued; `setForeground()` toggles while it waits.                          | The running job is NOT preempted by the toggle — the switch keeps waiting for its own turn.                                         |
| — | Negative: two gentle switches queued back to back.                                                     | Both run, in submission order — no starvation.                                                                                      |
| — | Negative: a switch's action throws.                                                                    | Propagates as a normal `Future` error to the caller; the scheduler recovers and keeps dispatching.                                  |
| — | Negative: model affinity at tier -1.                                                                   | Ignored — a switch runs regardless of `_loadedModelId`, same as chat at T0.                                                          |
| 13 | Two `generateOneShot` calls overlap on the cloud backend (e.g. Nataraj background + foreground fill).  | Both complete independently; neither blocks or cancels the other.                                                                   |
| 14 | Chat starts while one or more cloud `generateOneShot` calls are in flight.                             | Every pending call is cancelled and resolves `Right(null)` (not left hanging); chat proceeds normally.                              |

---

## 12. Literature and "novelty" callout

The recipe is built on four classical schedulers (a) plus four
contemporary cloud-LLM-serving systems (b) that already publish very
similar tier+fairness combinations. UNIUN's contribution is the
**mobile adaptation**, not the algorithmic structure.

### (a) Classical foundations

**Linux CFS (Completely Fair Scheduler, Molnár 2007).** Linux's
default since 2.6.23. Each task accumulates `vruntime`; the picker
always chooses the lowest `vruntime`. We adopt this for the fair pool
(T4) and `min_vruntime`-style newcomer seeding.
*Reference:* `kernel/sched/fair.c` in the Linux source.
[Docs](https://docs.kernel.org/scheduler/sched-design-CFS.html).

**Earliest Deadline First (Liu & Layland, 1973).** Provably optimal
single-processor real-time algorithm: pick the job with the closest
deadline. We use it as a one-shot promotion (T3) for Gana cron ticks
past their fire time, not as the dominant scheduler.
*Reference:* Liu, C. L. and Layland, J. W. "Scheduling Algorithms for
Multiprogramming in a Hard-Real-Time Environment." *J. ACM* 20:1
(Jan 1973), 46–61.

**POSIX `SCHED_FIFO` + cgroup CPU shares.** Strict priority bands
above a CFS-managed default band. We adopt the same shape — strict
T0–T3 above the CFS-style T4.
*Reference:* POSIX.1-2017, IEEE Std 1003.1.

**FQ-CoDel / CAKE (Hoeiland-Joergensen et al., 2018).** Network fair
queueing — uses sparse-flow boosting so newcomer flows don't starve.
The `min_vruntime` newcomer-seeding rule is the same idea.
*Reference:* RFC 8290 (CoDel), RFC 8033 (PIE), CAKE paper.

### (b) Contemporary LLM-serving systems with similar structure

These are server-side schedulers, but the *algorithmic shape* — strict
priorities above a fairness layer, with deadline promotion and
preemption — is the same as UNIUN's T0–T4.

**BROS — *Efficient LLM Serving on Hybrid Real-time and Best-effort
Requests* (Apr 2025).** Splits requests into RT (latency-critical,
interactive) and BE (throughput-oriented, batch). Dynamic priority
scheduling with bidirectional KV-cache management for cross-tier
preemption. RT-vs-BE is structurally identical to UNIUN's T0–T3 vs T4.
*Reference:* [arXiv:2504.09590](https://arxiv.org/abs/2504.09590).

**PROSERVE — *Unified Multi-Priority Request Scheduling for LLM
Serving* (Dec 2025).** Two-tier framework with weighted priorities,
token-level deadline gains, and capacity reservation for high-value
tasks. Same shape as strict tiers + EDF deadline + soft budget.
*Reference:* [arXiv:2512.12928](https://arxiv.org/abs/2512.12928).

**VTC — *Locality-aware Fair Scheduling in LLM Serving* (Jan 2025).**
CFS adapted to LLM serving via virtual-token counters — token-based
proportional fairness across requests. Mechanically identical to our
T4 `vruntime` accounting.
*Reference:* [arXiv:2501.14312](https://arxiv.org/pdf/2501.14312).

**vLLM strict-priority scheduling.** vLLM's production scheduler uses
FCFS by default with preemption (recomputation or KV-swap) when out
of space; a strict-priority (SP) policy is available as an
alternative. Interactive arrivals preempt batch requests.
*Reference:* [IBM/vllm PR #48](https://github.com/IBM/vllm/pull/48),
[vllm-project/vllm RFC #6077](https://github.com/vllm-project/vllm/issues/6077),
[scheduling-in-inference-engines overview](https://fergusfinn.com/blog/scheduling-in-inference-engines/).

### What's actually UNIUN-specific

The honest delta vs the prior work above:

1. **UI-foreground tier hoisting.** Server systems have no "user is
   staring at this page" signal. UNIUN's `setForeground(LlmTaskKind)`
   driven by `initState` / `dispose` of `NatarajDeckPage` /
   `GanaFormPage` is the local contribution that doesn't appear in
   BROS, PROSERVE, VTC, or vLLM.

2. **Model-affinity batching with swap-cost awareness.** Cloud
   systems keep multiple models warm in HBM; the question is *which
   replica*, not *which model is loaded right now*. UNIUN can only
   hold one model in mobile RAM/GPU; the picker treats the ~10 s
   swap as a first-class cost and prefers same-model candidates
   even when their tier-tied vruntime would say otherwise.

3. **Single-device, single-context framing.** Everything cited in
   (b) is multi-GPU server inference. The constraint that drives our
   design — one `InferenceChat` slot, one loaded model — is mobile-
   specific.

### Naming

We refer to the policy we ship as the **UNIUN Scheduling Algorithm**
inside this repo as a naming convenience. It is *not* a first-of-its-
kind algorithm; the building blocks are now standard in cloud LLM
serving (BROS, PROSERVE, VTC, vLLM). The contribution worth pointing
at is the *mobile adaptation* in (1)–(3) above.

---

## 13. Future work

- **Agent-round scheduling.** Agentic Ganas / Shiv "deep answer" mode
  ([`agent_skills.md`](agent_skills.md) §9) submit each agent-loop
  round as one scheduler job — T4 for Gana rounds, T0 for Shiv —
  so chat preempts between rounds and vruntime bills per round. The
  design is specified there; the scheduler itself needs no change.
- **Dynamic embedding concurrency.** Read `system_info_plus`; raise
  `EmbeddingQueue` semaphore from 2 to 3 on flagships.
- **Per-task time slice (Linux CFS-style `sched_slice`).** Currently a
  chat completes in full before the picker re-runs. A future
  iteration could checkpoint at every N tokens for finer-grained
  fairness.
- **Priority inheritance** to handle the case where a T4 job holds a
  resource a T0 job needs. Not relevant today (no shared resources
  beyond the model context, which preemption already handles).
- **Continuous batching** (vLLM-style). Impractical on mobile GPUs
  without server-class memory bandwidth; revisit if hardware changes.
- **Multi-GPU.** N/A on mobile.
- **Scheduler observability.** A debug overlay showing live tier
  contents + vruntime + budget would help diagnose user-reported
  performance complaints.

---

## Cross-references

- [`SHIV_AI.md`](SHIV_AI.md) — overall Shiv architecture; the
  scheduler replaces the "ModelTaskQueue" section described there.
- [`Ganas.md`](Ganas.md) — Gana lifecycle; submission paths and
  model affinity rules are described in §6 above.
- [`graphrag.md`](graphrag.md) and [`rag.md`](rag.md) — embedding's
  role in retrieval; the embedding side queue (§7) lives next to but
  outside this scheduler.
- Issue [#118](https://github.com/basictech01/uniun/issues/118) — the
  bug this work resolves.
- Issue [#160](https://github.com/basictech01/uniun/issues/160) — the
  model-switch tier (§3) and cloud one-shot concurrency (§8) both
  originate from this issue's follow-on investigation.
