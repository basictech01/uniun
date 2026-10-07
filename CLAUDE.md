# CLAUDE.md

Behavioral guardrails for working in this repo. Keep code surgical and explicit.

- **Think before coding.** State assumptions, surface tradeoffs, ask when unclear instead of guessing silently.
- **Simplicity first.** Minimum code that solves the problem. No speculative abstractions, no error handling for impossible cases.
- **Surgical changes.** Touch only what the user asked for; remove only orphans your own edits created.
- **Goal-driven.** Define a verifiable success criterion before you write code; loop until it's met.

---

# UNIUN — AI Context & Rules

This file is the single source of truth for any AI assistant working on this codebase. Read it completely before touching any file.

---

## What Is UNIUN?

UNIUN is a **decentralized, offline-first social and knowledge network** built entirely on the Nostr protocol, implemented as a Flutter mobile application. Users create, share, and connect **Notes** — Nostr Kind 1 events — that form both a social feed and a personal knowledge graph. Data is stored locally in an Isar database on the device and synced to the Nostr relay via WebSocket, managed by the Gateway sync isolate (lib/gateway/).

The app combines four systems into one: a social feed (Vishnu), a note creation workspace (Brahma), an AI assistant that reasons over the user's saved notes using on-device LLM inference (Shiv), and a public/private messaging layer (Channels + DMs). On-device AI runs via `flutter_gemma ^1.5.1` (user-selected model: Qwen3 0.6B / DeepSeek R1 / Gemma 4 E2B / Gemma 4 E4B) with no cloud API calls by default (an opt-in UNIUN Cloud backend exists — see `docs/SHIVA/SHIV_AI.md`). The knowledge graph is not a separate construction — it emerges naturally from the Nostr event graph: every `e` tag is a graph edge, every `t` tag is a topic node, every reply thread is a directed conversation subgraph.

**The relay (`uniun-backend/`)** is a Go service built on Khatru (github.com/fiatjaf/khatru). It stores events in BadgerDB (primary) with optional MySQL mirror. Media blobs (Blossom protocol) are stored on Azure Blob Storage. The Flutter app's Gateway sync isolate connects to this relay via WebSocket.

---

## Core Philosophy (NEVER Violate These)

- **Feed Freedom**: Notes are permanent. There is NO delete, NO soft-delete, NO NIP-09 implementation, NO `deleted` field, NO `isDeleted` field anywhere in any model, entity, or repository. Once published to Nostr, a note exists. The app does not pretend otherwise. This is an intentional design decision, not an oversight.

- **Offline-First**: The app works fully without internet. Isar is the source of truth. The UI reads only from Isar, never directly from a relay. The Gateway syncs with relays when connectivity is available and writes results back to Isar.

- **No Backend**: Zero custom servers. No REST API. No GraphQL. No Firebase. Only Nostr relays (WebSocket protocol, NIP-01) and Blossom media servers (content-addressed HTTP blob store for images).

- **One Event Type for Notes**: Everything the user creates is a Nostr Kind 1 event — a "Note". There are no separate Post, Comment, Thread, or Reply models. Note roles (feed post vs reply vs reference) are **derived** from the presence or absence of `rootEventId` and `replyToEventId` fields. Never add a new model type that maps to a Reddit-style concept.

---

## Architecture

```
Flutter UI (Presentation Layer — BLoC)
    ↓ calls use cases
Domain Layer (entities, repository interfaces, use cases)
    ↓ implemented by
Data Layer (Isar models, repository implementations)
    ↑ written to by
Gateway sync isolate (lib/gateway/ — RelayConnector + inbound handlers + EventQueue + CleanupManager)
    ↔ WebSocket
Nostr Relay Network
```

**Key components:**
- **Flutter + BLoC**: State management via `flutter_bloc`. Events flow into BLoC, new States flow out to UI via `BlocBuilder`/`BlocListener`.
- **Clean Architecture**: Three strict layers — Data, Domain, Presentation — with unidirectional dependency flow (Presentation → Domain ← Data).
- **Gateway / sync isolate** (`lib/gateway/`): Owned by this codebase and editable. Runs in a Dart isolate. Manages relay WebSocket connections, incoming event processing (inbound handlers persist events to Isar), the outgoing event queue, and retention cleanup.
- **Isar**: On-device NoSQL database. Object-based (no SQL). Used exclusively in the Data layer.
- **flutter_gemma**: On-device LLM runner for Shiv (AI assistant). Uses Google Gemma 2B or 7B via MediaPipe LLM Inference API. GPU-accelerated on Android (GPU delegate) and iOS (Metal).

### Layer Rules

**Data layer** (`lib/data/`):
- Contains Isar collection models (`@Collection`) and repository implementations.
- Models are **mutable** — no `@freezed` on Isar models (Isar requires mutable fields).
- May import `package:isar_community/isar.dart`.
- Must NOT import Flutter widget packages.
- Repository implementations are annotated `@Injectable(as: InterfaceName)`.
- All writes to Isar must be wrapped in `isar.writeTxn(() async { ... })`.

**Domain layer** (`lib/domain/`):
- Contains freezed entities, abstract repository interfaces, use cases, and input parameter classes.
- Has **zero** imports from `isar_community`, `flutter`, or any presentation package.
- Entities use `@freezed abstract class` pattern (Freezed 3.x requirement — not `class`).
- Repository interfaces define the contract; implementations live in `lib/data/repositories/`.
- Use cases extend `UseCase<ReturnType, InputType>` or `NoParamsUseCase<ReturnType>` from `lib/core/usecases/usecase.dart`.
- Results are always wrapped in `Either<Failure, T>` from the `dartz` package.

**Presentation layer** (`lib/presentation/` or feature folders like `lib/search/`, `lib/community/`):
- Contains BLoC classes, pages, and widgets.
- NO direct Isar access. All data flows through use cases → repositories.
- BLoC receives Events, calls use cases, emits States.
- Use `bloc_concurrency` for event transformers (e.g. `droppable()`, `sequential()`).

### Key Technical Decisions

- **Unread tracking is unified, not per-surface.** A single `UnreadNoteModel` collection holds one row per unread message across every surface (feed/group/DM/private group), discriminated by `kind`; presence = unread, deletion = read. There is no separate `ChannelReadStateModel`/`DMReadStateModel`/`FeedReadStateModel`.
- **Notes are queued for embedding, not embedded in place.** `EmbedAndStoreNoteUseCase` writes a `PendingEmbedding` row (`PendingEmbeddingRepository`, returns `Either`) and calls `NoteEmbeddingTrigger.nudge()`; `NoteEmbeddingWorker` (`lib/features/shiv/rag/indexing/`) embeds one note at a time, newest first, stores the vector, then deletes the row **last**, so a kill or a not-ready embedder loses nothing and an empty table means no work. Every embed (note, PDF/DOCX chunk, Shiv question) goes through `EmbeddingQueue`, one at a time, a question first; the worker waits while a chat reply is generating. Embedding costs ~11.5 s a note on a weak phone whatever the text length, and batching (`generateEmbeddings`) is no faster, so never assume it is cheap and never call the model directly. Not built yet: backfill of notes embedded before the queue, #232. See [`docs/SHIVA/embedding.md`](docs/SHIVA/embedding.md).
- **Image input in Shiv chat is for vision models only.** `AIModelId.supportsImages` (Gemma 4 E2B/E4B; Qwen3 and DeepSeek R1 are text-only, cloud models report false) gates the attach button via `ChatImageSupportCubit`. An image turn must use `createChat(supportImage: true)`: a `.litertlm` engine rejects images on the concurrent `openChat` sessions. flutter_gemma rebuilds a cached text-only engine itself when `supportImage` changes — do not close it by hand.
- **On-device LLM via `flutter_gemma`.** Single backend, no Strategy pattern. `FlutterGemma.installModel().fromNetwork().withProgress().withCancelToken().install()` for downloads; `InferenceChat` manages history — never rebuild it in our prompt. System instruction is prepended to the first user turn (Qwen ignores `systemInstruction` in `createChat()`).
- **Same scroll model for feed and chat.** Chronological only in v1. Pagination via `createdLessThan(before)`. No separate ranking.
- **GraphRAG = the Nostr event graph.** Every `e` tag is a note→note edge (`eTagRefs`), every `t` tag a note→topic edge (`tTags`), every reply a directed subgraph. No LLM entity extraction — these are user-asserted edges. v1 retrieval: vector-seed → 1-hop BFS expand. See `docs/graphrag.md`.
- **Share / quote = embed-by-value via the `embeddedNoteJson` tag.** Sharing a note into any destination (feed / channel / DM / private channel) publishes a new event in the target surface carrying a self-contained JSON snapshot of the **original event** `{id, pubkey, created_at, kind, tags, content, sig}` in an `["embeddedNoteJson", <json>]` tag (private channels carry it inside the MLS envelope under key `"em"`). There is **no** `q`/`k`/`p` quote pointer — the snapshot is the source of truth, so the receiver renders the embed with **no Isar lookup, immune to retention**. `EmbeddedNoteCodec` (`lib/core/notes/embedded_note_codec.dart`) is the single encode/decode/verify path. The user's own composed note (text + NIP-10 `e` references + NIP-92 `imeta` images) rides alongside as a normal note. **Integrity:** the snapshot's signature is verified once at inbound (`verifyAndSanitize`); on failure the `sig` is blanked and `EmbeddedNoteCard` shows an "unverified" badge. `quotedNote` is built in `NoteModel.toDomain()` from the snapshot — never an Isar quote lookup — and the cards render the embed gated on `quotedNote != null` (there is no separate `quoteEventId` field). **Tag-order discipline:** every publisher signs in the canonical order documented in `event_queue_model.dart` (single source of truth). No kind bypasses the shaped serializer.

---

## Nostr Event Model

> Everything is a `NostrEvent`. The `kind` field determines meaning. There are no separate "users", "channels", or "posts" at the protocol level.

```
NostrEvent {
  id:         String  — SHA256 of canonical serialization
  pubkey:     String  — author's secp256k1 public key (this IS the user identity)
  created_at: int     — Unix timestamp
  kind:       int     — determines meaning
  tags:       List    — [[tag_name, value, ...], ...]
  content:    String  — meaning depends on kind
  sig:        String  — Schnorr signature over id
}
```

### Kind Reference (UNIUN-relevant)

| Kind  | Name                | Description                                      |
|-------|---------------------|--------------------------------------------------|
| 0     | User Metadata       | Profile (name, avatar, nip05, about)             |
| 1     | Short Text Note     | Public note — the primary unit in UNIUN          |
| 3     | Contact List        | NIP-02 follow list — drives Vishnu feed scope    |
| 6     | Repost              | Repost of a Kind 1                               |
| 7     | Reaction            | Like or emoji on any event                       |
| 13    | Seal                | Layer 2 of encrypted DM (wraps Kind 14)          |
| 14    | DM Chat Message     | Actual DM content (inner rumor, unsigned)        |
| 40    | Channel Creation    | Creates a public channel; event ID = channel ID  |
| 41    | Channel Metadata    | Update channel name/description/icon             |
| 42    | Channel Message     | Message sent inside a channel                    |
| 1059  | Gift Wrap           | Outer envelope for encrypted DMs                 |
| 10063 | User Server List    | User's preferred Blossom media servers           |
| 24242 | Blossom Auth        | Signed auth token for Blossom uploads            |

### Tags Reference

```
["e", event_id, relay_url, marker, pubkey]  → references another event (graph edge)
["p", pubkey, relay_url]                    → references a user
["t", hashtag]                              → topic tag (graph node)
["a", kind:pubkey:d-tag, relay_url]         → reference to replaceable event
["imeta", "url ...", "m ...", "x ..."]      → inline media metadata (NIP-92)
["h", group_id]                             → NIP-29 private channel routing
["d", draft_id]                             → NIP-37 draft addressable id
["server", url]                             → BUD-03 user server (Kind 10063)
["expiration", unix_ts]                     → soft-expiry hint (NIP-37 drafts)
```

**NIP-10 e-tag markers** (threading):
- `"root"` — the top-level post of the thread → stored as `rootEventId`
- `"reply"` — the direct parent being replied to → stored as `replyToEventId`
- `"mention"` — cited for reference only → stored in `eTagRefs`

### Note Roles (Derived, NOT Stored as a Field)

Note roles are inferred at query time. Never add a `role`, `isReply`, `isRoot`, or `noteRole` field to any model or entity.

| Role           | Condition                                    | UI location         |
|----------------|----------------------------------------------|---------------------|
| Top-level note | `rootEventId == null`                        | Vishnu feed         |
| Reply          | `rootEventId != null`                        | Thread view         |
| Reference      | `type == NoteType.reference`                 | Knowledge graph link|

---

## NIP Implementation Stack

### Used in UNIUN

| NIP    | Purpose                                                  |
|--------|----------------------------------------------------------|
| NIP-01 | Base event format, relay WebSocket protocol              |
| NIP-02 | Contact list (Kind 3) — drives Vishnu feed `authors` filter |
| NIP-05 | Human-readable identifiers (`user@domain.com`) in profiles |
| NIP-10 | Reply threading via e-tag markers (root/reply/mention)   |
| NIP-17 | Private DMs — full 3-layer wrap (Kind 14 rumor → 13 seal → 1059 gift wrap), shipped |
| NIP-28 | Public channels (Kind 40 create / Kind 41 meta / Kind 42 msg) |
| NIP-44 | Encryption for DM payloads (ChaCha20-Poly1305)           |
| NIP-59 | Gift wrap (Kind 1059) — the outer envelope of the NIP-17 chain above, shipped |

### Explicitly NOT Used

| NIP    | Why excluded                                                      |
|--------|-------------------------------------------------------------------|
| NIP-09 | Event deletion — **permanently excluded**. Feed freedom is a core principle. Never implement. |
| NIP-04 | Legacy DM encryption (AES-CBC) — superseded by NIP-44.            |
| NIP-11 | Relay capability info — handled automatically by Khatru on relay; Flutter client does not implement. |
| NIP-65 | Relay list metadata (Kind 10002) — relays managed locally in `RelayModel` (Isar), not via Nostr events. |

---

## Data Layer

### Unified `Note` collection (everything is a note)

There is exactly **one** Isar collection for user-visible messages: `NoteModel` (`@Name('Note')`, accessor `isar.noteModels`). Feed notes, public-group messages, DMs, and private-group messages all live in it, discriminated by the Nostr **`kind`** field plus nullable container fields:

| `kind` | Surface | Container field set | Constant |
|--------|---------|---------------------|----------|
| 1      | Vishnu feed note          | (none)           | `kNoteKind` |
| 42     | Public group (NIP-28)     | `groupId`        | `kGroupMessageKind` |
| 14 / 15| Direct message (NIP-17)   | `conversationId` | `kDmTextKind` / `kDmFileKind` |
| 9023   | Private group (NIP-29)    | `privateGroupId` | `kPrivateGroupKind` |

> `NoteModel.groupId` carries `@Name('channelId')` and `NoteModel.privateGroupId` carries `@Name('groupId')` — both preserve the on-disk Isar schema name from before the app-wide channel→group rename. The Dart field names above (`groupId`/`privateGroupId`) are what the code actually uses today.

Constants live in `lib/core/notes/note_kinds.dart`. `kind` IS stored; note **roles** (reply/root/reference) are still *derived* from `rootEventId`/`replyToEventId`, never stored. `NoteEntity` is the single domain entity for every surface — there are NO `DmMessageEntity`, `GroupMessageEntity`, or `PrivateGroupMessageEntity` types. `NoteModel.toDomain()` maps `groupId → sourceGroupId`, `privateGroupId → sourcePrivateGroupId`, and carries `kind`/`conversationId`.

Because every message is in one collection keyed by a globally-unique `eventId`, cross-surface references resolve in a single indexed lookup: `NoteResolverRepository.resolveById` is one query (it derives the reply transport `NoteSource` from `kind`/container fields), and `FeedRepository` is one `(isSeen, created)`-indexed query (feed-eligible kinds 1/42/9023 only — DMs are excluded). `FollowedNoteModel` and `SavedNoteModel` remain **separate** tables (a follow-pointer and a forever-retained bookmark copy — metadata about notes, not note content). The `NoteRelationModel` edge table is kind-agnostic and unchanged.

Key files — read these directly rather than relying on this doc:
- `lib/data/models/notes/note_model.dart` — unified `NoteModel` Isar collection + `toDomain()`
- `lib/core/notes/note_kinds.dart` — `kind` discriminator constants
- `lib/domain/entities/note/note_entity.dart` — `NoteEntity` freezed (the only message entity)
- `lib/data/repositories/note_resolver_repository_impl.dart` — single-collection resolver
- `lib/data/repositories/feed_repository_impl.dart` — single-collection feed
- `lib/core/error/failures.dart` — `Failure` freezed union
- `lib/core/usecases/usecase.dart` — `UseCase<T,P>` and `NoParamsUseCase<T>` base classes

**Critical field notes (NoteModel):**
- `kind` is the unified discriminator; `groupId`/`privateGroupId`/`conversationId` are non-null only for their respective kinds (all indexed).
- `rootEventId` and `replyToEventId` are NIP-10 threading fields. Both null = top-level feed note.
- `eTagRefs` stores ALL e-tag event IDs including root/reply/mention. `rootEventId`/`replyToEventId` are extracted separately. For `kind == 42`, `toDomain()` strips `groupId`/`replyToEventId` from `eTagRefs` so NoteCard counts only genuine mentions.
- `embeddedNoteJson` — nullable; the embed-by-value snapshot of the quoted original (the `embeddedNoteJson` tag / MLS envelope key). Source of truth for `quotedNote`, which `toDomain()` decodes directly (no Isar lookup, retention-immune). A blanked `sig` inside it means the embed failed signature verification (renders an "unverified" badge). The cards gate the embed on `quotedNote != null` — there is no separate `quoteEventId` render marker.
- `attachments` is a `List<MediaAttachment>` embedded directly on the note (one entry per NIP-92 `imeta` tag). `hasMedia` is derived from `attachments.isNotEmpty` in the constructor — never set it manually.
- `NoteType` enum (`text|image|link|reference`) stored as `EnumType.name` in Isar.

**Media:** there is exactly one media-related side table — `MediaCacheModel { sha256, localPath, downloadedAt }`. It tracks which blobs are on this device. Imeta metadata lives on `NoteModel.attachments`; cache state lives on `MediaCacheModel`; the two are joined by SHA-256. There is no `MediaBlobModel`, no `NoteMediaRefModel`, no reference counter, no automatic media GC. Removing a file from device is user-driven via the gallery (`MediaRepository.removeLocal`).

**Generated files — never edit manually.** Regenerate with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
Build order: `freezed` runs before `isar_generator` (enforced via `pubspec.yaml` `global_options`).

---

## Package Versions (Critical — Do Not Upgrade Without Checking)

| Package                        | Version     | Why This Exact Version                                         |
|--------------------------------|-------------|----------------------------------------------------------------|
| `isar_community`               | `3.3.2`     | NOT `isar` 3.x — the original isar package is incompatible with Dart 3.x. Use `isar_community` fork. |
| `isar_community_flutter_libs`  | `3.3.2`     | Must match `isar_community` exactly                            |
| `isar_community_generator`     | `3.3.2`     | Must match `isar_community` exactly (dev dependency)           |
| `freezed`                      | `^3.0.0`    | NOT 2.x — v3 requires `abstract class` pattern for `@freezed` entities |
| `freezed_annotation`           | `^3.0.0`    | Must match `freezed` major version                             |
| `build_runner`                 | `^2.13.0`   | Needs `build_runner_core` 9.x compatibility                    |
| `injectable`                   | `^2.3.2`    | DI annotation framework                                        |
| `injectable_generator`         | `^2.4.1`    | DI code generator (dev dependency)                             |
| `dartz`                        | `^0.10.1`   | Functional Either/Option types                                 |
| `tostore`                      | `^3.1.2`    | Not 3.1.0: its `statvfs` struct is 24 bytes short, so every disk-space check overflows the heap (random native aborts). 3.1.2 reads 3.1.0 stores unchanged. 3.5.x changes the API and on-disk format — upgrading needs a re-embed path first. |
| `google_mlkit_text_recognition`| `^0.17.1`   | On-device OCR for Shiv's image search. The plugin bundles only the Latin recogniser and declares the others `compileOnly`, so Hindi needs `text-recognition-devanagari` in `android/app/build.gradle.kts` and `GoogleMLKit/TextRecognitionDevanagari` in `ios/Podfile` — remove either and Hindi text silently goes unread at runtime (the build still passes, and English OCR keeps working, so nothing looks broken). The enum value is spelled `TextRecognitionScript.devanagiri`. |
| `google_mlkit_image_labeling`  | `^0.16.1`   | On-device labels ("dog", "food") for Shiv's image search. **Ships without Firebase:** the plugin hard-depends on `com.google.mlkit:linkfirebase` (→ `firebase-common` + `firebase-iid`) only for Firebase-hosted custom models, so `android/app/build.gradle.kts` excludes it and `proguard-rules.pro` has `-dontwarn com.google.mlkit.linkfirebase.**`. Never use the `remote` model type or `manageFirebaseModels` — that branch needs the excluded classes. |
| `flutter_bloc`                 | `^8.1.3`    | BLoC state management                                          |
| `bloc_concurrency`             | `^0.2.4`    | Event transformers (droppable, sequential, restartable)        |
| `flutter_gemma`                | `^1.5.1`    | Needs `hooks ^2.0.0`; openmls 1.3 still pins `hooks ^1.0.0`, but its pin is conservative — `dependency_overrides: hooks: ^2.0.0` in `pubspec.yaml` lets both coexist (verified: clean build). Drop the override once openmls relaxes upstream. `background_downloader` (flutter_gemma's transitive download engine) is separately pinned to `9.5.6` — `9.5.7` fails the Android Kotlin build on this project's legacy Gradle setup. |
| Dart SDK                       | `>=3.12.0 <4.0.0` | Toolchain: Flutter 3.44.2 / Dart 3.12.2                  |

**Isar import**: Always use `package:isar_community/isar.dart`. Never `package:isar/isar.dart`.

---

## Modules / Features

### Vishnu — Feed

The main chronological feed of Kind 1 notes.

- Displays top-level notes (`rootEventId == null`) newest-first.
- Pagination via `createdLessThan(before)` cursor on `NoteModel.created`.
- Unread tracking: `FeedReadStateModel` (Isar `@collection`, single row) stores `lastReadEventId` and `lastReadTimestamp`. As the user scrolls, the BLoC receives the last visible event ID via `UpdateFeedReadPositionEvent` and persists it.
- On next app launch, feed resumes from `lastReadEventId` position (Telegram-style "you are here" marker).
- No ranking algorithm in v1. Pure chronological.

**BLoC**: `VishnuFeedBloc`
- `LoadFeedEvent` → calls `GetFeedUseCase` → emits feed state
- `LoadMoreFeedEvent` → pagination with `before` cursor
- `RefreshFeedEvent` → reload from top
- `SaveNoteEvent` → calls `SaveNoteUseCase`
- `UpdateFeedReadPositionEvent` → updates `FeedReadStateModel`

### Brahma — Create Note

Note composition and publishing.

- Supports all `NoteType` values: `text`, `image`, `link`, `reference`.
- Image upload via Blossom protocol (Kind 24242 auth token, PUT to user's Blossom server, `imeta` tag in event).
- Reference picker allows selecting existing notes to create graph edges (`e` tags with `mention` marker).
- Graph preview shown before publishing (using `BuildNoteGraphUseCase`).
- Signs note with user's private key. Broadcasts via the Gateway's EventQueue.
- Draft support via `DraftNoteRepository` (local only, not published to relay).

**BLoC**: `BrahmaCreateBloc`
- `UpdateContentEvent`, `AddReferenceEvent`, `RemoveReferenceEvent`
- `AttachImageEvent` → Blossom upload flow
- `TagUserEvent` → adds `p` tag
- `PreviewReferenceGraphEvent` → shows graph before submit
- `SubmitNoteEvent` → sign + enqueue for relay publishing

### Shiv — AI Assistant

On-device AI assistant using GraphRAG over the user's saved notes.

- **Model selection** via `AIModelSelectionPage`/`SelectAIModelCubit`. Catalog: Qwen3 0.6B, DeepSeek R1, Gemma 4 E2B/E4B. Selection stored in `AppSettingsModel`. Downloads use `FlutterGemma.installModel().withCancelToken(...)` — `SelectAIModelCubit.cancelDownload()` aborts in-flight via a domain-side `DownloadCancellation` handle.
- **RAG pipeline** (`lib/features/shiv/rag/`): Phase 1 — `RagPipeline.init()` (embedder) + `AIModelRunner.initChat()` (just validates a model is active — the runner stores NO per-conversation state). Phase 2 — each turn: embed query → `VectorSearchService` (cosine top-K, **scoped to the picked Manas** via `ManasContextLoader.merge` when one is selected, else the whole library) → 1-hop graph expansion (`GetGraphNeighboursUseCase`) → memory lookup (`GetMemoriesByNoteIdsUseCase`) → `EnrichedContext` → `PromptBuilder` within `PromptBudget`. The **system instruction is built per-conversation and passed PER TURN** into `sendAndStream` (NOT stored on the singleton runner), so independent chat surfaces (Shiv tab + inline composer-chat) never clobber and every use case carries its own.
- **Conversation persistence**: `ShivConversationModel` + `ShivMessageModel`. `parentId` chain enables the branch tree view; `activeLeafMessageId` tracks which leaf the user reads. Auto-title: first 40 chars of first user message.
- **Memory nodes**: `MemoryNodeModel` carries wiki-style summaries linked to graph nodes; loaded as additional RAG context.
- **Thinking tag**: DeepSeek R1 emits `<think>...</think>` blocks. `ShivMessageBubble._parseThinking()` splits visible vs. collapsible. Stored content is cleaned via `stripThinking` (in `generation/chat_helpers.dart`).
- **Shared generation substrate** (`lib/features/shiv/generation/`): the context→prompt→invoke pieces every AI feature reuses. `context/manas_context_loader.dart` (relocated here from `gana/engine/` — an `@lazySingleton` packing a Manas/all-notes note pool: relevance-ranked `merge`/`searchAll`, or **static** newest-first `packNewest`/`loadPool`/`loadAll` for the DI-less background isolate, with `isar` passed as a param there); `prompt/prompt_parts.dart` + `prompt/composer_chat_prompt.dart` (shared `/no_think`/`<NOOP>` + per-use-case templates); `gana_run.dart` (the input→prompt Gana pipeline both Gana isolates delegate to); `chat_helpers.dart` (`stripThinking`/`buildBranch`/`pairCleanHistory`/`entityContextLines`).
- **Gana** (`lib/features/shiv/gana/`): user-owned AI agents that watch an input surface, infer over selected Manas(es), and autonomously publish. Foreground `GanaEngine` (main isolate) + background `gana_workmanager.dart` (own isolate + own Isar, no DI) both call `generation/gana_run.dart` (`prepareGanaRun` + shared guard/log/cursor helpers); the divergent inference + publish stay per-isolate. A Gana can be pinned to a UNIUN Cloud model (`GanaEntity.desiredBackend == uniunCloud`), independent of the app's globally active backend — the foreground engine routes that one call through `GenerateOneShotUseCase`'s `backendOverride`; the background isolate calls `UniunGatewayClient` directly using an API key handed over via `inputData` at schedule time (no re-auth per tick). Local pins keep the original skip-on-mismatch gate (no cheap way to swap the on-device model per-call). See `docs/SHIVA/Ganas.md` §1.3. The form UI folds the raw `(triggerMode, triggerReactive, triggerIntervalMinutes)` triple into a single **"When should this run?"** radio via `GanaTriggerPreset` (`lib/core/enum/gana_trigger_preset.dart`) — five presets cover the matrix and `validFor(inputType)` hides options that can't fire; raw fields stay in Isar so legacy rows keep working. **Screens:** `GanaDashboardPage` (route `shivGanaList`, opened from the Shiv home Gana button) is the one Gana screen — totals, a needs-attention list, each Gana with an outcome bar, counts, trigger and scope, recent activity, a New button; there is no separate list page. `GanaDetailPage` shows lifetime stats and the last 10 runs as drop-downs: a succeeded run opens to the note it published, a failed run to a plain-words reason from `GanaRunError.parse` (best-effort reading of the raw `<stage>: <error>` text) with the raw error underneath, a skipped run to its reason. **Counters:** `GanaModel.runsSucceeded/runsFailed/runsSkipped` are the only lifetime figures (the run log keeps 10 per Gana); `writeGanaRun` bumps them in the same transaction as the log row, once per `runId`; they are nullable because Isar reads a missing field on an old row as the minimum integer, are per-device (not in the mesh body) and `upsertGana` preserves them across edits.
- **Nataraj** (`lib/features/shiv/nataraj/`): a swipe deck that synthesizes 2–3 of the user's own notes into one new note, reusing the generation substrate. Cards are a local cache (not Nostr events). Read `lib/features/shiv/nataraj/` directly — single feature folder with engine + bloc + pages + widgets.
- **Composer-chat** (`lib/features/shiv/composer_chat/`): the shared `UniunComposer`/`ComposerHost` turns into an inline AI chat — tap the avatar → pick a Manas (or "All notes" → "Ask Brahma") → ask. `ComposerChatCubit` streams the answer via `SendChatStreamUseCase`, grounded in the surface's recent messages (`entityContextLines`) + the Manas (`merge`/`searchAll`), with its OWN distinct system instruction. Works in every surface using the composer (thread/channel/DM/private). The Shiv-tab input (`ShivInputComposer`) has the same Manas picker, which scopes `RagPipeline.buildMessage(manasIds:)`.
- **On-device runner**: `AIModelRunner` lives at `lib/data/datasources/llm/local_llm_runner.dart` (NOT `shiv/services/`). flutter_gemma 1.0; prefers **GPU** with a CPU fallback (foreground + bg Gana + embedder); opens a throwaway `openChat` per turn and re-feeds system + trimmed history + RAG (stateless per turn — see the RAG bullet).
- **LLM repository abstraction** (`lib/domain/repositories/llm_repository.dart`): unified contract every consumer (`ShivAIBloc`, `NatarajGenerator`, `ComposerChatCubit`, `ExtractKnowledgeUseCase`) goes through — `sendChat` (stream), `generateOneShot`, `openConversation`/`closeConversation`, `preempt`/`resumeBackgroundWork`, `getActive`/`setActiveBackend`, `listAvailableModels`, `setActiveModel`. `LlmRepositoryImpl` dispatches by active `LlmBackendType` (`localGemma` | `uniunCloud`) read from `LlmPreferencesDataSource`. Two data sources implement `LlmDataSource`: `LocalLlmDataSource` (wraps `AIModelRunner` + `InferenceScheduler` + `AIModelRepository` catalog) and `RemoteLlmDataSource` (a thin delegate to `UniunRepository.streamChat`/`listAvailableModels` — no HTTP/auth logic of its own; single in-flight extraction cancel-port, no local queue). `UniunRepository`/`UniunRepositoryImpl` is the sole wrapper around the raw `UniunGatewayClient` HTTP client for UNIUN's own inference gateway (`api.uniun.in`) — sign-in is a silent Nostr-keypair challenge/sign, never a pasted API key; it also handles QR-login approval and the gateway-backed onboarding interest roster. `InferenceScheduler` (`lib/data/datasources/llm/inference_scheduler.dart`) is the **UNIUN Scheduling Algorithm**: 5 tiers — T0 chat, T1 foreground-of-current-page, T2 extract, T3 deadline (Gana cron past fire time), T4 fair pool (nataraj + gana, CFS-style `vruntime`) — with model-affinity batching to amortize the ~10 s `flutter_gemma` model swap. Embedding lives on a separate `EmbeddingQueue` (one embed at a time, a Shiv question served ahead of queued notes and PDF/DOCX chunks; parallel chip path). Full spec in [`docs/SHIVA/scheduling.md`](docs/SHIVA/scheduling.md). API keys live in `LlmCredentialsDataSource` (FlutterSecureStorage — Android Keystore / iOS Keychain, **never** Isar/SharedPreferences). The background `gana_workmanager.dart` isolate keeps the simpler direct-`FlutterGemma` path for local Ganas — the repository abstraction is for the main isolate (no `getIt` in bg). A cloud-pinned Gana in that same isolate calls `UniunGatewayClient` directly instead (also no DI needed — it's a plain `http.Client` wrapper).
- **App settings repository** (`lib/domain/repositories/app_settings_repository.dart`): wraps the existing `AppSettingsStore` (SharedPreferences) behind a domain interface. Use cases: `getNatarajCoachSeen`/`set…`, `getAutoDeleteOldNotesDays`/`set…`, `getRecentSyncWindowDays`/`set…`. BLoCs/Cubits read settings via use cases; only `AppSettingsRepositoryImpl` touches the store.

Read these files for the full picture rather than expanding this section:
- `lib/features/shiv/chat/bloc/shiv_ai_bloc.dart`
- `lib/features/shiv/rag/pipeline/rag_pipeline.dart`
- `lib/data/datasources/llm/local_llm_runner.dart` — `AIModelRunner` (moved out of `shiv/services/`)
- `lib/data/datasources/llm/llm_data_source.dart` + `local_llm_data_source.dart` + `remote_llm_data_source.dart` — backend split
- `lib/domain/repositories/llm_repository.dart` + `lib/data/repositories/llm_repository_impl.dart` — backend-agnostic contract + dispatch
- `lib/features/shiv/generation/` — shared context / prompt / gana_run / chat_helpers substrate
- `lib/features/shiv/composer_chat/cubit/composer_chat_cubit.dart`
- `lib/domain/usecases/shiv_usecases.dart`

### Public Groups — Chat (NIP-28)

> Renamed from "Channels" to "Groups" across code, routes, and UI — `GroupModel`/`PrivateGroupModel` carry `@Name('Channel')`/`@Name('PrivateChannel')` only to preserve the on-disk Isar schema name across the rename. If you see "Channel" naming anywhere outside those two `@Name(...)` annotations, it's stale — the live terminology is Group. Full detail: `docs/Messaging/`.

- Kind 40 = group creation. The `event.id` of the Kind 40 event **is** the group id forever (stored as `GroupModel.groupId`). Never generate a separate id.
- Kind 42 = group message, tagged `["e", groupId, "", "root"]`. Built by `CreateGroupMessageUseCase`.
- Kind 41 = metadata update (creator only) — handled gateway-side by `Kind41Handler` (`lib/gateway/inbound/handlers/kind41_handler.dart`), which checks `event.pubkey == group.creatorPubKey` before applying.
- `lib/features/groups/{create,join,feed,thread}/bloc/` — `CreateGroupBloc`, `JoinGroupBloc`, `GroupFeedBloc`.
- Unread tracking is unified, not per-surface: a single `UnreadNoteModel` row per unread message across every surface (feed/group/DM/private group), discriminated by `kind`. There is no separate `ChannelReadStateModel`.
- Join by QR or manual ID both feed the same `JoinGroupBloc` text field — QR/deep-link just pre-fills it, there's no QR-only code path.
- QR payload: `UniunQrPayload` with `UniunQrKind.publicGroup` (`lib/common/qr/uniun_qr_payload.dart`). Generation: `UniunQrCard.publicGroup()`. See `docs/General/QR_AND_DEEP_LINKS.md`.

### Private Groups (NIP-29 + MLS)

> See `docs/Messaging/` for the full Marmot/MLS design — group creation, key packages, Welcome/Commit events, admin approval flow.

- Encrypted group messaging (Kind 9023 application messages) using MLS (`openmls` Dart package) via `MarmotMlsService` (MLS engine, SQLCipher `mls_data.db`) + `MarmotTransportService` (the Nostr-facing orchestrator: create/join/leave/send/approve).
- Wire kinds: 9021 = join key-package request, 9023 = application message, 9024 = Welcome, 9025 = Commit, 9002 = group metadata.
- `lib/features/private_groups/{create,join,detail}/bloc/` — `CreatePrivateGroupBloc`, `JoinPrivateGroupBloc`, `PrivateGroupDetailBloc`.
- `PrivateGroupModel` (`groupId`, `mlsGroupId`, `adminPubkey`, ...) and `PrivateGroupJoinRequestModel` (`eventId`, `senderPubkey`, `keyPackageB64`, `handled: bool` — rows are never deleted, so a re-synced join request can't be double-processed) — Isar collections.
- Admin approval (`MarmotTransportService.approveJoinRequest`) calls `MarmotMlsService.addMembers`, publishes a Kind 9024 Welcome + Kind 9025 Commit, then marks the request row `handled`.

### DMs — Direct Messages (NIP-17)

> Encryption/decryption both live in one class: `Nip17EncryptionService` (`lib/domain/services/nip17_encryption_service.dart`). Full detail: `docs/Messaging/`.

- Kind 14 = the actual message content (called a "rumor" — it is UNSIGNED).
- Three-layer encryption: Kind 14 → NIP-44 encrypt → Kind 13 (seal, signed) → NIP-44 encrypt with an ephemeral key → Kind 1059 (gift wrap, the only thing published to relay).
- Inbound Kind 1059 rows land first in `EncryptedDmModel` (a temporary queue), get decrypted by `Nip17EncryptionService.processInboundQueue`, and are written straight into the unified `NoteModel` table (`sig: ''` — deniable, no valid NIP-01 signature) before the queue row is deleted in the same transaction.
- Only `["p", recipient_pubkey]` is visible on the relay. Subscription filter: `{"kinds": [1059], "#p": ["my_pubkey"]}`.
- Unread tracking uses the same unified `UnreadNoteModel` as groups/feed — there is no separate `DMReadStateModel`.

### Followed Notes

Subscribing to a note's reference graph — distinct from saved notes (which are for Shiv AI).

- `FollowedNoteModel` (`eventId`, `contentPreview`, `followedAt`, `newReferenceCount`). Gateway opens `{"kinds":[1],"#e":["followedNoteId"]}` per followed note; SyncEngine bumps `newReferenceCount` on each match.
- `FollowedNotesCubit`: `load() / followNote() / unfollowNote() / clearNewReferences()`.
- UX: drawer hosts a collapsible "Followed Notes" section. Tapping a row opens `FollowedNoteDetailPage` directly — there is NO standalone `FollowedNotesPage`.

### Reports & Moderation (NIP-56)

UNIUN ships **Kind 1984** reporting (NIP-56) — the App Store / Play Store user-content-moderation hook. The block system was already in place; reporting is the second half.

- `ReportModel` (`@Name('Report')`) — one row per filed report. Unique-replace index on `eventId`; indexed `targetEventId` + `targetPubkey` + `created`. Persisted forever (it's the user's own moderation history).
- `ReportType` enum — `nudity / malware / profanity / illegal / spam / impersonation / other`. The `.name` is the wire value placed in the report-type slot of every `e`/`p` tag.
- `kReportKind = 1984` lives in `lib/core/notes/note_kinds.dart` — Kind 1984 is the ONLY kind that emits NIP-56-shaped tags via `EventQueueModel.reportType`.
- `EventQueueModel.reportType` (nullable) — when set, `toSerializedRelayMessage` emits `["e", id, "", reportType]` and `["p", pubkey, reportType]` (the report type pre-empts the NIP-10 root/reply/mention markers entirely). Documented in the canonical tag-order block.
- `ReportRepository` — `reportNote / reportUser / listMyReports / hasReported`. Implementation signs the Kind-1984 event with the existing `UserRepository.getActiveKeysHex()` path, persists the local `ReportModel`, and enqueues via `EventQueueRepository.enqueueSignedEvent(reportType: ...)` — single shaped publish path, no escape hatch.
- UI: `ReportSheetPage.show(context, targetEventId:, targetPubkey:)` opens a modal bottom sheet with radio + optional reason + an "Also block this user" checkbox (default OFF). `MyReportsPage` lists submitted reports. Wired into `NoteCardMenu` (foreign notes only, alongside Block) and surfaced from Settings → My Reports.
- **Submit composes three effects** (in `ReportSheetCubit.submit`): (1) ALWAYS publish the Kind-1984 event; (2) ALWAYS tombstone the reported note locally via `DeleteNoteUseCase` so the reporter's feed / threads stop showing it (silently skipped on profile-only reports); (3) OPTIONALLY call `BlockUserUseCase` when the checkbox is on. Steps 2–3 are best-effort follow-ups; a failure there does not roll back the published report.
- **v1 explicit non-goal**: UNIUN does NOT consume reports authored by others. Aggregation / filtering is left to the relay layer or a future client-side scoring pass. NIP-56 itself warns that relay-side automod off reports is easily gamed.

### Sharing (embed-by-value)

The share button on any NoteCard opens `ShareSheetPage` (modal bottom sheet) with destinations: Feed / Public group / Private group / DM, plus "Share via…" external link via `share_plus`. The sheet has an **inline composer** above the destination tiles: the user authors a full note — text + references (NIP-10 `e` mentions, via `ReferencePickerPage`) + images (NIP-92 `imeta`, via `showMediaPickSheet` → `UploadMediaUseCase`) — published alongside the embed. `ShareRepositoryImpl` dispatches each destination to the existing publish use case (`PublishMediaNoteUseCase` / `CreateGroupMessageUseCase` / `SendDmUseCase` / `SendPrivateGroupMessageUsecase`) — no new publish path. The shared original is carried **by value** as an `embeddedNoteJson` snapshot tag (see the bullet under "Note Model"), NOT a `q` pointer. If the shared note is itself a share, the genuine inner original is snapshotted (`quotedNote.quotedNote` stays null). External URL: `https://www.uniun.in/note/<hex>` (App Links + Universal Links, see `lib/core/router/deep_link.dart`).

**Tag-order discipline** (re-read this before reordering tags anywhere): publishers must emit tags in the same order `EventQueueModel.toSerializedRelayMessage` rebuilds, or the broadcast event re-serializes to a different hash and the relay rejects the signature. Canonical order: `e root → e reply → e mention… → p… → t… → h → d → k → embeddedNoteJson → expiration → server… → imeta…` (the old NIP-18 `q` slot is now `embeddedNoteJson`; `k` survives for NIP-37 drafts only). **NIP-56 (Kind 1984)** is the one exception that re-shapes the `e`/`p` rows: when `EventQueueModel.reportType` is set, the e tag becomes `["e", id, "", reportType]` and the p tag becomes `["p", pubkey, reportType]`, with NIP-10 markers suppressed. There is **no** raw-passthrough escape hatch — every kind serializes through the shaped path, including private channels (Kinds 9002–9025, via `h`), drafts (Kind 31234, via `d`/`expiration`), Blossom server lists (Kind 10063, via `server`), and notes with media (Kinds 1 / 42, via `imeta`). Inline docs in `event_queue_model.dart` are authoritative.

---

## Gateway (Relay Sync Isolate)

The Gateway runs in a separate Dart isolate (`lib/gateway/`). It owns all relay WebSocket connections. The Flutter UI never touches the relay directly — Isar is the shared bus between isolates.

```
lib/gateway/
  ├── gateway.dart              — entry point, spawns the isolate
  ├── gateway_init_message.dart — carries isarDirectory path to the isolate
  ├── orchestrator/             — GatewayOrchestrator + RelayRegistry: coordinates
  │                               relay connections and drives resubscribes
  ├── transport/                — the actual per-relay WebSocket connections
  ├── session/                  — per-relay session state
  ├── inbound/                  — InboundBus + incoming-event handlers → write to Isar
  ├── outbound/                 — OutboundPump: the publish queue
  ├── watchers/                 — IsarWatcherHub: consolidates every watchLazy() subscription
  └── cleanup/                  — CleanupManager: retention policy enforcement
```

**How it works:**
- The isolate opens its own `Isar` instance at the same path — no `SendPort` needed. Isar is the interface.
- `IsarWatcherHub` (`lib/gateway/watchers/isar_watcher_hub.dart`) holds every `watchLazy()` subscription the Gateway needs, replacing what used to be five separate ad-hoc subscriptions on one class:
  - `EventQueueModel` watcher → new queue rows trigger immediate send via `outbound/`.
  - `RelayModel` watcher → syncs live relay connections when relays are added/removed at runtime.
  - `FollowedNoteModel` watcher → refreshes `#e` REQ subscriptions.
  - `CleanupManager` (`cleanup/`) purges queue entries and expired notes per the retention table below.

**The per-relay transport (`transport/`):**
- Persistent connection, exponential backoff reconnect (max 60s).
- Outbound: cursor-based (`_lastSentQueueId`); one event in-flight, waits for `["OK"]` ACK.
- Group events (Kind 40–44) routed to group-specific relays via `GroupModel.relays`; temporary services created for those relays (5 min TTL).
- Inbound: stores received Kind 1 events to `NoteModel` (idempotent). Bumps `FollowedNoteModel.newReferenceCount` when e-tags match a followed note.

**Relay subscriptions the Gateway opens:**
```dart
// Kind 1 notes scoped to self + followed users (feed_notes subscription)
// — see lib/gateway/subscriptions/providers/feed_notes_subscription.dart
{"kinds": [1], "authors": ["selfPubkey", "followedPubkey1", ...]}

// Followed note references — refreshed when FollowedNoteModel changes
{"kinds": [1], "#e": ["followedNoteId1", "followedNoteId2", ...]}

// Public group messages — see lib/gateway/subscriptions/providers/groups_subscription.dart
{"kinds": [42], "#e": ["...joined groupIds"], "since": ...}
// companions: {"kinds": [40], "ids": [...groupIds]}  {"kinds": [41], "#e": [...groupIds]}

// Private group traffic — see private_groups_subscription.dart
{"kinds": [9023], "#h": ["...joined groupIds"], "since": ...}
// companions: {"kinds": [9002], "ids": [...groupIds]}  {"kinds": [9021, 9022, 9024, 9025], "#h": [...groupIds]}

// DMs — gift wraps addressed to this user (shipped) — see dms_subscription.dart
{"kinds": [1059], "#p": ["myPubkey"]}
```

**The Gateway (`lib/gateway/`) is owned by this codebase and is editable.** The Flutter UI still only reads/writes Isar; the Gateway is the only component that talks to relays. Inbound handlers write into the unified `Note` collection (see below).

**Isar retention policy (enforced by CleanupManager):** retention is now applied per-`kind` to rows **within the single `Note` collection**, not per-collection.

| Note kind (in `Note` collection)   | Retention              |
|------------------------------------|------------------------|
| Kind 1 (regular, not saved)        | 7 days (configurable)  |
| Kind 1 (saved — separate SavedNote table) | Forever         |
| Kind 1 (own note, own pubkey)      | Forever                |
| Kind 42 (channel message)          | 3 days (configurable)  |
| Kind 14/15 (DM content)            | Forever                |
| Kind 9023 (private channel message)| Forever                |
| Kind 0 (profiles — own table)      | 30 days, refresh on view|
| AI conversations/messages          | Forever                |

**Media files have no retention of their own.** There is no timer or sweep that targets media directly, and the user can always remove a blob by hand via Settings → Storage → Media. Saved / followed / own / DM / private-channel media stay on disk as long as the user wants them — those notes are never evicted, so their media is never touched by GC either. **Ordinary notes' media is not exempt, though**: `CleanupManager`'s opt-in note-retention sweep (`lib/gateway/cleanup/cleanup_manager.dart`, off by default) deletes any `MediaCacheModel` file left unreferenced after it evicts an old note — a side effect of note eviction, not an independent media policy. The cache table (`MediaCacheModel`) is the only record of what's on disk — deleting a row from it deletes the file.

On-demand fetch: if a note is referenced but not in Isar, `SyncEngine.fetchById(eventId)` queries the relay with `{"ids": [eventId]}`.

---

## BLoC Pattern

```
User action (tap, scroll, type)
    ↓
UI sends Event to BLoC: context.read<SomeBloc>().add(SomeEvent(...))
    ↓
BLoC handler calls use case: final result = await useCase.call(input)
    ↓
Use case calls repository: return await repository.doSomething(...)
    ↓
Repository reads/writes Isar, returns Either<Failure, Entity>
    ↓
BLoC folds the Either, emits new State
    ↓
UI rebuilds via BlocBuilder<SomeBloc, SomeState>
```

**Named BLoCs per module:**
- `VishnuFeedBloc` — feed
- `BrahmaCreateBloc` — note creation
- `ShivAIBloc` — AI assistant
- `GraphBloc` — knowledge graph view
- `DrawerBloc` — groups + DMs drawer
- `SavedNotesBloc` — saved notes management

**Event transformer usage (bloc_concurrency):**
- Use `droppable()` for search/query events (ignore new events while processing).
- Use `sequential()` for write operations (process in order).
- Use `restartable()` for user typing/input (cancel previous, start new).

---

## Dependency Injection

Uses `injectable` + `get_it`.

| Annotation                      | When to use                                        |
|---------------------------------|----------------------------------------------------|
| `@singleton`                    | `Isar` instance — one per app lifetime             |
| `@injectable`                   | Repository implementations, BLoC instances         |
| `@lazySingleton`                | Use cases — created on first access                |
| `@Injectable(as: Interface)`    | Repository impl registered as its interface        |

After adding any `@injectable`, `@singleton`, or `@lazySingleton` annotation, regenerate:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Blossom Media Upload

Blossom is a content-addressed HTTP blob store. File identity = SHA-256 hash. Same file on any Blossom server = same URL.

Upload flow:
1. User selects image → app computes SHA-256 locally.
2. `HEAD /<sha256>` on user's Blossom server — check if already uploaded.
3. If not found: sign Kind 24242 auth event (t=upload, x=sha256, expiration=+10min), `PUT /upload` with auth header + file bytes.
4. Receive blob descriptor: `{url, sha256, size, type}`.
5. Embed in note: `content` gets the URL, `tags` gets `["imeta", "url ...", "m image/jpeg", "x <sha256>", "dim WxH"]`.

User's Blossom servers declared in Kind 10063 event.

---

## Backend Responsibility Split

```
Flutter App (this repo)
    ↓ reads/writes
Isar DB (local, offline-first source of truth)
    ↑ written by
Gateway sync isolate (lib/gateway/ — owned by this repo)
    ↕ WebSocket (NIP-01)
uniun-backend/  ← Go relay (Khatru + BadgerDB + Blossom)
    ↕ optional mirror
MySQL

Flutter Brahma (image attach)
    → PUT /upload  (Blossom BUD-01)
uniun-backend Blossom handler
    → Azure Blob Storage
```

- **Flutter App (this repo)**: Create/sign notes, render UI from Isar, all user interactions
- **Gateway sync isolate (`lib/gateway/` — owned by this repo)**: Saves relay events to Isar (inbound handlers write the unified `Note` collection), manages WebSocket connections, EventQueue for offline sync.
- **uniun-backend/ (Go relay — this repo, `uniun-backend/` folder)**: Khatru-based Nostr relay. Accepts/stores events (BadgerDB primary, MySQL optional mirror). Handles Blossom media uploads via Azure Blob Storage. See `docs/Architecture/BACKEND.md` and `uniun-backend/DEPLOY.md`.

**Rule:** Never add direct HTTP calls from Flutter to the relay. Flutter only talks to Isar. The Gateway handles all relay communication.

The Flutter app **never talks to the relay directly**. It only reads/writes Isar. The Gateway handles all network sync.

---

## Datasource

There is no remote datasource in this app. The only datasource is Isar (local, on-device).

Each repository impl receives `Isar` via constructor injection. The Isar instance is opened once as a `@singleton` via `IsarModule`:

File: `lib/data/datasources/isar_module.dart`

```dart
@module
abstract class IsarModule {
  @singleton
  @preResolve
  Future<Isar> createIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [NoteModelSchema, ProfileModelSchema, ...],  // add every new model schema here
      directory: dir.path,
    );
  }
}
```

**Rule**: Every new Isar `@Collection` model must have its generated schema added to `IsarModule.createIsar()`.

---

## User Storage Strategy

### Own User (the logged-in identity)

| What | Where | Retention |
|------|-------|-----------|
| Private key (nsec bech32) | `flutter_secure_storage` (Android Keystore / iOS Keychain) | Until logout |
| Public key (hex) + npub | Isar `UserKeyModel` | Until logout |
| Profile (Kind 0) | Isar `ProfileModel` with `lastSeenAt = DateTime(3000, 6, 1)` | Forever — sentinel date prevents eviction |

The private key is **never** written to Isar. `UserKeyModel` holds only the public identity.

On app launch, `SplashPage` calls `UserRepository.getActiveUser()`:
- `Right(user)` → skip onboarding, go to `HomePage`
- `Left(notFound)` → show `WelcomePage`

On reinstall, Isar is wiped but `flutter_secure_storage` may survive on Android (depends on backup settings). If Isar is empty but secure storage has the key, the user will be asked to log in again — the private key alone is insufficient without the Isar row.

### Other Users (feed / DM / channel participants)

| Category | Profile stored? | Retention |
|----------|----------------|-----------|
| Own user | ✅ Yes, `lastSeenAt = DateTime(3000,6,1)` | Forever (sentinel) |
| DM / Channel participants | ✅ Yes | Forever |
| Feed users (seen) | Temporarily | 30 days from `lastSeenAt` |
| Random unseen users | ❌ Not stored | — |

`ProfileModel.lastSeenAt` is updated each time the profile appears in the UI. The `CleanupManager` evicts profiles where `lastSeenAt < now - 30 days`. Own profile uses `DateTime(3000, 6, 1)` so it is never evicted — there is no `isOwn` boolean field.

### Following: two independent axes

UNIUN has **two** kinds of "follow", aimed at different things. They are not aliases.

**1. Followed Users (people-following, NIP-02 Kind 3)**
- `FollowedUserModel` (Isar) — local mirror of the user's contact list. Kept in sync with the published Kind 3 event by `Kind3ContactListHandler` (inbound) + `FollowUserUseCase` / `UnfollowUserUseCase` (outbound).
- The Vishnu feed is scoped to `{kinds:[1], authors:[selfPubkey, ...followedPubkeys]}` — see `lib/gateway/subscriptions/providers/feed_notes_subscription.dart`. Empty follow list ⇒ feed shrinks to own notes only (relay does not firehose the public timeline at us).
- When the follow set changes, `IsarWatcherHub` fires `onFollowedUsersChanged` → orchestrator `resubscribeAll('feed_notes')`.
- Use cases: `FollowUserUseCase`, `UnfollowUserUseCase`, `IsFollowingUseCase`, `GetFollowedUsersUseCase`, `GetFollowedPubkeysUseCase`, `WatchFollowedUsersUseCase`.
- UI: scan a user QR (`UniunQrPayload.user`) → `FollowUserUseCase` → drawer's "Followed" section lists them.

**2. Followed Notes (note-graph subscription, unrelated to NIP-02)**
- `FollowedNoteModel` (Isar) — `eventId`, `contentPreview`, `followedAt`, `newReferenceCount`.
- Subscribes to a single note's **reference graph**, not its author. The Gateway opens `{kinds:[1], "#e":["followedNoteId"]}` per followed note — any new Kind-1 that e-tags the target surfaces, regardless of who wrote it.
- `newReferenceCount` is incremented by the inbound handler on each new match; cleared when the user opens the followed-note detail page.
- Use cases: `FollowedNoteRepository.followNote / unfollowNote / clearNewReferences / isFollowed`.

These are orthogonal — following a user does not auto-follow their notes' graphs, and following a note does not imply following its author.

---

## Permanent Exclusions

**NIP-09 (event deletion) is permanently excluded.** Notes are forever — core product principle, not a gap. Never add a `deleted` field, Kind 5 event handling, or any soft-delete mechanism. See "Feed Freedom" under Core Philosophy.

---

## Localization (l10n)

All UI strings go through `AppLocalizations` — never hardcode text in widgets.

**Why:**
- **Translation** — want Hindi or Spanish? Add `app_hi.arb` with the same keys, translated. Flutter picks the right one based on phone language. Zero code change.
- **One place to edit** — want to change "Save & Continue" to "Done"? Change it in `app_en.arb`, updates everywhere instantly.
- **No typos across screens** — "Following" spelled wrong? Fix in one file, fixed on every screen.

**How to use:**
```dart
// In any widget build method:
final l10n = AppLocalizations.of(context)!;
Text(l10n.actionSave)
```

**Adding a new string:**
1. Add the key + English value to `lib/l10n/app_en.arb`
2. Run `flutter gen-l10n` (or `flutter pub get`)
3. Use `l10n.yourKey` in the widget

**Import:** `package:uniun/l10n/app_localizations.dart`

---

## Rules for AI Assistants

### DO

- Work one model/entity/feature at a time. Do not speculatively scaffold future features.
- **File grouping (SOLID SRP)**: Single Responsibility applies at the **class level**, not the file level. Group related classes of the same domain in one file — e.g., `note_usecases.dart` holds all Note use cases, `ai_model_usecases.dart` holds all AI model use cases. This is correct SOLID. Do NOT create one file per use case.
- Use `isar_community` package (import `package:isar_community/isar.dart`). Never `isar`.
- Use `abstract class` for all `@freezed` domain entities (Freezed 3.x requirement):
  ```dart
  @freezed
  abstract class SomeEntity with _$SomeEntity {
    const factory SomeEntity({...}) = _SomeEntity;
  }
  ```
- Keep Isar models mutable (`late` fields, no `@freezed`).
- Keep domain entities immutable (`@freezed abstract class`).
- Derive note role from `rootEventId`/`replyToEventId` — never add a separate `isReply`, `isRoot`, `role`, or `noteRole` field to any model or entity.
- Wrap all Isar writes in `isar.writeTxn(() async { ... })`.
- Return `Either<Failure, T>` from all repository methods and use cases.
- Use `Failure.errorFailure(e.toString())` in catch blocks.
- Check for existing records before inserting (idempotent saves).
- Annotate repository implementations with `@Injectable(as: RepositoryInterface)`.
- Run `build_runner` after any change to `@freezed`, `@collection`, or `@injectable` annotated classes.
- **Prefer bottom sheets over modal dialogs.** Reach for `showModalBottomSheet` (rounded top, drag handle, `AppColors.surfaceContainerLowest`) for input forms, pickers, and option lists — it is the app's default surface for transient UI. Reserve `AlertDialog` / `showDialog` for terse destructive confirmations ("Delete X?" yes/no). When a text field lives in a sheet, wrap it with `isScrollControlled: true` + `MediaQuery.viewInsets.bottom` padding so the keyboard doesn't cover it.
- **Read `test/TESTING.md` BEFORE writing or modifying any test.** It is the canonical testing guide: comment style (one-line factual docstring), `test/_helpers/fixtures.dart` for every entity factory (`aNote`, `aReply`, `aProfile`, `aSavedNote`, `aManas`, `aUserKey`, `aMediaBlob`, `Content.*` payloads, fixed clocks `tT0`/`tNow`, stable pubkeys `kSelfPub`/`kAlicePub`), canonical packages (`bloc_test` + `mocktail` + `get_it` reset pattern, NOT `mockito`), folding edge cases into the original test file (NOT `*_edge_cases_test.dart`), and the eight-row CI shard map. The edge-case checklist there (Unicode, RTL, emoji, boundary, scale, malformed, type-confusion, concurrency, failure paths, idempotency) applies to every new test.
- **Device tests (`integration_test/`) run from a pre-set model, not a download.** `flutter test` uninstalls the app, which wipes a downloaded model, so push it once (`scripts/device_test.sh push-model <file>`, to `/data/local/tmp/uniun_test/`) and call `provisionTestModel(AIModelId.gemma4E2b)` from `integration_test/support/test_model.dart`; run with `scripts/device_test.sh run [file]` (keeps the screen awake, uses `--no-uninstall`). Gemma 4 E2B is the default model. Timing tests need `flutter drive --driver=test_driver/integration_test.dart --profile`. Register every new device test in `integration_test/all_tests.dart`. Usage details: `test/TESTING.md`.

### NEVER DO

- **Hardcode any UI string** — every piece of text shown to the user must come from `AppLocalizations` (l10n). Add the key to `app_en.arb` first, then use `l10n.yourKey` in the widget.
- Add `deleted`, `isDeleted`, `softDeleted`, or any deletion-related field to any model or entity.
- Implement or reference NIP-09 (Kind 5 deletion events).
- Import `package:isar_community/isar.dart` or any Isar type in the domain layer.
- Import Flutter widgets (`package:flutter/material.dart`, etc.) in the domain layer.
- Import Flutter widgets in the data layer.
- Create use cases for operations that do not have a concrete repository method backing them yet.
- Add `Post`, `Comment`, `Thread`, `Upvote`, or any Reddit-style model — everything is a `Note`.
- Add a `PostModel`, `CommentModel`, or any model that does not map to a Nostr event kind.
- Modify generated files (`*.g.dart`, `*.freezed.dart`) — they will be overwritten by `build_runner`.
- Use the old `isar` package — use `isar_community` only.
- Use Freezed 2.x `class` pattern — use Freezed 3.x `abstract class` pattern.
- Access Isar directly from BLoC or use cases — go through the repository interface.
- Hardcode Nostr event IDs or relay URLs.
- Push ranking/algorithm logic into the feed in v1 — chronological only.
- Add any form of cloud AI call — Shiv is entirely on-device.

---

## Common Code Patterns

### Adding a New Isar Model

```dart
// lib/data/models/some_model.dart
import 'package:isar_community/isar.dart';

part 'some_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('SomeName')  // explicit Isar collection name
class SomeModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  // ... other fields
}

extension SomeModelExtension on SomeModel {
  SomeEntity toDomain() => SomeEntity(/* map fields */);
}
```

### Adding a New Domain Entity

```dart
// lib/domain/entities/some/some_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'some_entity.freezed.dart';

@freezed
abstract class SomeEntity with _$SomeEntity {
  const factory SomeEntity({
    required String id,
    // ...
  }) = _SomeEntity;
}
```

### Adding a New Repository Interface

```dart
// lib/domain/repositories/some_repository.dart
import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/some/some_entity.dart';

abstract class SomeRepository {
  Future<Either<Failure, SomeEntity>> getSomething(String id);
}
```

### Adding a New Repository Implementation

```dart
// lib/data/repositories/some_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/some_model.dart';
import 'package:uniun/domain/entities/some/some_entity.dart';
import 'package:uniun/domain/repositories/some_repository.dart';

@Injectable(as: SomeRepository)
class SomeRepositoryImpl extends SomeRepository {
  final Isar isar;
  SomeRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, SomeEntity>> getSomething(String id) async {
    try {
      // ... Isar query
      return Right(result.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
```

### Adding a New Use Case

```dart
// lib/domain/usecases/get_something_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/some/some_entity.dart';
import 'package:uniun/domain/repositories/some_repository.dart';

@lazySingleton
class GetSomethingUseCase extends UseCase<Either<Failure, SomeEntity>, String> {
  final SomeRepository repository;
  const GetSomethingUseCase(this.repository);

  @override
  Future<Either<Failure, SomeEntity>> call(String input, {bool cached = false}) {
    return repository.getSomething(input);
  }
}
```

---

## Folder Structure Reference

Every feature module MUST follow this exact folder pattern (derived from the established codebase convention):

```
feature_name/
├── bloc/        # BLoC classes (bloc, event, state) + .freezed.dart generated files
├── cubit/       # Cubit classes (cubit, state) — use when no events are needed
├── pages/       # Full-screen widgets (one file per screen/page)
├── widgets/     # Reusable UI components scoped to this feature
└── utils/       # Feature-specific helpers, extensions, formatters
```

**Rules:**
- Never put widgets directly in `pages/` and vice versa — keep them separated.
- `bloc/` and `cubit/` are separate folders. Use BLoC when you need events; use Cubit when state transitions are simple.
- Each file does ONE thing. A 500-line page file should be split into page + widgets.
- `utils/` only exists if there are actual helper functions. Don't create it empty.

```
lib/
├── main.dart
│
├── common/                        # Shared across the whole app
│   ├── locator.dart               # get_it DI setup
│   ├── locator.config.dart        # Generated injectable config
│   ├── snackbar.dart              # Global snackbar helpers
│   ├── qr/                        # QR widgets (not feature-specific) — see docs/General/QR_AND_DEEP_LINKS.md
│   │   ├── uniun_qr_card.dart      # UniunQrCard.user()/.publicGroup()/.privateGroup() — no separate "ChannelQrCard" class
│   │   ├── uniun_qr_payload.dart   # UniunQrPayload + UniunQrKind{user,publicGroup,privateGroup,loginSession}
│   │   └── uniun_qr_scanner_page.dart # UniunQrScannerPage (MobileScanner)
│   └── widgets/                   # Truly shared widgets (used by 2+ features)
│       ├── user_avatar.dart
│       └── floating_nav.dart
│
├── core/
│   ├── constants/                 # App-wide constants
│   ├── enum/
│   │   ├── note_type.dart         # NoteType: text | image | link | reference
│   │   ├── message_role.dart      # MessageRole: user | assistant
│   │   ├── outbound_status.dart
│   │   └── relay_status.dart
│   ├── error/
│   │   └── failures.dart          # Failure freezed union
│   ├── extensions/                # Dart extension methods
│   ├── router/
│   │   └── app_routes.dart        # Named route constants (see routes list below)
│   ├── router/
│   │   ├── app_router.dart        # GoRouter declaration + deep-link redirects
│   │   ├── app_routes.dart        # Named route constants
│   │   └── deep_link.dart         # Universal-link host/segments + DeepLink.note(...) builder
│   ├── (QR lives at lib/common/qr/, not core/ — see below)
│   ├── theme/
│   │   └── app_theme.dart         # AppColors, AppTextStyles, ThemeData
│   └── usecases/
│       └── usecase.dart           # UseCase<T,P> and NoParamsUseCase<T> base classes
│
├── data/
│   ├── datasources/
│   │   ├── isar_module.dart       # Isar singleton — all schemas registered here
│   │   ├── isar_schemas.dart      # Schema list extracted for clarity
│   │   └── tostore_module.dart    # ToStore vector DB module
│   ├── models/                    # Isar @Collection models (mutable, no @freezed)
│   │   ├── notes/note_model.dart       # Unified Note collection (all kinds: 1/42/14/15/9023)
│   │   ├── notes/media_attachment.dart # @embedded — one NIP-92 imeta entry on Note.attachments
│   │   ├── media/media_cache_model.dart # sha → localPath + downloadedAt (only media side table)
│   │   ├── profile_model.dart
│   │   ├── user_key_model.dart
│   │   ├── group_model.dart             # Public group metadata only (kind 40/41). @Name('Channel') on disk (pre-rename)
│   │   ├── private_group_model.dart     # Private group metadata only. @Name('PrivateChannel') on disk (pre-rename)
│   │   ├── private_group_join_request_model.dart
│   │   ├── dm/dm_conversation_model.dart
│   │   ├── dm/encrypted_dm_model.dart  # Inbound gift-wrap queue (decrypts into Note)
│   │   ├── shiv_conversation_model.dart
│   │   ├── shiv_message_model.dart
│   │   ├── memory_node_model.dart     # Wiki summaries for GraphRAG
│   │   ├── graph_node_model.dart
│   │   ├── graph_edge_model.dart
│   │   ├── saved_note_model.dart
│   │   ├── followed_note_model.dart
│   │   ├── event_queue_model.dart
│   │   ├── relay_model.dart
│   │   ├── app_settings_model.dart
│   │   ├── ai_model_selection_model.dart
│   │   └── missing_profile_pubkey_model.dart
│   └── repositories/              # Repository implementations (@Injectable)
│
├── domain/
│   ├── entities/                  # Freezed domain entities (immutable, @freezed abstract class)
│   ├── repositories/              # Abstract repository interfaces
│   ├── usecases/                  # Business logic (@lazySingleton, grouped by feature)
│   │   ├── shiv_usecases.dart
│   │   ├── ai_model_usecases.dart
│   │   ├── knowledge_usecases.dart  # graph + memory use cases
│   │   ├── user_usecases.dart
│   │   ├── profile_usecases.dart
│   │   └── ...
│   └── inputs/                    # Input parameter classes for use cases
│
├── l10n/                          # Auto-generated localization
│
├── gateway/                       # Relay sync isolate (owned by this repo, editable)
│   ├── gateway.dart
│   ├── gateway_init_message.dart
│   ├── central_relay_manager.dart
│   └── websocket_service.dart
│
│ ── ── ── FEATURE MODULES (all under lib/features/) ── ── ──
│
└── features/
    ├── onboarding/pages/          # Splash, Welcome, AboutYou, YourIdentityKeys, ImportIdentity
    ├── home/pages/                # HomePage (app shell)
    ├── vishnu/                    # Feed tab
    │   ├── bloc/                  # VishnuFeedBloc (event, state, freezed)
    │   ├── drawer/bloc/           # DrawerBloc
    │   ├── drawer/widgets/        # vishnu_drawer.dart
    │   ├── pages/                 # vishnu_feed_page.dart
    │   └── widgets/               # note_card.dart, feed_filter_chips.dart
    ├── brahma/                    # Create Note tab
    │   ├── bloc/                  # BrahmaCreateBloc
    │   ├── graph/bloc/            # GraphBloc
    │   ├── graph/pages/           # GraphPage, GraphComposePage
    │   └── pages/
    ├── shiv/                      # AI Assistant tab
    │   ├── chat/bloc/             # ShivAIBloc (event, state, freezed)
    │   ├── chat/pages/            # ShivChatPage
    │   ├── chat/tree/...          # ShivBranchTreePage, BranchTreeGraph, NodeActionPanel
    │   ├── chat/widgets/          # ShivHistoryDrawer, ConversationTile, ShivInputComposer (has Manas picker), MessageBubble
    │   ├── composer_chat/         # ComposerChatCubit + Manas picker sheet + in-composer chat panel
    │   ├── generation/            # SHARED substrate: context/ (ManasContextLoader), prompt/ (PromptParts + templates), gana_run.dart, chat_helpers.dart
    │   ├── gana/                  # Autonomous agents: engine/ (GanaEngine, gana_workmanager), form/, dashboard/ (the Gana screen), detail/ (stats + run drop-downs), list/bloc (GanaListBloc), utils/ (formatters, GanaRunError)
    │   ├── nataraj/               # Swipe-deck idea generator (bloc, engine, pages, widgets)
    │   ├── model_select/          # SelectAIModelCubit, AIModelSelectionPage, widgets
    │   ├── pages/                 # ShivPage
    │   └── rag/                   # embedding/ (EmbeddingService) · indexing/ (DocumentIndexer, NoteEmbeddingWorker) · pipeline/ (RagPipeline) · prompt/ (PromptBuilder, PromptBudget) · retrieval/ (VectorSearchService, EnrichedContext)
    │   #  AIModelRunner is at lib/data/datasources/llm/local_llm_runner.dart (NOT shiv/services/)
    ├── thread/                    # Thread view (BFS replies)
    │   ├── bloc/                  # ThreadBloc
    │   ├── pages/                 # ThreadPage
    │   └── widgets/
    ├── groups/                    # Public groups (NIP-28) — renamed from "channels"
    │   ├── create/                # CreateGroupBloc + page
    │   ├── feed/                  # GroupFeedBloc + page + composer
    │   ├── thread/                # thread within a group
    │   └── join/                  # JoinGroupBloc + page — QR and manual ID share one text field
    ├── private_groups/            # Private groups (NIP-29 + MLS) — renamed from "private_channels"
    │   ├── create/                # CreatePrivateGroupBloc + page
    │   ├── join/                  # JoinPrivateGroupBloc + page
    │   └── detail/                # PrivateGroupDetailBloc + page
    ├── dm/                        # Direct messages (NIP-17, UI pending)
    │   ├── create/                # CreateDmBloc + CreateDmPage
    │   └── chat/                  # DmChatPage
    ├── followed_notes/cubit/      # FollowedNotesCubit
    ├── saved_notes/               # SavedNotesCubit + SavedNotesPage
    ├── share/                     # NIP-18 share sheet
    │   ├── bloc/                  # ShareSheetBloc (loads destinations, dispatches share)
    │   ├── pages/                 # ShareSheetPage (modal bottom sheet)
    │   └── widgets/               # DestinationTile, DmDestinationTile, CollapsibleSection
    └── settings/                  # SettingsCubit, EditProfileCubit, StorageCubit + pages/widgets
```

**Named routes** (`lib/core/router/app_routes.dart`):
```dart
splash, welcome, importIdentity, yourIdentityKeys, aboutYou
home, settings, editProfile, privacyPolicy
thread, followedNoteDetail, noteDetail
aiModelSelection, graph, brahmaCreate
groupEntry, createGroup, joinGroup, groupDetail
privateGroupEntry, createPrivateGroup, joinPrivateGroup, privateGroupDetail
savedNotes, createDm, chatDm
scanQr, userProfile
```

Deep-linkable (Universal Links / App Links — host `www.uniun.in`, `lib/core/router/deep_link.dart`):
- `/group/<groupId>` → `groupDetail` (legacy `/channel/<groupId>` still 301s to this — kept for old links in circulation)
- `/private/<groupId>` → `privateGroupDetail`
- `/user/<npub|hex>` → anonymous route (in-app uses `userProfile`)
- `/note/<hex>` → `noteDetail` (used by share)
- Every external deep link carries `?dl=1`; the router's `_deepLinkAuthGate()` checks for an active identity and redirects to `/welcome` if none exists. In-app navigation (no `dl=1`) skips this gate entirely.

External links carry `?dl=1`; redirects gate auth/relay-ensure via `_deepLinkAuthGate()`. In-app navigation skips those checks. Path constants live in `lib/core/router/deep_link.dart` (single source of truth — manifest + AASA + Dart all read the same segments).

---

## Frequently Made Mistakes

1. **Using `class` instead of `abstract class` with `@freezed`** — Freezed 3.x requires `abstract class`. This causes a compile error.

2. **Importing `package:isar/isar.dart`** — The project uses `isar_community`. The original `isar` package will not resolve.

3. **Adding a `deleted` field** — Do not do this. Ever. Not even temporarily. Feed Freedom.

4. **Skipping `build_runner`** — After any change to a `@freezed`, `@Collection`, or `@injectable` class, you MUST run `flutter pub run build_runner build --delete-conflicting-outputs`. The generated files will be out of sync otherwise.

5. **Creating Post/Comment models** — There are no posts or comments. There are only Notes (Kind 1 events). If it's user-created content, it's a Note.

6. **Accessing Isar from a use case or BLoC** — Use cases and BLoC must not import or use Isar directly. Go through the repository interface.

7. **Forgetting `writeTxn`** — All Isar mutations (put, delete) must be inside `isar.writeTxn(() async { ... })`. Reads do not need a transaction.

8. **NIP-10 field confusion** — `eTagRefs` holds ALL e-tag event IDs. `rootEventId` is specifically the e-tag with `"root"` marker. `replyToEventId` is specifically the e-tag with `"reply"` marker. They are not redundant — `eTagRefs` includes all of them plus `"mention"` tags.
