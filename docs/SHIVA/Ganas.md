# Ganas — User-Owned AI Agents with Brahma or Manas Knowledge

> **Status**: Phase 2 (shipped foreground; background tick installed; background inference gated on `flutter_gemma_bg_isolate_test.dart`).
> **Lives in**: Shiv (the AI assistant tab).
> **Companion**: `docs/BRAHMA/Manas.md` (the knowledge bases Ganas consume).
>
> **2026-06-20 refactor**: the foreground engine moved from its own Dart
> isolate **into the main isolate** as a `@lazySingleton`. The SendPort
> bridge, inference server, output dispatcher, and `GanaPendingOutputModel`
> are gone. Rationale + trade-offs in §2 + §7 below. The WorkManager
> background-tick path is unchanged (it has its own ephemeral isolate
> spawned by the OS).

A **Gana** ("गण" — a band, group, or attendant in Sanskrit) is a user-defined AI worker. The user gives it knowledge (the whole **Brahma** knowledge base or a **Manas**), instructions (a **task prompt**), an **input** to watch, an **output** to publish to, and **triggers**. Once enabled, the Gana runs by itself — on-device — and publishes results as real Nostr events.

Ganas are **purely local config** — they never broadcast as Nostr events. Two devices with the same identity have independent Gana sets.

---

## Table of Contents

1. [Functional model](#1-functional-model)
2. [Topology](#2-topology)
3. [Manas Context Loader](#3-manas-context-loader)
4. [Data model](#4-data-model)
5. [Domain layer](#5-domain-layer)
6. [Single-run lifecycle](#6-single-run-lifecycle)
7. [Does the main-isolate engine block the UI?](#7-does-the-main-isolate-engine-block-the-ui)
8. [Background execution](#8-background-execution)
9. [Self-loop + safety guards](#9-self-loop--safety-guards)
10. [UI placement](#10-ui-placement)
11. [Folder structure](#11-folder-structure)
12. [Open follow-ups](#12-open-follow-ups)

---

## 1. Functional model

### 1.1 What a Gana has

| Field | Notes |
|---|---|
| `name` | required, ≤60 chars |
| `description` | optional |
| `manasIds` | Empty means Brahma (whole knowledge base); the form can select one Manas. Older rows with several Manases still merge their context under a shared budget. |
| `taskPrompt` | user-authored instructions injected into every prompt |
| `inputType` + `inputRefId` | input surface — `channel`, `privateChannel`, `dm`, `user`, `followedNote`, or `null` (standalone) |
| `outputType` + ref | destination — `feed`, `channel`, `privateChannel`, `dm` (exactly one is published per run) |
| `desiredModelId` + `desiredBackend` | `desiredBackend == null` ⇒ local, skip-on-mismatch against the active on-device model (unchanged legacy behavior). `desiredBackend == uniunCloud` ⇒ this Gana always runs on `desiredModelId` via the UNIUN Cloud gateway, independent of whatever backend/model the rest of the app has active — see §1.3. |
| `triggerMode` | `recurring` (cron-style, fires forever until disabled) OR `oneShot` (fires once, auto-disables) |
| `triggerReactive` | fires within ~3s of a new note on the input surface |
| `triggerIntervalMinutes` | `Timer.periodic` clamped ≥5 min (≥30 min in background) |
| `enabled` | master switch (defaults to `false` — opt-in after review) |

The form UI folds these three trigger fields behind a single **"When should this run?"** radio (`GanaTriggerPreset`, `lib/core/enum/gana_trigger_preset.dart`). Five presets map onto the matrix: `onceOnEnable`, `onceOnFirstMessage`, `everyMessage`, `onSchedule`, `messageOrSchedule`. `GanaTriggerPreset.validFor(inputType)` hides options that can't fire (e.g. `everyMessage` with no input). The raw fields stay in Isar — the preset is a UI fold only — so legacy rows continue working with no migration.
| Cursor | `lastProcessedEventId`, `lastProcessedCreated`, `lastRunAt` |

### 1.2 The "Life Lessons Replier" example

```
User config:
  name:        "Life Lessons Replier"
  manases:     [Life Lessons]   (47 saved + own + draft notes)
  input:       Channel #daily-thoughts (joined)
  output:      Channel #daily-thoughts (same)
  trigger:     Reactive
  taskPrompt:  "When someone posts a question or reflection here, pick
                the most relevant note from my Manas and reply with a
                1-2 sentence paraphrase that adds value."

Run trace (post-refactor):
  1. Bob posts kind-42 in #daily-thoughts.
  2. Gateway writes it to noteModels.
  3. Main-isolate engine's noteModels.watchLazy() fires; debounced 3s.
  4. Input filter selects Bob's message (created > cursor, not self,
     not in our own output history).
  5. Manas Context Loader embeds Bob's message, vector-searches the
     Manas pool, and packs the top scored hits under the token budget.
  6. Prompt assembled: SYSTEM rules → USER instruction → KNOWLEDGE
     → INPUT (Bob's msg).
  7. Engine calls AIModelRunner.generateOneShot() with
     `kind: LlmTaskKind.gana` + `modelId: gana.desiredModelId` — the
     InferenceScheduler places it at T4 (fair pool) by default, or T1
     when the GanaForm preview is open, or T3 when the cron deadline
     has passed. Shiv chat (T0) preempts. See scheduling.md.
  8. Reply sanitized through LlmTextSanitizer (envelope strip + GPT-2
     byte-pass decode for emoji).
  9. <NOOP> sentinel check: no. Body extracted.
 10. Engine calls CreateChannelMessageUseCase directly (no pending
     table, no dispatcher hop).
 11. Existing publish path: NoteModel.put + EventQueueModel.put →
     gateway → relay.
 12. Cursor advanced; GanaRunModel.succeeded logged with the
     outputEventId.
 13. Bob sees the reply in #daily-thoughts within ~10s.
```

### 1.3 Cloud pin (`desiredBackend == uniunCloud`)

A Gana pinned to a UNIUN Cloud model bypasses the on-device gate entirely,
in both isolates:

- **Foreground (`GanaEngine`)**: skips `FlutterGemma.hasActiveModel()` and
  calls `GenerateOneShotUseCase` (`lib/domain/usecases/llm_usecases.dart`)
  with `backendOverride: uniunCloud, modelIdOverride: desiredModelId`.
  `LlmRepositoryImpl` routes straight to `RemoteLlmDataSource` for that one
  call — it never reads or changes the app's globally active backend
  (`LlmPreferencesDataSource.activeBackend`), so a cloud-pinned Gana and a
  local Shiv chat session coexist without either stepping on the other.
  Not connected to UNIUN Cloud, or no `desiredModelId` set ⇒
  `GanaSkipReason.cloudUnavailable`, retried next trigger — no fallback to
  local. A cloud-pinned Gana running at the same time as a cloud-backed
  Nataraj fill (or another cloud Gana) no longer races it — see
  `scheduling.md` §8, "Cloud one-shot concurrency": each `generateOneShot`
  call is tracked independently, so concurrent cloud calls complete on
  their own instead of one silently hanging when another arrives.
- **Background (`gana_workmanager.dart`)**: same skip-on-unavailable
  contract, but reached differently since the isolate has no DI. The main
  isolate reads the already-minted UNIUN Cloud API key from
  `LlmCredentialsDataSource` once, at `GanaWorkmanagerBootstrap.scheduleBackground()`
  time, and hands a copy to the bg isolate via `inputData` — same pattern as
  `privkeyHex`. The bg tick then calls `UniunGatewayClient().chatCompletion(...)`
  directly (no DI, no re-auth handshake); a rejected/expired key just fails
  the run like any other inference error. `FlutterGemma.initialize()` is
  skipped for a tick whose one due Gana is cloud-pinned.
- Local pins can't cheaply switch which on-device model is loaded mid-run
  (that's a ~9s swap of the app's actual active model) — that's why local
  keeps the original skip-on-mismatch gate instead of an override. Cloud
  model selection is just an HTTP parameter, so there's no such cost.

---

## 2. Topology

Two isolates total now: the main app isolate (which owns the foreground
engine alongside everything else) and the WorkManager dispatcher's
ephemeral OS-spawned isolate. The gateway has its own isolate, which is
the existing relay-sync component — it doesn't host Gana logic.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          MAIN ISOLATE (UI)                                │
│                                                                          │
│  ShivHistoryDrawer ─► GanaListBloc ─► GetGanasUseCase ─► Isar (Gana*)    │
│  GanaFormPage      ─► GanaFormBloc ─► UpsertGanaUseCase                  │
│  GanaDetailPage    ─► GetGanaRunsUseCase                                 │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ GanaEngine  (@lazySingleton, started in HomePage.initState)        │ │
│  │                                                                    │ │
│  │   ├ Isar.ganaModels.watchLazy()    ─► schedule rebuild (500ms)     │ │
│  │   ├ Isar.noteModels.watchLazy()    ─► reactive Ganas (3s debounce) │ │
│  │   ├ Timer.periodic(N min)          ─► interval Ganas               │ │
│  │   ├ InferenceScheduler             ─► kind=gana + desiredModelId,  │ │
│  │   │                                   T4 fair pool by default,     │ │
│  │   │                                   T3 if cron deadline passed,  │ │
│  │   │                                   T1 while GanaForm preview is │ │
│  │   │                                   open. See scheduling.md.     │ │
│  │   │                                                                │ │
│  │   └ One run:                                                       │ │
│  │      1. Self-output guard set loaded                               │ │
│  │      2. GanaInputFilter (per-type Isar query + cursor +            │ │
│  │         drop-self-pubkey + drop-self-outputs)                      │ │
│  │      3. Reply ancestry (up to 2 hops)                              │ │
│  │      4. ManasContextLoader.merge                                   │ │
│  │           • input present ⇒ embed query, vector-search,            │ │
│  │             intersect with Manas membership, pack top-K            │ │
│  │           • else ⇒ newest-first fallback                           │ │
│  │      5. GanaPromptBuilder — SYSTEM rules + USER instruction +      │ │
│  │         KNOWLEDGE + INPUT (no `publish_message(body=...)` ask)     │ │
│  │      6. Model gate (FlutterGemma.hasActiveModel)                   │ │
│  │      7. AIModelRunner.generateOneShot(kind=gana,                   │ │
│  │         modelId=gana.desiredModelId) — InferenceScheduler picks    │ │
│  │         the tier (T4 default · T1 form · T3 cron). Chat preempts.  │ │
│  │      8. LlmTextSanitizer cleans envelope + GPT-2 byte-pass mojibake│ │
│  │      9. NOOP sentinel check; else call publish use case directly:  │ │
│  │           • PublishNoteUseCase (feed, kind 1)                      │ │
│  │           • CreateChannelMessageUseCase (channel, kind 42)         │ │
│  │           • SendDmUseCase (DM, NIP-17 gift-wrap)                   │ │
│  │           • SendPrivateChannelMessageUsecase (NIP-29 MLS)          │ │
│  │     10. Log GanaRunModel + advance cursor                          │ │
│  │     11. One-shot Ganas auto-disable on successful publish          │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  HomePage (WidgetsBindingObserver)                                       │
│    AppLifecycleState.paused  ─► GanaWorkmanagerBootstrap.scheduleBg()    │
│    AppLifecycleState.resumed ─► GanaWorkmanagerBootstrap.cancelBg()      │
└──────────────────────────────────────────────────────────────────────────┘
                                  ▲       │
                                  │       │  Isar (shared DB on-disk)
                                  │       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│              WORKMANAGER ISOLATE  (ephemeral, OS-dispatched)              │
│                                                                          │
│  ganaWorkManagerDispatcher (top-level, @pragma vm:entry-point)           │
│   ├ Fires ~30 min after AppLifecycleState.paused                         │
│   ├ BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken) │
│   ├ Opens own Isar at the shared path                                    │
│   ├ Loads flutter_gemma fresh (verified by                               │
│   │   integration_test/flutter_gemma_bg_isolate_test.dart)               │
│   └ Walks enabled interval Ganas, ONE per tick:                          │
│       ─► feed (kind 1) / channel (kind 42): sign locally, write          │
│          EventQueueModel directly (gateway broadcasts on next watcher    │
│          tick). NoteModel.put for local visibility.                      │
│       ─► DM (NIP-17) / private channel (NIP-29 MLS): SKIPPED in bg.      │
│          Foreground engine reactively picks the same input up on next    │
│          app open. (Limitation: one-shot DM/PC Ganas with no reactive    │
│          trigger won't fire from a killed app.)                          │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
                                  │  EventQueueModel rows from publish use cases
                                  ▼
                  GATEWAY ISOLATE (existing) ──► relay broadcast
```

### Why no engine isolate any more

Pre-refactor, the engine lived in its own Dart isolate and bridged into
the main isolate via `SendPort → GanaInferenceServer →
LocalInferenceQueue → flutter_gemma`. Replies came back via `SendPort`,
then the engine wrote a `GanaPendingOutputModel` row that a main-isolate
`GanaOutputDispatcher` drained via `watchLazy`. Six hops per run.

The engine's hot-path work breaks down as:

| Step | Type | Blocks Dart event loop? |
|---|---|---|
| Isar `watchLazy()` callback | Async stream tick | No |
| Build prompt (string concat + Isar reads) | Async + cheap | No (Isar is async) |
| `AIModelRunner.generateOneShot` | FFI to native threads | No |
| Per-token stream callback (~50µs × 180) | Async stream tick | No |
| Publish use case (NoteModel.put + EventQueueModel.put) | Async + writeTxn | No |

Nothing in there is pure-Dart CPU-bound. The 200-second generation runs
on native threads (`execution_thread_pool` + `callback_thread_pool`
visible in the native logs). The Dart isolate is parked on awaits
99.99% of the time. So a separate isolate buys nothing measurable while
costing 6 hops + a duplicate Isar handle.

What we kept:

- **`InferenceScheduler`** (see [`scheduling.md`](scheduling.md)) — chat
  preemption still matters because the GPU is one-at-a-time.
  flutter_gemma 1.x's concurrent-sessions feature removes model
  duplication, not GPU serialization. The scheduler's T0 chat tier is
  what makes preemption usable in practice.
- **WorkManager bg isolate** — separate concern. OS-dispatched, can't
  share with main. Stays exactly as-is.

---

## 3. Manas Context Loader

`lib/features/shiv/generation/context/manas_context_loader.dart`

> Relocated 2026-06-21 from `gana/engine/` into the shared `generation/` substrate
> (also used by Nataraj, Shiv chat, and the composer-chat). Now an
> `@lazySingleton`: the **main-isolate instance** `merge` / `searchAll` use the
> injected `Isar`, while the **static** `packNewest` / `loadPool` / `loadAll`
> take an `isar` param so the DI-less background WorkManager isolate can call
> them. `searchAll(query:)` ranks over the whole vector index (the "All notes"
> scope).

```
ManasContextLoader.merge({            // main-isolate instance method
  required List<String> manasIds,
  required int budget,                  // tokens
  String? relevanceQuery,               // optional — usually the input text
}) async → List<PackedNote>

   1. For each manasId in manasIds:
        link rows = ManasNoteLinkModel where manasId == this
        add all noteIds to a Set (dedupes across manases)

   2. Branch on whether we have a relevance query:

      ─ By-relevance (when relevanceQuery is non-empty):
          a. EmbeddingService.embed(query)  → vector
          b. VectorSearchService.search(queryVector: vec, topK: 50)
          c. Intersect with the Manas membership Set (preserves score order)
          d. Resolve each surviving id (saved → notes → drafts)
          e. Pack high-score first under the char budget
          f. On any failure (no embedder, no vector index) fall through.

      ─ Newest-first (fallback):
          a. Resolve every id in the Set
          b. Sort by `created` desc
          c. Pack newest-first under the char budget

   3. Skip oversize notes rather than truncate (truncation changes meaning).
```

Why we now use the embeddings: every saved/own note already gets its
embedding upserted to tostore via the existing RAG pipeline (`🧠
EmbedAndStore` in the logs). The infrastructure was sitting there; the
engine being in the main isolate made it a 5-line addition instead of a
cross-isolate plumbing project. Reactive Ganas now retrieve by
similarity to the actual input message instead of by recency, which is
the right semantic for "reply with the most relevant note."

Standalone Ganas (no input) still use newest-first — there's nothing to
score against.

For a Gana with empty `manasIds`, the foreground engine uses `mergeAll` and
the background worker uses `packAllNewest`. Both use `loadAll` to collect
saved notes, the active user's own notes, drafts, and notes linked to any
Manas, then dedupe and pack under the same token budget. The foreground
path ranks against an input message when one is available. The form treats
empty `manasIds` as the explicit Brahma choice; returning from Manas creation
refreshes only the picker so an unsaved Gana draft stays intact.

---

## 4. Data model

Two new Isar collections (plus existing `ManasModel` / `ManasNoteLinkModel`).
The third (`GanaPendingOutputModel`) was deleted in the 2026-06-20 refactor
— the foreground engine publishes directly now, no handoff table needed.

```
┌──────────────────────────────┐  ┌──────────────────────────────┐
│ GanaModel                    │  │ GanaRunModel                 │
├──────────────────────────────┤  ├──────────────────────────────┤
│ Id  id                       │  │ Id  id                       │
│ String ganaId (uniq)         │  │ String runId (uniq)          │
│ String name                  │  │ String ganaId (idx)          │
│ String? description          │  │ DateTime startedAt (idx)     │
│ List<String> manasIds        │  │ GanaRunStatus status         │
│ String taskPrompt            │  │  (running|succeeded|         │
│ GanaInputType? inputType     │  │   skipped|failed)            │
│ String? inputRefId           │  │ GanaSkipReason? skipReason   │
│ GanaOutputType outputType    │  │  (noActiveModel|             │
│ String? outputChannelId      │  │   modelMismatch|             │
│ String? outputGroupId        │  │   noNewInput|modelSwapped|   │
│ int? outputDmConversationId  │  │   noopReturned)              │
│ String? desiredModelId       │  │ List<String> inputEventIds   │
│ bool triggerReactive         │  │ String? outputEventId        │
│ int? triggerIntervalMinutes  │  │ String? error                │
│ bool enabled                 │  └──────────────────────────────┘
│ String? lastProcessedEventId │
│ DateTime? lastProcessedCrtd  │  Retention: per-Gana 10 newest,
│ DateTime? lastRunAt          │  global cap 1000, pruned every
│ int? runsSucceeded           │  6h by CleanupManager (Phase 3).
│ int? runsFailed              │
│ int? runsSkipped             │  The three counters are the only
│ DateTime createdAt           │  lifetime figures: `writeGanaRun`
│ DateTime updatedAt           │  bumps them in the same transaction
└──────────────────────────────┘  as the log row, so pruning never
                                  loses them.

(`GanaPendingOutputModel` removed — engine publishes directly.)
```

The counters are per-device local state like the cursor (not in the mesh body,
kept across edits by `upsertGana`). They are **nullable** on purpose: Isar reads
a field missing from an older row as the minimum integer, so a non-nullable
counter would start hugely negative; `toDomain()` turns null into 0. A finished
run is counted once per `runId`; `running` is never counted.

Schemas registered in `lib/data/datasources/isar_schemas.dart`:
`GanaModelSchema`, `GanaRunModelSchema`. Additive — existing installs
pick them up on next launch without migration.

---

## 5. Domain layer

```
lib/domain/
├── entities/gana/
│   ├── gana_entity.dart           freezed mirror of GanaModel
│   └── gana_run_entity.dart       freezed mirror of GanaRunModel
│
├── repositories/
│   ├── gana_repository.dart       upsert / list / enabled / byId / delete
│   │                              setEnabled / advanceCursor
│   └── gana_run_repository.dart   logRun / getRunsFor / getOutputEventIdsFor
│                                  pruneOldRuns
│
└── usecases/gana_usecases.dart    11 @lazySingleton use cases grouped:
                                     UpsertGanaUseCase
                                     GetGanasUseCase
                                     GetEnabledGanasUseCase
                                     GetGanaByIdUseCase
                                     DeleteGanaUseCase
                                     SetGanaEnabledUseCase
                                     AdvanceGanaCursorUseCase
                                     LogGanaRunUseCase
                                     GetGanaRunsUseCase
                                     GetGanaOutputEventIdsUseCase
                                     PruneGanaRunsUseCase
```

Two `@Injectable(as: ...)` repository impls in `lib/data/repositories/`:
`gana_repository_impl.dart` and `gana_run_repository_impl.dart`. All writes inside `isar.writeTxn`.

---

## 6. Single-run lifecycle

```
                ┌──────────────────────────────────────────┐
                │ Reactive watcher OR interval timer tick  │
                └──────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │ Single-flight mutex held? │── yes ──► return (skip)
                    └───────────────────────────┘
                                  │ no
                                  ▼
                    ┌─────────────────────────────────────┐
                    │ Re-fetch GanaEntity from Isar       │
                    │ (config may have changed mid-debounce)│
                    └─────────────────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────────────┐
                    │ Load self-output ids                │
                    │ Run GanaInputFilter (per-type)      │
                    └─────────────────────────────────────┘
                                  │
                  ┌───────────────┼───────────────┐
                  │ inputType != null AND inputs.isEmpty
                  ▼
        ┌───────────────────────────┐
        │ return (no cursor advance)│  next trigger re-tries
        └───────────────────────────┘
                  │ otherwise
                  ▼
                    ┌─────────────────────────────────────┐
                    │ Reply ancestry (up to 2 hops)       │
                    │ ManasContextLoader.merge            │
                    │ GanaPromptBuilder.build             │
                    └─────────────────────────────────────┘
                                  │
                                  ▼
                    ┌──────────────────────────────────────┐
                    │ AIModelRunner.generateOneShot(        │
                    │   kind: LlmTaskKind.gana,             │
                    │   modelId: gana.desiredModelId        │
                    │           ?? activeModelId,           │
                    │   deadline: cronFireTime (if cron),   │
                    │ )                                     │
                    │   ─► InferenceScheduler picks tier:   │
                    │      T1 if GanaFormPage open,         │
                    │      T3 if past cron deadline,        │
                    │      T4 fair-pool otherwise.          │
                    │   Model affinity batches same-model   │
                    │   Ganas to amortize swap cost.        │
                    │   See docs/SHIVA/scheduling.md.       │
                    └──────────────────────────────────────┘
                                  │
                ┌─────────────────┼─────────────────────────┐
                ▼                 ▼                         ▼
   skippedNoActiveModel  skippedCancelled  ok              failed
   skippedModelMismatch  (runner returned                  log run.failed
   noopReturned           null mid-stream)                 (no cursor advance)
        │                          │                       │
        ▼                          ▼                       │
   log run.skipped     log run.skipped(modelSwapped)      │
   (no cursor adv.)    (no cursor adv.)                   │
                                                          │
        ┌─────────────────────────────────────────────────┘
        │ ok
        ▼
    ┌─────────────────────────────────────┐
    │ Call publish use case directly:     │
    │   - PublishNoteUseCase (feed)       │
    │   - CreateChannelMessageUseCase     │
    │   - SendDmUseCase (NIP-17)          │
    │   - SendPrivateChannelMessageUsecase│
    │     (NIP-29 MLS)                    │
    │ Returns outputEventId               │
    │                                     │
    │ Log GanaRunModel.succeeded with     │
    │   outputEventId set                 │
    │ Advance cursor (eventId, time)      │
    │ One-shot Ganas auto-disable here    │
    └─────────────────────────────────────┘
```

Cursor is **never** advanced on skip or fail. The same input is retried on the next trigger. Idempotency falls out for free because the input filter is timestamp-cursor based + self-output guard.

---

## 7. Does the main-isolate engine block the UI?

**No.** Empirically verified — Manas note extraction has been running in
the main isolate since launch via the same `AIModelRunner.generateOneShot
→ LocalInferenceQueue` path, while the user scrolls and types without
hitches. Ganas use the same plumbing.

The full call chain post-refactor:

```
Reactive watcher / interval timer / fire-on-enable
  └─► GanaEngine._runIfPossible (single-flight mutex)
        └─► _runOnce
              ├─ Isar reads (input filter, ancestry, Manas links)   [async]
              ├─ EmbeddingService.embed (if reactive)               [FFI → native]
              ├─ VectorSearchService.search                         [async]
              ├─ Prompt build (string concat)                        [<1ms]
              ├─ AIModelRunner.generateOneShot(kind=gana)             [FFI]
              │    └─ InferenceScheduler → tier T4 / T3 / T1
              │         └─ flutter_gemma native threads             [native pool]
              │             ─► chat (T0) preempts via
              │                InferenceChat.stopGeneration
              ├─ LlmTextSanitizer.clean                              [<1ms]
              └─ Publish use case
                  ├─ NoteModel.put (writeTxn)                        [async]
                  └─ EventQueueModel.put (writeTxn)                  [async]
```

Where Dart-thread time goes during a 200-second run:

| Phase | Dart-thread time |
|---|---|
| Watcher dispatch + scheduling | ~1ms |
| Isar reads (input + ancestry + Manas) | ~10-30ms |
| EmbeddingService.embed (when reactive) | <10ms Dart-side (TFLite native) |
| VectorSearchService.search | ~5-20ms |
| Prompt build | <1ms |
| AIModelRunner stream callbacks | ~50µs × 180 = ~10ms total |
| Sanitize | <1ms |
| Publish writes | ~10-30ms |
| **Total Dart-thread per run** | **~50-100ms spread over 200,000ms** |

That's <0.05% of wall clock spent on the Dart event loop. UI frames at
60Hz (16ms budget) are unaffected.

What flutter_gemma actually does: each `TextResponse` chunk crosses
back from a C++ thread via FFI as a stream event. The Dart side handles
the chunk in microseconds (sanitize-tracker, scrubber, buffer.write).
Native decoding continues independently on `execution_thread_pool`.

Edge cases that DO have a measurable cost on the main isolate:

- **First model load** (`litert_lm_engine_create` — ~10s observed).
  Happens once per chat session open. flutter_gemma already spawns an
  internal helper isolate for the heavy lift (note in the log:
  `(includes isolate spawn ~50-200ms)`), but the orchestrating Dart
  side does pay ~100-300ms in scattered work during that 10s window.
- **Burst publish** (NoteModel.put + EventQueueModel.put back-to-back,
  plus gateway watcher waking). ~50-100ms hitch visible once per Gana
  publish. Same cost as a user-typed publish from Brahma.

Both were present before the refactor too. Nothing got worse.

**`generateOneShot` returns `null` on preempt or model swap.** Engine
treats it as cancelled, logs `modelSwapped` if the active model id
actually changed between request start and return, and does NOT advance
cursor → next trigger retries cleanly.

---

## 8. Background execution

> "if my app is running in the bg like i press the home button then running and if remove from the bg then stop right what are you trying to say"

Three states:

| App state | Engine isolate | WorkManager | What runs |
|---|---|---|---|
| **Foreground** | Active | Cancelled | Reactive + interval triggers fire; inference happens; publishes happen |
| **Backgrounded** (home pressed, still in recents) | Suspended by OS | One-shot fired ~30 min after pause | Tick only bumps `lastRunAt` on due Ganas. No inference. Foreground catches up on next open |
| **Killed** (swiped from recents) | Dead | Still fires (OS-level scheduler) | Same as backgrounded — cursor-bump only, no inference in v1 |

```
                              App lifecycle
                              ─────────────
                                    │
   ┌──────────────────┐             │             ┌──────────────────────┐
   │ FOREGROUND       │             │             │ BACKGROUND / KILLED  │
   │                  │ ──paused──► │ ──killed──► │                      │
   │ Engine isolate:  │             │             │ Engine isolate:      │
   │   reactive       │             │             │   suspended/gone     │
   │   interval       │             │             │                      │
   │   inference      │             │             │ WorkManager fires    │
   │   publish        │             │             │   every ~30 min:     │
   │                  │             │             │   bump lastRunAt     │
   │                  │ ◄─resumed── │             │   (no inference v1)  │
   └──────────────────┘             │             └──────────────────────┘
                                    │
                                    │ when user reopens:
                                    │   foreground engine sees
                                    │   bumped Ganas as "due" and
                                    │   runs inference immediately.
```

### 8.1 Native plumbing

| Platform | What we added | Why |
|---|---|---|
| Android | `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` permissions | foreground service required for tasks beyond 10-min wall budget; wake lock keeps the CPU awake for the tick |
| iOS Info.plist | `UIBackgroundModes: [fetch, processing]`; `BGTaskSchedulerPermittedIdentifiers: [in.uniun.app.gana.tick]` | BGTaskScheduler refuses to launch a task whose identifier wasn't pre-declared |
| iOS AppDelegate.swift | `WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "in.uniun.app.gana.tick")` inside `application(_:didFinishLaunchingWithOptions:)` BEFORE the super call | iOS requires the Swift-side handler registration during the launch window — Info.plist alone is not enough. Without this, `registerOneOffTask` submits successfully on the Dart side but the OS never fires the task. |
| pubspec | `workmanager: ^0.9.0` | cross-platform background scheduler. 0.7+ fixed foreground-registration NPE; 0.8 dropped `isInDebugMode` (now no-op). |

### 8.2 Testing background tasks

Background ticks are notoriously hard to verify because the OS schedules them on its own clock. Use these tools instead of waiting:

**iOS — simulator NEVER fires BG tasks.** Apple documents this: BGTaskScheduler tasks are not delivered in the simulator. Always test on a physical device. From an Xcode lldb console, while the app is paused, you can force-fire one:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"in.uniun.app.gana.tick"]
```

**Android — Doze + App Standby Buckets defer one-off tasks.** Even with everything wired correctly the OS may delay the job for hours, especially if the user hasn't opened the app recently. Force-fire via adb:

```bash
# list jobs scheduled by our app
adb shell dumpsys jobscheduler | grep -A 20 in.uniun.app

# run the scheduled job immediately (replace 999 with the job id from dumpsys)
adb shell cmd jobscheduler run -f in.uniun.app 999
```

**`initialDelay` is Android-only.** On iOS the parameter is silently ignored — iOS picks its own wake time.

### 8.3 The unanswered question — v2 background inference

flutter_gemma 1.0.0's docs are silent on whether `FlutterGemma.initialize()` + `openChat()` work in a background isolate. We don't ship background inference in v1 because shipping unverified inference behaviour means broken Ganas that the user can't debug.

The test that answers this lives at `test/integration/flutter_gemma_bg_isolate_test.dart`. Move to `integration_test/` and run on a real device with a model already installed. Three outcomes:

- **OK** → green light. ~30-line patch in `gana_workmanager.dart` swaps the cursor-bump for real inference. Background Ganas become independent of foreground.
- **SKIP** → preconditions not met (no model installed). Re-run.
- **FAIL** → halt; ship queue-then-foreground forever (or until flutter_gemma adds bg-isolate support upstream). Document the limitation here in §8.

---

## 9. Self-loop + safety guards

| Layer | Guard | What it prevents |
|---|---|---|
| Input filter | `authorPubkey != selfPubkey` | Self-loops (Gana reads its own publish) + Gana-to-Gana ping-pong (one user's Gana A publishes → their Gana B reads → publishes → A reads → …) |
| Input filter | `eventId ∉ this Gana's output history` | Belt+suspenders against the same |
| Run gate | `desiredModelId` carried into the scheduler | Model-affinity rules batch same-model Ganas; mismatched Ganas wait for an affinity opportunity instead of skipping outright |
| Run gate | `FlutterGemma.hasActiveModel()` | Skip cleanly with `noActiveModel` if model is uninstalled |
| Cursor | NOT advanced on skip/fail | Same input retried next trigger; never lose work |
| Scheduler | `InferenceScheduler` (5-tier — see [`scheduling.md`](scheduling.md)) | Chat (T0) preempts; GanaForm preview hoists to T1; cron deadlines promote to T3; CFS fair pool at T4 stops Nataraj from starving Gana |
| Publish | use-case-level errors → `GanaRunStatus.failed` | Publish failures surface in the run log; engine does not retry automatically (next trigger will re-attempt naturally) |
| Form | `enabled = false` default | User must explicitly turn on after reviewing config — no surprise publishes |
| Form | Interval ≥ 5 min | Foreground; background clamps to ≥ 30 min |
| Cleanup | Per-Gana 10 / global 1000 | `GanaRun` log doesn't grow unbounded; pruned every 6h |

---

## 10. UI placement

The **Shiv drawer** hosts Ganas alongside the existing chat history.

```
Shiv tab
  └─ ShivChatPage  Scaffold(drawer: ShivHistoryDrawer)
       └─ ShivHistoryDrawer (280 wide — matches Vishnu / Brahma)
            ├─ Header
            ├─ GANAS section (collapsible)
            │    ├─ "+ New Gana" → pushNamed(shivGanaForm)
            │    └─ GanaTile (× N)
            │         ├─ name
            │         ├─ trigger summary ("Reactive · Every 30m")
            │         ├─ last-run badge ("Succeeded · 2 min ago")
            │         ├─ tap     → pushNamed(shivGanaDetail, ganaId)
            │         └─ long    → bottom sheet (Enable/Disable, Edit, Delete)
            └─ CONVERSATIONS section (existing, unchanged behaviour)
```

`GanaFormPage` (route `shivGanaForm`):

```
┌──────────────────────────────────┐
│ New Gana                  Save   │
├──────────────────────────────────┤
│ Name                              │
│ [_____________________]           │
│                                   │
│ Description                       │
│ [_____________________]           │
│                                   │
│ MANASES                           │
│ Pick one or more …                │
│ [Rust Expert ✓] [Life Lessons]…   │  multi-select chips
│                                   │
│ Task prompt                       │
│ [ multi-line ]                    │
│                                   │
│ INPUT                             │
│ ▾ Public channel                  │  dropdown of GanaInputType
│ ▾ #daily-thoughts                 │  type-aware ref picker
│                                   │
│ OUTPUT                            │
│ ▾ Public channel                  │
│ ▾ #daily-thoughts                 │
│                                   │
│ MODEL                             │
│ ▾ Use whichever model is active   │  +N installed models
│                                   │
│ TRIGGERS                          │
│ [⬤] React to new input             │
│ Run every  [ 30 ] minutes (min 5) │
│                                   │
│ [⬤] Enabled                        │
│                                   │
│ (edit mode only)                  │
│ Delete Gana                       │
└──────────────────────────────────┘
```

`GanaDetailPage` (route `shivGanaDetail/:ganaId`) shows the same config as a read-only summary plus lifetime done / failed / skipped, an outcome bar, and the last 10 runs from `GanaRunModel` as drop-downs: a succeeded run opens to the note it published, a failed run to a plain-words reason (no identity / publish / network / model / other, sorted from the raw message by `GanaRunError.parse`) with the raw error underneath, a skipped run to a sentence for its skip reason.

`GanaDashboardPage` (route `shivGanaList`, opened from the Shiv home "Gana" button) is the Gana screen — there is no separate list page. Header: common back button and a New button (empty state has one too). Body: Active / Done / Failed / Skipped totals, a "needs attention" list (Ganas whose last run failed, with the error), every Gana with its outcome bar, counts, success rate and an on/off switch, and the 10 newest runs across all Ganas. It shares `GanaListBloc` with the list, so it refreshes as the engine runs. Success rate is done ÷ (done + failed); skipped runs are left out because a Gana waiting for input skips a lot without failing. Each Gana card also shows its trigger and scope.

---

## 11. Folder structure

```
lib/
├── core/enum/
│   ├── gana_input_type.dart           channel/privateChannel/dm/user/followedNote
│   ├── gana_output_type.dart          feed/channel/privateChannel/dm
│   └── gana_run_status.dart           running/succeeded/skipped/failed
│                                      + GanaSkipReason enum
│
├── data/
│   ├── datasources/isar_schemas.dart  GanaModelSchema, GanaRunModelSchema,
│   │                                  GanaPendingOutputModelSchema registered
│   ├── models/
│   │   ├── gana_model.dart            Isar collection + toDomain ext
│   │   ├── gana_run_model.dart        Isar collection
│   │   └── gana_pending_output_model.dart  engine→main publish queue
│   └── repositories/
│       ├── gana_repository_impl.dart       @Injectable
│       └── gana_run_repository_impl.dart   @Injectable
│
├── domain/
│   ├── entities/gana/
│   │   ├── gana_entity.dart           freezed
│   │   └── gana_run_entity.dart       freezed
│   ├── repositories/
│   │   ├── gana_repository.dart       interface
│   │   └── gana_run_repository.dart   interface
│   └── usecases/gana_usecases.dart    11 @lazySingleton use cases
│
├── features/shiv/gana/
│   ├── engine/                         MAIN ISOLATE (post-refactor)
│   │   ├── gana_engine.dart            @lazySingleton — scheduler + run loop +
│   │   │                               direct publish; delegates the run to
│   │   │                               ../../generation/gana_run.dart
│   │   ├── gana_input_filter.dart      per-type Isar queries + self-guards
│   │   ├── gana_prompt_builder.dart    SYSTEM rules + USER instruction +
│   │   │                               KNOWLEDGE + INPUT + NOOP sentinel
│   │   ├── gana_workmanager.dart       top-level OS-dispatched bg tick (also
│   │   │                               delegates to ../../generation/gana_run.dart)
│   │   └── gana_workmanager_bootstrap.dart  initialize + schedule/cancel bg
│   │   #  manas_context_loader.dart MOVED → ../../generation/context/
│   │   #  gana_run.dart (shared fg/bg run pipeline) → ../../generation/
│   │
│   │   DELETED 2026-06-20 (moved into main isolate as @lazySingleton):
│   │     gana_bootstrap.dart, gana_isolate.dart, gana_init_message.dart,
│   │     inference/gana_inference_server.dart,
│   │     inference/gana_inference_protocol.dart,
│   │     inference/gana_output_dispatcher.dart,
│   │     data/models/gana_pending_output_model.dart
│   │
│   ├── list/bloc/
│   │   ├── gana_list_bloc.dart        backs ShivHistoryDrawer Ganas section
│   │   ├── gana_list_event.dart
│   │   └── gana_list_state.dart
│   ├── form/
│   │   ├── bloc/                       gana_form_bloc/event/state
│   │   └── pages/gana_form_page.dart   create + edit
│   └── detail/pages/gana_detail_page.dart
│
├── gateway/cleanup/cleanup_manager.dart  + _pruneGanaRuns() phase (every 6h)
│
├── core/router/
│   ├── app_routes.dart                 shivGanaForm, shivGanaDetail constants
│   └── app_router.dart                 routes registered
│
├── features/shiv/chat/widgets/
│   └── shiv_history_drawer.dart        Ganas section added above Conversations
│
└── l10n/app_en.arb                     ganaForm*, ganaDrawer*, ganaTile*,
                                        ganaRun* keys (zero hardcoded English)

ios/Runner/Info.plist
  + UIBackgroundModes: fetch, processing
  + BGTaskSchedulerPermittedIdentifiers: in.uniun.app.gana.tick

android/app/src/main/AndroidManifest.xml
  + FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, WAKE_LOCK,
    RECEIVE_BOOT_COMPLETED, POST_NOTIFICATIONS permissions

pubspec.yaml
  + workmanager: ^0.6.0
  + flutter_gemma: ^1.0.0
  + flutter_gemma_litertlm / _mediapipe / _embeddings

test/integration/
  └── flutter_gemma_bg_isolate_test.dart   Phase 6a verification
                                           (move to integration_test/ to run)
```

---

## 12. Open follow-ups

| Item | Trigger to ship |
|---|---|
| **Background inference for DM/PC** | Currently bg tick skips kind 14 / 9023 (native plugins are main-isolate-only). Plumbing NIP-17 / MLS into the bg isolate would lift the limitation. |
| **Function-calling output** | Dropped from the prompt entirely (models leaked `publish_message(body=...)` as text; sanitizer rule + plain-text prompt instead). flutter_gemma 1.2.0 now exposes true tool-calling + a skill runtime — the revisit is designed in [`agent_skills.md`](agent_skills.md) (agentic Ganas, typed publish via `publish-*` skills, per-round scheduling). Note the historical text-leak is exactly the small-model reliability risk that doc's P1 gate must measure. |
| **Real `outputEventId` for DM + private channel** | Transport use cases (`SendDmUseCase`, `SendPrivateChannelMessageUsecase`) return `void` / `Unit`. Engine snapshots `noteModels` before/after the call to recover the new eventId — works but feels fragile. |
| **User-private config sync across devices** | Out of scope; would need encrypted Nostr-based sync layer |
| **"Run now" button** | Deferred; once we see how trigger model behaves in the wild |
