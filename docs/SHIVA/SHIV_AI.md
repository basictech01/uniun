# Shiv AI — System Design

Shiv is UNIUN's AI assistant. It reasons over the user's saved notes via vector + graph RAG, and runs against **two interchangeable backends** behind one repository:

- **Local** — `flutter_gemma 1.5.1` on-device inference (default, fully offline).
- **Cloud (UNIUN Cloud)** — UNIUN's own inference gateway (`api.uniun.in`), authenticated with the user's own Nostr keypair — no separate password/account. See `UniunRepository`/`UniunRepositoryImpl` below; this replaced an earlier direct-OpenRouter integration entirely (`openrouter_api` is no longer a dependency).

The user picks the backend in Settings. The chat code, RAG pipeline, knowledge extractor and BLoC have **no idea which backend is active** — they call the same `LlmRepository` interface.

Resources: <https://pub.dev/packages/flutter_gemma> · <https://pub.dev/documentation/flutter_gemma/latest/>

---

## Table of Contents

1. [Mental Model](#mental-model)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [File-by-File Map](#file-by-file-map)
4. [Call Flows](#call-flows)
5. [Backend Switching — Local ↔ Cloud](#backend-switching--local--cloud)
6. [Branching Chat](#branching-chat)
7. [RAG Pipeline](#rag-pipeline)
8. [Data Models](#data-models)
9. [Ganas — autonomous AI workers](#ganas--autonomous-ai-workers)
10. [Out of Scope](#out-of-scope)

> **Companion docs**:
> - `docs/SHIVA/Ganas.md` — Phase 2 AI agents (uses the same Shiv inference path via a SendPort bridge).
> - `docs/BRAHMA/Manas.md` — knowledge bases that Ganas consume.

---

## Mental Model

```
ShivChatPage (or any caller — extraction, summarisation, …)
        │
        ▼
ShivAIBloc / ExtractKnowledgeUseCase           ← Presentation / Domain
        │  calls *.call(input) — never an engine directly
        ▼
llm_usecases.dart                              ← Domain use cases
   SendChatStreamUseCase / GenerateOneShotUseCase / …
        │
        ▼
LlmRepository  (interface)                     ← Domain contract
        │
        ▼
LlmRepositoryImpl                              ← Data layer dispatcher
        │  reads LlmPreferencesDataSource.activeBackend, picks one of:
        ├──────────────────────────────────────────────┐
        ▼                                              ▼
LocalLlmDataSource                            RemoteLlmDataSource
        │                                              │
        ▼                                              ▼
AIModelRunner ▶ openChat(modelType…)         UniunRepository.streamChat()
        │  InferenceScheduler (5-tier — see              │
        │  docs/SHIVA/scheduling.md)                     ▼
        ▼                                     UniunRepositoryImpl
flutter_gemma 1.5.1 (LiteRT-LM / MediaPipe)        (the ONLY class that
                                                 imports UniunGatewayClient)
                                                        │
                                                        ▼
                                              UniunGatewayClient ──HTTP──►
                                                        api.uniun.in (UNIUN Cloud)
```

Three things to notice:

1. **One contract, two paths.** `LocalLlmDataSource` and `RemoteLlmDataSource` both implement `LlmDataSource`. The repository picks based on `LlmPreferencesDataSource.activeBackend`.
2. **The runner is internal.** `AIModelRunner` is no longer a service — it's an implementation detail of `LocalLlmDataSource`, sitting at `lib/data/datasources/llm/local_llm_runner.dart`. Phase 1 of the v2 refactor moved it out of `lib/features/shiv/services/` so the layer boundary is honest.
3. **`RemoteLlmDataSource` is a thin delegate, not a raw HTTP client.** All auth (silent Nostr-keypair login, key decryption, 401-refresh-and-retry), catalog filtering, and chat streaming live in `UniunRepositoryImpl` — `RemoteLlmDataSource` just forwards to `UniunRepository.streamChat`/`listAvailableModels`. `UniunGatewayClient` (the raw HTTP client) is never imported anywhere else in the app; `UniunRepository` also handles QR-login approval (`approveQrLogin`, scanning a browser's login QR from an already-signed-in phone) and the onboarding interest-picker roster (`getOnboardingInterests`) — both ride the same gateway, so they live on this same repository rather than a separate one.

---

## Clean Architecture Layers

Strict downward calls. Presentation never imports `flutter_gemma`. Data never imports widgets.

| Layer | Path | Contents |
|---|---|---|
| **Presentation** | `lib/features/shiv/` | `ShivAIBloc`, pages, widgets, model picker sheet |
| **Presentation** | `lib/features/settings/widgets/` | `CloudProviderCard` (API key paste + backend toggle) |
| **Domain — entities** | `lib/domain/entities/llm/` | `LlmBackendType`, `LlmModelInfo` |
| **Domain — repositories** | `lib/domain/repositories/` | `LlmRepository`, `UniunRepository` |
| **Domain — use cases** | `lib/domain/usecases/llm_usecases.dart` | 14 use cases grouped per SRP — chat, one-shot, lifecycle, backend, credentials |
| **Core primitives** | `lib/core/llm/` | `LlmCancellationToken` |
| **Data — repositories** | `lib/data/repositories/` | `LlmRepositoryImpl`, `UniunRepositoryImpl` |
| **Data — data sources** | `lib/data/datasources/llm/` | Both backends + runner + queue + prefs + credentials store |

---

## File-by-File Map

### Domain — entities

```
lib/domain/entities/llm/
├── llm_backend_type.dart    enum { localGemma, uniunCloud }
└── llm_model_info.dart      @freezed { id, displayName, backend, contextWindow, prices… }
```

### Domain — repositories (interfaces only)

```
lib/domain/repositories/
├── llm_repository.dart      session lifecycle + sendChat + generateOneShot
│                            + preempt/resume + backend & model selection
├── uniun_repository.dart    the ONLY interface for talking to UNIUN Cloud —
│                            connect/disconnect/isConnected/accountStatus/
│                            listAvailableModels/streamChat/approveQrLogin/
│                            getOnboardingInterests. No pasted API key —
│                            connect() silently signs in with the user's
│                            own Nostr keypair.
└── ai_model_repository.dart local model catalog + download + orphaned-file
                             cleanup (getOrphanedModelFilesSizeBytes/
                             cleanupOrphanedModelFiles) — manages files on
                             disk, not inference.
```

### Domain — use cases (grouped — `llm_usecases.dart`)

| Class | Wraps |
|---|---|
| `HasActiveLlmModelUseCase` | `LlmRepository.hasActiveModel()` |
| `OpenLlmConversationUseCase` | `openConversation(systemInstruction)` |
| `CloseLlmConversationUseCase` | `closeConversation()` |
| `SendChatStreamUseCase` | `sendChat(message, cleanHistory)` → `Stream<String>` |
| `GenerateOneShotUseCase` | `generateOneShot(prompt, maxTokens)` |
| `PreemptBackgroundWorkUseCase` | pauses low-priority lane (chat is incoming) |
| `ResumeBackgroundWorkUseCase` | resumes low-priority lane |
| `GetActiveLlmBackendUseCase` / `SetActiveLlmBackendUseCase` | local ↔ cloud switch |
| `ListAvailableLlmModelsUseCase` | local: downloaded models · cloud: UNIUN Cloud catalogue, filtered to what the account's plan/credit balance can use |
| `GetActiveLlmModelUseCase` / `SetActiveLlmModelUseCase` | which model is active on the active backend |
| `ConnectUniunCloudUseCase` / `DisconnectUniunCloudUseCase` / `IsUniunCloudConnectedUseCase` / `GetUniunCloudStatusUseCase` | UNIUN Cloud connection lifecycle — no key to paste, `connect()` signs in silently |

### Core primitives

```
lib/core/llm/
└── llm_cancellation_token.dart    Completer-backed cancel signal
```

### Data — repositories

```
lib/data/repositories/
├── llm_repository_impl.dart      dispatches per active backend
└── uniun_repository_impl.dart    the ONLY class that imports UniunGatewayClient —
                                  composes signing/decryption/secure-storage with
                                  catalog filtering + chat streaming + 401-retry
```

### Data — data sources (the heart of the engine routing)

```
lib/data/datasources/llm/
├── llm_data_source.dart             abstract — one impl per backend
│
├── local_llm_data_source.dart       wraps AIModelRunner + InferenceScheduler
│                                    listAvailableModels → local catalog (downloaded only)
│
├── local_llm_runner.dart            opens InferenceChat via flutter_gemma 1.5.1
│                                    passes modelType + isThinking per active model
│                                    holds _activeExtraction → safe preemption
│
├── inference_scheduler.dart         5-tier scheduler — chat / foreground /
│                                    extract / deadline / fair-pool. CFS-style
│                                    vruntime + EDF deadlines + model affinity.
│                                    See docs/SHIVA/scheduling.md.
├── embedding_queue.dart             one-at-a-time gate with priorities for the embedder (see embedding.md)
│                                    lane (separate model, never blocks LLM).
│
├── local_model_params.dart          AIModelId → (ModelType, isThinking) lookup
│                                    keeps chat template aligned to the model file
│
├── remote_llm_data_source.dart      thin delegate to UniunRepository.streamChat/
│                                    listAvailableModels — no HTTP/auth logic of
│                                    its own; preempts active extraction on chat send
│
├── llm_credentials_data_source.dart flutter_secure_storage for the UNIUN Cloud
│                                    `uk_` key (same Keystore/Keychain pattern as
│                                    nsec) — read/written only by UniunRepositoryImpl
│
└── llm_preferences_data_source.dart SharedPreferences: activeBackend + activeCloudModelId
```

### Presentation — Shiv feature

```
lib/features/shiv/
├── pages/shiv_page.dart                       tab root: model check → landing / chat
├── chat/
│   ├── bloc/shiv_ai_bloc.dart                 events, state, streaming, branching
│   ├── pages/shiv_chat_page.dart              message list + composer
│   ├── widgets/
│   │   ├── shiv_message_bubble.dart           user/assistant bubbles, <think> parsing
│   │   ├── shiv_input_composer.dart           [+ model picker] + text field + send/stop
│   │   ├── shiv_history_drawer.dart           conversation list side drawer
│   │   ├── shiv_conversation_tile.dart        swipe-to-delete tile
│   │   └── shiv_model_picker_sheet.dart       + button → bottom-sheet model picker
│   └── tree/                                  branch graph view (long-press fork)
├── model_select/                              SelectAIModelCubit + AIModelSelectionPage
│                                              (local file catalog — Phase 1 unchanged)
└── rag/
    ├── embedding/embedding_service.dart       all-MiniLM-L6-v2 (tflite_flutter)
    ├── retrieval/vector_search_service.dart   cosine sim over ToStore vectors
    ├── prompt/prompt_builder.dart             system prompt + extraction prompt
    ├── prompt/prompt_budget.dart              per-model token budgets
    └── pipeline/rag_pipeline.dart             init + buildMessage (two-phase)
```

### Presentation — Settings

```
lib/features/settings/
├── pages/settings_page.dart                Account · Identity · AI · Cloud AI · Storage · …
└── widgets/
    ├── ai_card.dart                        opens local model picker (AIModelSelectionPage)
    └── cloud_provider_card.dart            connect/disconnect UNIUN Cloud (silent
                                             keypair sign-in, no pasted key), switch backend
```

---

## Call Flows

### Chat send — happy path

```
User taps send in ShivChatPage
   │
   ▼
ShivAIBloc._onSendMessage
   │  saves user msg + placeholder asst msg to Isar
   │
   ▼
RagPipeline.buildMessage(userQuestion)                  ← see "RAG per turn" below
   │  • picks PromptBudget.forActiveModel(getActiveLlmModel)
   │  • embed query → vector search → graph expand → memory lookup
   │  • PromptBuilder.buildUserMessage(enriched, budget) → final prompt string
   │
   ▼  RagMessage { userMessage, contextCount }
_sendChatStream.call(SendChatStreamInput(message: userMessage, cleanHistory))
   │
   ▼
SendChatStreamUseCase  →  LlmRepository.sendChat
   │
   ▼
LlmRepositoryImpl._active  ← reads prefs.activeBackend
   │
   ├─ localGemma  ─►  LocalLlmDataSource.sendChat
   │                     │
   │                     ▼  AIModelRunner.sendAndStream
   │                     │     • _activeExtraction?.stopGeneration()   safe per-session preempt
   │                     │     • InferenceScheduler.run(kind: LlmTaskKind.chat, …)  ← T0, always preempts
   │                     │     • model.openChat(modelType, isThinking) ← from LocalModelParams
   │                     │     • chat.addQueryChunk(Message.text(prompt))
   │                     │     • generateChatResponseAsync() → yields TextResponse tokens
   │                     ▼  Stream<String>
   │
   └─ uniunCloud  ─►  RemoteLlmDataSource.sendChat
                         │
                         │  cancel every in-flight generateOneShot call
                         │  (each tracked independently — see below)
                         │  UniunRepository.streamChat(modelId, messages)
                         │     → UniunRepositoryImpl resolves/refreshes the uk_ key,
                         │       calls UniunGatewayClient.streamChatCompletion (SSE),
                         │       retries once on a stale-key 401
                         ▼  Stream<String>
```

The stream returns to `_onTokenReceived` (strips leading whitespace, appends to `streamingContent`). `_onStreamDone` persists the final asst message and strips any `<think>…</think>` blocks.

### RAG per turn — what happens inside `RagPipeline.buildMessage`

```
userQuestion: "what did i write about the saga pattern?"
       │
       ▼
[1] EmbeddingService.embed(query)
       │  all-MiniLM-L6-v2 (tflite_flutter, on-device, ~80 MB)
       ▼  List<double> queryVec (384 dims)
       │
[2] PromptBudget.forActiveModel(LlmModelInfo)
       │  Qwen3 0.6B  → max=2048,  topK=3,  hops=1
       │  Gemma 4 E4B → max=8192,  topK=10, hops=2
       │  Cloud       → max=16384, topK=15, hops=2
       ▼  PromptBudget { maxTokens, topK, maxHops, section caps }
       │
[3] VectorSearchService.search(queryVec, topK=budget.topK)
       │  ToStore ANN cosine over saved-note embeddings
       ▼  List<ScoredNote>  seedNotes
       │
[4] GetMemoriesByNoteIdsUseCase(seedNoteIds)
       │  pulls MemoryNodeModel rows the extractor built earlier
       ▼  seedMemories + concept keys
       │
[5] GetGraphNeighboursUseCase(conceptKeys, maxHops=budget.maxHops)
       │  BFS over GraphEdgeModel from seed concepts
       ▼  edges (each = source → relation → target)
       │
[6] GetGraphNodesByKeysUseCase(edge endpoints)
       │  resolves keys to readable node names
       ▼  graphNodes
       │
[7] GetMemoriesByNoteIdsUseCase(notes that asserted those edges)
       │  expandedMemories from beyond the seeds
       ▼  EnrichedContext { seedNotes, graphNodes, graphEdges, memories }
       │
[8] PromptBuilder.buildUserMessage(enriched, budget)
       │  Lays out as: "Question: <q>" → context sections → "## Question\n<q>"
       │  (question repeated at both ends — Lost-in-the-Middle countermeasure
       │  from Liu et al. 2023; small models attend strongest to start + end).
       │
       │  Priority order — drops lowest first if over budget:
       │    query (10%)  →  top 1-2 seed notes (35%)
       │                 →  graph relations (20%)
       │                 →  remaining seed notes
       │                 →  memory summaries (15%)
       ▼  String userMessage
       │
   RagMessage { userMessage, contextCount = #notes + #edges + #memories }
```

The exact same `RagMessage` is sent to whichever LLM is active — local Gemma or UNIUN Cloud. RAG is backend-agnostic. The embedding always runs on-device, so even cloud chat doesn't leak the note bodies it didn't pull into context.

Pipeline source: `lib/features/shiv/rag/pipeline/rag_pipeline.dart` — `buildMessage` (per turn) + `buildSystemInstruction` (once at conversation open).

### Knowledge extraction — background graph build

```
VishnuFeedBloc / ThreadConversationBody save action
   │
   ▼
SaveNoteUseCase + (fire-and-forget) EmbedAndStoreNoteUseCase
   │
   ▼
EmbedAndStoreNoteUseCase  ─►  ExtractKnowledgeUseCase
   │
   │  hasModel = await HasActiveLlmModelUseCase.call()
   │  searchVectors → similar notes for context
   │  builds extraction prompt (directional, JSON schema)
   ▼
GenerateOneShotUseCase  →  LlmRepository.generateOneShot
   │
   ├─ local  ─►  AIModelRunner.generateOneShot
   │                InferenceScheduler.run(kind: LlmTaskKind.extract, …)  ← T2, yields to chat
   │                model.openChat(temp=0.2)
   │                _activeExtraction = oneShot  ← held so chat can stopGeneration()
   │                → buffer concatenated tokens → String?
   │
   └─ cloud  ─►  RemoteLlmDataSource.generateOneShot
                    UniunRepository.streamChat → buffer → String?
                    tracked as its own entry in _extractions (a Set, not a
                    single field) — concurrent calls never cancel each
                    other; only sendChat/preemptBackgroundWork cancel all
                    of them, and cancelling now resolves the call as
                    Right(null) instead of leaving it hanging forever

Parsed JSON → graph nodes + edges + memory upserted in Isar.
```

If chat preempts during local extraction: `stopGeneration()` cancels the extraction session (`openChat` gives independent native sessions). Extraction returns `null`. The pending row in `PendingExtractionRepository` survives, and `DrainPendingExtractionsUseCase` retries it when the user leaves the Shiv tab.

On cloud, a preempted `generateOneShot` also resolves `Right(null)` (same "no result yet, will retry" meaning) — but a *genuine* stream failure (network error, rate limit, invalid model) now surfaces as `Left(Failure)` instead, so `GanaEngine`'s existing `failed`-vs-`skipped` branching gets the real signal instead of both reading as null.

### Enter / leave Shiv tab

```
HomePage tab index → 2
   ▼
ShivAIBloc.onEnterShivTab()
   ▼
PreemptBackgroundWorkUseCase  →  LlmRepository.preemptBackgroundWork
   │
   ├─ local: SchedulerCoordinator.setForeground(LlmTaskKind.chat)
   │         (T0 chat preempts; lower tiers freeze until the user leaves)
   └─ cloud: cancels every in-flight generateOneShot entry in _extractions
```

Leaving the tab does the inverse plus `DrainPendingExtractionsUseCase.call()` to replay any preempted extractions.

### Connect UNIUN Cloud — no key to paste

```
SettingsPage → CloudProviderCard → "Connect"
   ▼
ConnectUniunCloudUseCase  →  UniunRepositoryImpl.connect()
   │  challenge → sign with the user's own Nostr privkey → login
   │  decrypts (or mints, if this account has zero active keys) a `uk_` gateway key
   │  stores it in flutter_secure_storage
   ▼
   ├─ ok   → card flips to Connected, ListAvailableLlmModelsUseCase loads the catalog
   └─ fail → snackbar (e.g. no network) — nothing persisted
```

QR-login (approving a browser sign-in from an already-connected phone) is the same underlying identity, via `UniunRepository.approveQrLogin(sessionId)` — see `lib/common/qr/uniun_qr_scanner_page.dart`.

### Switch backend

```
CloudProviderCard toggle (or model picker sheet)
   ▼
SetActiveLlmBackendUseCase  →  LlmRepository.setActiveBackend(uniunCloud)
   │  calls UniunRepository.connect() first if not already connected
   ▼
LlmPreferencesDataSource.setActiveBackend
   │  (next call to LlmRepositoryImpl._active resolves to RemoteLlmDataSource)
```

### Pick a model (chat input `+`)

```
ShivInputComposer + icon → ShivModelPickerSheet
   ▼
ListAvailableLlmModelsUseCase   (local: downloaded · cloud: UNIUN Cloud catalogue,
                                 filtered to what the account's plan/credit covers)
   │
   ▼ user taps a row
SetActiveLlmModelUseCase  →  LlmRepository.setActiveModel(id)
   │  local  → AppSettingsStore.setActiveModelId(AIModelId.values.byName(id))
   │           then AIModelRepository.activateModel(id) — re-links
   │           flutter_gemma's native engine to the new model through
   │           InferenceScheduler (modelSwitch, tier -1, gentle — waits
   │           for whatever's running to finish, then applies ahead of
   │           anything else queued; see scheduling.md §3 "Model switch
   │           tier"). A plain settings write alone would leave the
   │           native engine pointed at the previous model even though
   │           hasActiveModel() still reads true.
   └─ cloud → LlmPreferencesDataSource.setActiveCloudModelId(id)
```

Deleting the currently-active local model (Settings → Storage) goes through the same `AIModelRunner.runExclusiveModelOperation`, but forced (`forcePreempt: true`) — the file is being removed, so it can't wait for the current job to finish naturally.

Model picker rows show `displayName` only — the raw catalog `id` (the gateway's internal routing string) is never rendered to the user.

---

## Backend Switching — Local ↔ Cloud

| Concern | Local Gemma | UNIUN Cloud |
|---|---|---|
| Trigger | Default; user has a model downloaded | User taps Connect — silent Nostr-keypair sign-in, no password/key paste |
| Inference path | flutter_gemma `openChat` → `addQueryChunk` → `generateChatResponseAsync` | `UniunGatewayClient.streamChatCompletion` — OpenAI-compatible SSE |
| Session model | Per-turn `openChat` with `modelType` from `LocalModelParams` | Stateless — full prompt every call |
| Cancellation | per-session `stopGeneration()` | cancel the underlying stream subscription |
| Concurrency | accelerator-mutexed → `InferenceScheduler` (5 tiers, CFS fair pool, EDF deadline, model affinity — see [`scheduling.md`](scheduling.md)) | network-concurrent — every call tracked independently in `_extractions`, no queue |
| Preemption of extraction | `_activeExtraction.stopGeneration()` driven by the scheduler when a higher-tier job arrives | `sendChat`/`preemptBackgroundWork` cancel all entries in `_extractions`; each resolves `Right(null)` |
| Models exposed | downloaded local files (via `AIModelRepository`) | UNIUN Cloud catalog, filtered by plan/credit balance |
| Credentials | none | `flutter_secure_storage` (Android Keystore / iOS Keychain) holds the gateway-minted `uk_` key — never a user-supplied API key |

### Chat template safety (a v2 fix worth highlighting)

`openChat()` defaults `modelType` to `gemmaIt`. If we don't override it, the SDK renders a Gemma 2/3 template even when the loaded file is Qwen3 or Gemma 4 → garbled prompts, leading `\n` tokens, hallucinations.

`LocalModelParams.forId()` is the **single source of truth** for the runtime mapping:

```
qwen25_05b   →  ModelType.qwen3   isThinking=false   (we use Qwen3 0.6B today)
deepseekR1   →  ModelType.deepSeek isThinking=true
gemma4E2b    →  ModelType.gemma4   isThinking=false
gemma4E4b    →  ModelType.gemma4   isThinking=false
```

The same mapping exists in `AIModelRepositoryImpl._gemmaParams` for the *install* path. Both must stay in sync — runtime template and install spec must agree.

### Logging in release (privacy)

`flutter_gemma` gates every internal log on `kDebugMode`. Release builds are silent regardless of level — no prompt, output, or conversation history can reach `logcat` / `syslog` even if a user (or attacker) tries to enable verbose mode.

`lib/main.dart` still sets the level explicitly so the *intent* is on the page:

```dart
FlutterGemma.logLevel =
    kReleaseMode ? GemmaLogLevel.none : GemmaLogLevel.info;
```

Use `GemmaLogLevel.verbose` only when actively debugging a model bug locally — it prints prompts and generated tokens.

### KV-cache hygiene

Before 0.16.5, opening a new chat after closing one could see residual KV-cache state from the previous native session (issue #308). Fixed upstream: each `createSession` now opens a fresh native session + conversation handle. We get this for free with the version bump — no code change needed.

---

## Branching Chat

The chat looks linear by default. Long-press a message → "Continue from here" forks a branch. The branch tree is **derived at render time** from `ShivMessageModel.parentId` — no separate branch table.

### Four fields that drive everything

| Field | Where | Meaning |
|---|---|---|
| `conversationId` | `ShivConversationModel` + every msg | groups everything under one conversation |
| `parentId` | `ShivMessageModel` | predecessor message — `null` for root |
| `activeLeafMessageId` | `ShivConversationModel` | which path the user is currently viewing |
| `messageId` | `ShivMessageModel` | unique per message |

### Loading the active path

Walk `parentId` backwards from `activeLeafMessageId` to root, reverse, render. The shared root messages naturally appear in every branch — no duplication on disk.

```dart
final byId = {for (final m in all) m.messageId: m};
final path = <ShivMessageEntity>[];
String? cur = activeLeafMessageId;
while (cur != null) { path.insert(0, byId[cur]!); cur = byId[cur]!.parentId; }
```

### Branch view modes

- **Vertical Tree Explorer** — `lib/features/shiv/chat/tree/pages/shiv_branch_tree_page.dart`
- **Node action panel** — `lib/features/shiv/chat/tree/widgets/node_action_panel.dart` (Open / Continue From Here / New Branch)
- **Branch graph** — `lib/features/shiv/chat/tree/widgets/branch_tree_graph.dart`

---

## RAG Pipeline

Two-phase to match `InferenceChat`'s lifecycle:

**Phase 1 — session open (once per conversation):**
```dart
await rag.init();                                  // load embedding model
final sysInstruction = await rag.buildSystemInstruction();   // persona + name + bio
await openConv.call(OpenLlmConversationInput(systemInstruction: sys));
```

**Phase 2 — each user turn:**
See the [RAG per turn](#rag-per-turn--what-happens-inside-ragpipelinebuildmessage) flow above for the step-by-step inside `buildMessage`. Output is a single `RagMessage { userMessage, contextCount }` that gets passed verbatim to `SendChatStreamUseCase`.

### Per-model RAG scaling

`PromptBudget.forActiveModel(LlmModelInfo)` resolves the budget each turn — RAG automatically grows or shrinks to match the active engine's context window. Caller does nothing special.

| Active model | RAG budget | topK seed notes | graph hops | Engine `maxTokens` |
|---|---:|---:|---:|---:|
| Qwen3 0.6B (default small) | 2,048 | 3 | 1 | 2,048 |
| DeepSeek R1 1.5B | 1,024 | 3 | 1 | 1,280 |
| Gemma 4 E2B | 4,096 | 5 | 2 | 4,096 |
| Gemma 4 E4B | 8,192 | 10 | 2 | 8,192 |
| **Cloud (UNIUN Cloud)** | **16,384** | **15** | **2** | — |
| no active model | 2,048 | 3 | 1 | — |

Engine `maxTokens` is the hard KV-cache size baked into the local model file (e.g. `deepseek_q8_ekv1280.task` = 1,280-token cache; opening larger aborts at `CalculatorGraph::Run`). RAG budget for DeepSeek therefore reserves ~256 tokens for the generated response.

Cloud's 16k cap is intentional — most cloud models expose 32k–1M context but pulling too much makes answers noisier *and* costs more. The gateway's `LlmModelInfo.contextWindow` isn't populated per-model yet; when it is, `_cloud()` will read it and adapt per-model.

Section split inside any budget: query 10%, top notes 35%, graph relations 20%, summaries 15%. Trimming order (drops lowest first): summaries → extra seed notes → graph relations.

### Chat history budget (separate from RAG budget)

RAG sections compete inside `PromptBudget`; chat history is budgeted **separately** inside `LocalLlmRunner` so old turns can't eat into the RAG context. On every call to `sendAndStream`:

```dart
historyBudgetTokens = (LocalModelParams.maxTokens × 0.20).round()
```

| Active model | History budget |
|---|---:|
| Qwen3 0.6B | ~410 |
| DeepSeek R1 1.5B | ~256 |
| Gemma 4 E2B | ~820 |
| Gemma 4 E4B | ~1,640 |

`_trimHistory` walks `cleanHistory` newest-first and keeps as many `(user, assistant)` pairs as fit, restoring chronological order before composing the prompt. Older turns are silently dropped — the LLM never sees them. The current question is always preserved (it's a separate `currentMessage` arg, not part of the history budget). Why 20%: leaves 80% for system instruction + RAG sections + response — empirically the sweet spot for keeping multi-turn coherence on small models without starving retrieval.

Source: `lib/data/datasources/llm/local_llm_runner.dart` — `_historyBudgetTokens`, `_trimHistory`, `_composePrompt`.


### Embedding stays local even on cloud backend

`all-MiniLM-L6-v2` (~80 MB, bundled `.tflite`) runs in `EmbeddingService` regardless of which LLM is active. The embedding is independent of the answer generator — local notes, local vectors, then *either* on-device or cloud LLM consumes the assembled prompt. No private data ever leaves the device unless the user explicitly chose the cloud backend.

### Extraction prompt (directional rule landed v2)

`prompt_builder.dart:buildExtractionPrompt` now enforces "<source> <type> <target>" reads as a sentence, with a worked example that prevents the inverted-edge bug ("rajendrasinh is_son_of samarth" wrong; "samarth child_of rajendrasinh" right).

---

## Data Models

> Authoritative definitions live in `lib/data/models/`. Below is the schema shape only.

```dart
// lib/data/models/shiv_conversation_model.dart
class ShivConversationModel {
  Id id = Isar.autoIncrement;
  late String conversationId;
  late String title;                  // first user msg truncated to 40 chars
  late String activeLeafMessageId;    // walks parentId chain to render branch
  late DateTime createdAt;
  late DateTime updatedAt;
}

// lib/data/models/shiv_message_model.dart
class ShivMessageModel {
  Id id = Isar.autoIncrement;
  late String messageId;
  late String conversationId;
  String? parentId;                   // null = root
  @Enumerated(EnumType.name) late MessageRole role;   // user | assistant
  late String content;
  late DateTime createdAt;
}

// lib/data/models/ai_model_selection_model.dart
class AIModelSelectionModel {
  Id id = Isar.autoIncrement;
  @Enumerated(EnumType.name) late AIModelId modelId;
  late String modelName;
  late String modelPath;              // modelId.name — flutter_gemma owns the file
  late DateTime downloadedAt;
}

// lib/data/models/memory_node_model.dart    (GraphRAG wiki summary per note)
// lib/data/models/graph_node_model.dart     (extracted concept)
// lib/data/models/graph_edge_model.dart     (extracted relation, subject → verb → object)
```

The active backend (`localGemma` / `uniunCloud`) and the active cloud model id live in `SharedPreferences` (via `LlmPreferencesDataSource`), not in Isar.

API keys live **only** in `flutter_secure_storage` (via `LlmCredentialsDataSource`), never in Isar or SharedPreferences.

### Local model catalog

All four files come from the `litert-community` org on HuggingFace — the same source flutter_gemma's own README recommends. No HuggingFace token required.

| AIModelId | Display | Size | Format | ModelType | isThinking |
|---|---|---|---|---|---|
| `qwen25_05b` | Qwen3 0.6B | 586 MB | `.litertlm` | `qwen3` | false |
| `deepseekR1` | DeepSeek R1 1.5B ⭐ | 1.7 GB | `.task` | `deepSeek` | true |
| `gemma4E2b` | Gemma 4 E2B | 2.4 GB | `.litertlm` | `gemma4` | false |
| `gemma4E4b` | Gemma 4 E4B | 4.3 GB | `.litertlm` | `gemma4` | false |

> The `AIModelId` enum value `qwen25_05b` is legacy — kept to avoid an enum-rename migration in users' SharedPreferences. The actual file and label are Qwen3 0.6B.

---

## Ganas — autonomous AI workers

Ganas are user-defined AI agents that share the **same inference path** as Shiv chat but run **autonomously** in a background isolate. The full design lives in `docs/SHIVA/Ganas.md`; this section is the integration summary for Shiv readers.

### Integration in three diagrams

**1. Sharing the model — no second load.**
flutter_gemma's `model.openChat()` lets one loaded model serve multiple independent sessions. Chat opens its session per turn; Gana opens its session per run. Both flow through the same `InferenceScheduler` — chat submits as `LlmTaskKind.chat` (T0, always preempts), Gana submits as `LlmTaskKind.gana` (T4 fair pool, CFS-style `vruntime` shared with Nataraj). Full tier detail: `docs/SHIVA/scheduling.md`.

```
                  AIModelRunner (existing)
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
       chat.openChat            Gana.openChat
       (per turn, T0 chat)      (per run, T4 fair pool)
              │                     │
              └─────────┬───────────┘
                        ▼
              ONE loaded flutter_gemma model
              (main isolate, native thread)
```

**2. Cross-isolate bridge.**
The Gana engine isolate sends a serializable `GanaInferenceRequest` over a `SendPort`. The main-isolate `GanaInferenceServer` receives it, delegates to `AIModelRunner.generateOneShot`, and replies on the request's `replyPort`. No locks, no shared memory — just message passing.

```
Engine isolate                 Main isolate
              ┌─── SendPort ──►┐
              │ GanaInference  │
              │ Request{       │
              │  prompt,       │
              │  replyPort,    │
              │  expectedModelId}
              │                │
              │                ├─► GanaInferenceServer
              │                │     ─► AIModelRunner.generateOneShot
              │                │         ─► InferenceScheduler (kind=gana)
              │                │             ─► flutter_gemma (native thread)
              │                ▼
              │   GanaInference
              │   Response{
              │    kind: ok|skipped*|failed,
              │    body, error}
              ◄── replyPort ───┘
```

**3. Publish path — never engine-side.**
DM (NIP-17 gift wrap) and private channel (NIP-29 / MLS) publishing touches native plugins that aren't safe to invoke from a background isolate. So the engine writes a `GanaPendingOutputModel` row and stops. The main-isolate `GanaOutputDispatcher` watches that table and calls the existing publish use cases.

```
Engine isolate                          Main isolate
─────────────                            ────────────
write GanaPendingOutputModel{
  body, ganaId, runId, outputType, ref}
                                       ─► GanaOutputDispatcher
                                             ─► PublishNoteUseCase /
                                                CreateChannelMessageUseCase /
                                                SendPrivateChannelMessageUsecase /
                                                SendDmUseCase
                                             ─► stamps outputEventId back on
                                                the matching GanaRun row
                                             ─► deletes the pending row
```

### What this means for Shiv

- **No new inference code.** Ganas reuse `AIModelRunner.generateOneShot` verbatim. If you change Shiv's inference behaviour, Gana behaviour changes the same way.
- **Chat always wins.** The scheduler's T0 chat tier preempts whatever Gana (or Nataraj, or extract) is mid-flight — `InferenceChat.stopGeneration()` at the next token boundary. Fair-pool jobs are re-queued; chat starts in <500 ms. Full tier rules in [`scheduling.md`](scheduling.md).
- **Same model state.** `FlutterGemma.hasActiveModel()` is process-wide — the server reads it directly, gates Gana runs on it. `SelectAIModelCubit` swapping models is observable to the server (it reads `AppSettingsStore.activeModelId` per request).

See `docs/SHIVA/Ganas.md` §7 for the UI-blocking analysis ("does the bridge slow the UI?" — no, with caveats).

---

## Out of Scope

| Feature | Status | Why |
|---|---|---|
| Direct provider keys (Anthropic, OpenAI native) | Not applicable | UNIUN Cloud is the only remote backend — model choice is a gateway-side catalog decision, not a per-provider key the app manages. |
| Image / vision input on cloud | Future | Depends on the gateway's model catalog exposing vision-capable models; UI not wired either way. |
| Function calling / tool use | Future | Gemma 4 + Qwen3 support it locally; not yet wired end-to-end. |
| Cost / usage display in chat | Future | `UniunRepository.accountStatus()` already exposes plan + credit balance; not yet surfaced inline in the chat UI. |
| Persistent on-device chat sessions | Future | Today we open a fresh `openChat` per turn for clean history. Long-lived sessions would save the per-turn prefill cost (84s on slow devices) but complicate branch switching. Phase 2 of v2 enabled it structurally; not yet enabled in code. |
| Hybrid keyword + vector search (BM25) | Future | Vector only today via ToStore. |
| Re-ranking with cross-encoder | Future | Top-K cosine only today. |
| Chunking of large notes | Future | One note = one embedding today. |
| NIP-09 deletion of conversations | Never | Same Feed-Freedom principle as notes. |
