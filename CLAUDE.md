# UNIUN — AI Context & Rules

This file is the single source of truth for any AI assistant working on this codebase. Read it completely before touching any file.

---

## What Is UNIUN?

UNIUN is a **decentralized, offline-first social and knowledge network** built entirely on the Nostr protocol, implemented as a Flutter mobile application. Users create, share, and connect **Notes** — Nostr Kind 1 events — that form both a social feed and a personal knowledge graph. Data is stored locally in an Isar database on the device and synced to the Nostr relay via WebSocket, managed by the EmbeddedServer (a separately maintained sync engine).

The app combines four systems into one: a social feed (Vishnu), a note creation workspace (Brahma), an AI assistant that reasons over the user's saved notes using on-device LLM inference (Shiv), and a public/private messaging layer (Channels + DMs). On-device AI runs via `flutter_gemma ^0.13.1` (user-selected model: Qwen3 0.6B / DeepSeek R1 / Gemma 4 E2B / Gemma 4 E4B) with no cloud API calls. The knowledge graph is not a separate construction — it emerges naturally from the Nostr event graph: every `e` tag is a graph edge, every `t` tag is a topic node, every reply thread is a directed conversation subgraph.

**The relay (`uniun-backend/`)** is a Go service built on Khatru (github.com/fiatjaf/khatru). It stores events in BadgerDB (primary) with optional MySQL mirror. Media blobs (Blossom protocol) are stored on Azure Blob Storage. The Flutter app's EmbeddedServer connects to this relay via WebSocket.

---

## Core Philosophy (NEVER Violate These)

- **Feed Freedom**: Notes are permanent. There is NO delete, NO soft-delete, NO NIP-09 implementation, NO `deleted` field, NO `isDeleted` field anywhere in any model, entity, or repository. Once published to Nostr, a note exists. The app does not pretend otherwise. This is an intentional design decision, not an oversight.

- **Offline-First**: The app works fully without internet. Isar is the source of truth. The UI reads only from Isar, never directly from a relay. EmbeddedServer syncs with relays when connectivity is available and writes results back to Isar.

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
EmbeddedServer (Dart Isolate — RelayConnector + SyncEngine + EventQueue + CleanupManager)
    ↔ WebSocket
Nostr Relay Network
```

**Key components:**
- **Flutter + BLoC**: State management via `flutter_bloc`. Events flow into BLoC, new States flow out to UI via `BlocBuilder`/`BlocListener`.
- **Clean Architecture**: Three strict layers — Data, Domain, Presentation — with unidirectional dependency flow (Presentation → Domain ← Data).
- **EmbeddedServer**: Built and maintained by a separate team. Runs in a Dart isolate. Manages relay WebSocket connections, incoming event processing, outgoing event queue, and retention cleanup. Do not modify EmbeddedServer internals.
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

### Key Technical Decisions (from FINDINGS.md)

**Finding 001 — Unread Tracking via lastReadEventId**:
Unread badges for Channels and DMs are NOT implemented by marking all messages read on channel open. Instead, `ChannelReadStateModel` and `DMReadStateModel` each store a `lastReadEventId`. As the user scrolls, the last visible event ID is reported to the BLoC which updates `lastReadEventId`. `unreadCount = messages with createdAt after lastReadEventId`. This gives scroll-position resume (like Telegram's "you are here" marker) and a "jump to first unread" feature for free. The SyncEngine updates these models when new messages arrive.

**Finding 002 — On-Device LLM via flutter_gemma**:
Shiv uses `flutter_gemma` as the single LLM backend. No Strategy pattern for multiple backends in v1 — that adds complexity with no user benefit. `FlutterGemmaPlugin.instance.getResponseStream(prompt)` for token streaming. Model file is downloaded on first launch (~1.5GB for Gemma 2B, ~5GB for Gemma 7B). Gemma 2B runs on any modern phone with 4GB+ RAM.

**Finding 003 — Feed + Chat Use Same Scroll Model**:
Both the Vishnu feed and Channel/DM chat use the same `lastReadEventId` + chronological pagination pattern. Feed is chronological-only for v1 (no ranking algorithm). Pagination uses Isar's `createdLessThan(before)` cursor pattern. No separate architecture is needed for feed vs chat scroll.

**Finding 004 — GraphRAG: UNIUN's Nostr Graph IS the Knowledge Graph**:
Standard vector RAG retrieves notes by semantic similarity but fails at multi-hop queries and global summarization. GraphRAG solves both by traversing the note reference graph. UNIUN already has this graph for free: every `e` tag is a note→note edge (stored in `eTagRefs`), every `t` tag is a note→topic edge (stored in `tTags`), every reply thread is a directed conversation graph. No LLM entity extraction needed — these are user-asserted edges. v1 approach: seed with vector similarity, then BFS-expand via the graph. See `docs/graphrag.md` for full implementation details.

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

| NIP    | Purpose                                         |
|--------|-------------------------------------------------|
| NIP-01 | Base event format, relay subscription protocol  |
| NIP-10 | Reply threading via e-tag markers               |
| NIP-11 | Relay capability advertisement                  |
| NIP-17 | Private DMs (Kind 14 rumor)                     |
| NIP-28 | Public channels (Kind 40/41/42)                 |
| NIP-44 | Encryption for DMs (ChaCha20 + HMAC-SHA256)     |
| NIP-59 | Gift wrap for private message delivery          |
| NIP-65 | User relay list metadata                        |

### Explicitly NOT Used

| NIP    | Why excluded                                                  |
|--------|---------------------------------------------------------------|
| NIP-09 | Event deletion — intentionally excluded. Feed freedom is a core principle. Never implement. |
| NIP-04 | Legacy DM encryption — superseded by NIP-17 + NIP-44          |

---

## Data Layer

Key files — read these directly rather than relying on this doc:
- `lib/data/models/note_model.dart` — `NoteModel` Isar collection
- `lib/domain/entities/note/note_entity.dart` — `NoteEntity` freezed
- `lib/domain/repositories/note_repository.dart` — repository interface
- `lib/core/error/failures.dart` — `Failure` freezed union
- `lib/core/usecases/usecase.dart` — `UseCase<T,P>` and `NoParamsUseCase<T>` base classes

**Critical field notes (NoteModel):**
- `rootEventId` and `replyToEventId` are NIP-10 threading fields. Both null = top-level feed note.
- `eTagRefs` stores ALL e-tag event IDs including root/reply/mention. `rootEventId`/`replyToEventId` are extracted separately.
- `cachedReactionCount` is denormalized; updated by SyncEngine when Kind 7 reactions arrive.
- `NoteType` enum (`text|image|link|reference`) stored as `EnumType.name` in Isar.

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
| `flutter_bloc`                 | `^8.1.3`    | BLoC state management                                          |
| `bloc_concurrency`             | `^0.2.4`    | Event transformers (droppable, sequential, restartable)        |
| Dart SDK                       | `>=3.2.4 <4.0.0` | Minimum Dart 3.2.4                                        |

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
- Signs note with user's private key. Broadcasts via EmbeddedServer's EventQueue.
- Draft support via `DraftNoteRepository` (local only, not published to relay).

**BLoC**: `BrahmaCreateBloc`
- `UpdateContentEvent`, `AddReferenceEvent`, `RemoveReferenceEvent`
- `AttachImageEvent` → Blossom upload flow
- `TagUserEvent` → adds `p` tag
- `PreviewReferenceGraphEvent` → shows graph before submit
- `SubmitNoteEvent` → sign + enqueue for relay publishing

### Shiv — AI Assistant

On-device AI assistant using GraphRAG over the user's saved notes.

**RAG pipeline (standard vector phase):**
1. User saves a note → `EmbeddingService` converts content to a float vector (`List<double>`, 384 or 768 dimensions) → stored in `SavedNoteModel.embedding` in Isar.
2. User asks Shiv a question → same embedding model converts question to vector.
3. `VectorSearchService` loads all saved note embeddings from Isar into memory → computes cosine similarity → returns top-K `ScoredNote` objects.
4. `PromptBuilder` assembles prompt: system prompt + top-K note contents + user question.
5. `AIModelRunner` (wrapping `FlutterGemmaPlugin`) streams the answer token-by-token via `getResponseStream()`.

**GraphRAG phase (on top of vector):**
- After vector retrieval, BFS-traverse the note graph from seed notes: follow `eTagRefs` edges, collect same-`tTags` notes, pull reply chains.
- Verbalize the subgraph into the prompt context before sending to Gemma.
- Enables multi-hop queries ("find notes connected to this concept") and global queries ("what are my main interests?").

**Why only saved notes:** Regular notes are cleaned up after 7 days by `CleanupManager`. Saved notes are the user's explicit personal knowledge base. Embeddings are only generated on save — not for every note seen.

**Models:**
- Embedding model: `all-MiniLM-L6-v2` (~80MB) or `nomic-embed-text` (~270MB)
- LLM: Gemma 2B (~1.5GB) or Gemma 7B (~5GB) via `flutter_gemma`

**BLoC**: `ShivAIBloc`
- `SendMessageEvent` → RAG pipeline → streaming state updates
- `SelectModelEvent` → `SelectAIModelUseCase`
- `LoadConversationsEvent`, `CreateConversationEvent`, `DeleteConversationEvent`

### Channels — Public Chat (NIP-28)

- Kind 40 = channel creation. The `event.id` of the Kind 40 event **is** the channel ID forever. Never generate a separate channel ID.
- Kind 42 = channel message. Tagged with `["e", kind40_id, relay_url, "root"]`.
- Channel metadata updates via Kind 41 (creator only).
- Unread tracking via `ChannelReadStateModel` (same `lastReadEventId` pattern as feed).
- `DrawerBloc` manages channel list and DM list for the app drawer.
- No private channels in MVP. NIP-28 is public-only.

### DMs — Direct Messages (NIP-17)

- Kind 14 = the actual message content (called a "rumor" — it is UNSIGNED).
- Three-layer encryption: Kind 14 → NIP-44 encrypt → Kind 13 (seal) → NIP-44 encrypt with ephemeral key → Kind 1059 (gift wrap, published to relay).
- Only `["p", recipient_pubkey]` is visible on the relay.
- Subscription filter: `{"kinds": [1059], "#p": ["my_pubkey"]}`.
- Unread tracking via `DMReadStateModel` (same `lastReadEventId` pattern).

### Followed Notes

Subscribing to a note's reference graph — distinct from saved notes (which are for Shiv AI).

- `FollowedNoteModel` stores `eventId`, `contentPreview`, `followedAt`, `newReferenceCount`.
- EmbeddedServer opens `{"kinds":[1],"#e":["followedNoteId"]}` per followed note.
- `newReferenceCount` incremented by SyncEngine on each new match.
- **Cubit**: `FollowedNotesCubit` — `load()`, `followNote()`, `unfollowNote()`, `clearNewReferences()`
- **UX**: The drawer contains a collapsible "Followed Notes" section listing all followed notes with unread badges. Tapping a followed note directly opens `FollowedNoteDetailPage` (no separate list page). There is NO standalone `FollowedNotesPage` or `FollowedNoteFeedPage`.
- **Detail view**: `followed_notes/followed_note_detail/` — cubit (`FollowedNoteDetailCubit`) + page (`FollowedNoteDetailPage`) showing the original note and its incoming references.

---

## EmbeddedServer (External — Do Not Modify)

The EmbeddedServer runs in a Dart isolate and is maintained by a separate team. It is the sync engine between Isar and Nostr relays.

```
EmbeddedServer
  ├── RelayConnector — manages WebSocket connections to multiple relays
  ├── SyncEngine — processIncoming(NostrEvent) → Isar; flushQueue() → relays
  ├── EventQueue — pending outgoing events with offline support
  └── CleanupManager — retention policy enforcement
```

**Relay subscriptions UNIUN opens:**
```dart
// Feed
{"kinds": [1], "authors": [...followedPubkeys], "limit": 50}

// Channel messages
{"kinds": [40, 41, 42], "#e": [channelId], "limit": 100}

// DMs (gift wraps addressed to this user)
{"kinds": [1059], "#p": [myPubkey]}

// Profile metadata
{"kinds": [0], "authors": [pubkey]}

// Followed note references (one per followed note)
{"kinds": [1], "#e": ["followedNoteId"]}
```

**Isar retention policy (enforced by CleanupManager):**

| Note type                          | Retention              |
|------------------------------------|------------------------|
| Kind 1 (regular, not saved)        | 7 days (configurable)  |
| Kind 1 (saved = true)              | Forever                |
| Kind 1 (own note, own pubkey)      | Forever                |
| Kind 42 (channel message)          | 3 days (configurable)  |
| Kind 14 (DM content)               | Forever                |
| Kind 0 (profiles)                  | 30 days, refresh on view|
| AI conversations/messages          | Forever                |

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
- `DrawerBloc` — channels + DMs drawer
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
EmbeddedServer (Dart isolate — separate team)
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
- **EmbeddedServer (Dart isolate — separate team)**: Saves relay events to Isar, manages WebSocket connections, EventQueue for offline sync. Do not modify.
- **uniun-backend/ (Go relay — this repo, `uniun-backend/` folder)**: Khatru-based Nostr relay. Accepts/stores events (BadgerDB primary, MySQL optional mirror). Handles Blossom media uploads via Azure Blob Storage. See `otodo.md` for build roadmap.

**Rule:** Never add direct HTTP calls from Flutter to the relay. Flutter only talks to Isar. The EmbeddedServer handles all relay communication.

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

### Followed Notes (NOT following people)

UNIUN does **not** implement a people-following / social graph in v1. There is no Kind 3 contact list, no follower count, no "following" list of users.

"Following a note" means subscribing to its **reference graph**: any new Kind 1 note that contains `["e", followedNoteId]` is captured and surfaced. This is implemented by:
- `FollowedNoteModel` (Isar) — stores `eventId`, `contentPreview`, `followedAt`, `newReferenceCount`
- `FollowedNoteRepository` — `followNote()`, `unfollowNote()`, `clearNewReferences()`, `isFollowed()`
- EmbeddedServer opens: `{"kinds":[1],"#e":["followedNoteId"]}` per followed note
- `newReferenceCount` is incremented by SyncEngine on each new match; cleared when user opens the feed

---

## What Is Already Built

Core identity, feed, threading, followed notes, settings, and onboarding are all implemented. Key modules:

| Area | Status |
|------|--------|
| Onboarding (welcome, key gen, import, profile setup) | ✅ Done |
| Home shell + floating nav (Vishnu / Brahma / Shiv tabs) | ✅ Done |
| Vishnu feed — BLoC, NoteCard, pagination, save/unsave | ✅ Done |
| Thread view — BFS load, nested replies, reply composer | ✅ Done |
| Followed notes — cubit, detail page, reference graph | ✅ Done |
| Settings — profile edit, identity, storage, style, alerts | ✅ Done |
| SavedNote — full note copy stored in Isar (not just ID) | ✅ Done |
| Brahma create note — BLoC, compose page, graph preview | ✅ Done |
| Channels (NIP-28), DMs (NIP-17), Shiv AI | 🔲 Pending |

**NIP-09 (event deletion) is permanently excluded.** Notes are forever — this is a core product principle, not a gap. Never add a `deleted` field, Kind 5 event handling, or any soft-delete mechanism anywhere in the codebase.

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
- Touch EmbeddedServer internals — that is a separate team's concern.
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
│   └── widgets/                   # Truly shared widgets (used by 2+ features)
│       └── user_avatar.dart
│
├── core/
│   ├── api/                       # HTTP client (Dio) — legacy, not used for Nostr
│   ├── bloc/                      # Global app-level BLoCs
│   ├── constants/                 # App-wide constants, endpoints, keys
│   ├── enum/
│   │   └── note_type.dart         # NoteType: text | image | link | reference
│   ├── error/
│   │   ├── failures.dart          # Failure freezed union
│   │   └── failures.freezed.dart  # Generated
│   ├── extensions/                # Dart extension methods (String, List, DateTime…)
│   ├── router/
│   │   └── app_routes.dart        # Named route constants
│   ├── theme/
│   │   └── app_theme.dart         # AppColors, AppTextStyles, ThemeData
│   └── usecases/
│       └── usecase.dart           # UseCase<T,P> and NoParamsUseCase<T> base classes
│
├── data/
│   ├── datasources/
│   │   └── isar_module.dart       # Isar singleton — all schemas registered here
│   ├── models/                    # Isar @Collection models (mutable, no @freezed)
│   │   ├── note_model.dart
│   │   ├── note_model.g.dart      # Generated
│   │   ├── profile_model.dart
│   │   ├── profile_model.g.dart   # Generated
│   │   └── user_key_model.dart
│   └── repositories/              # Repository implementations (@Injectable)
│       ├── note_repository_impl.dart
│       ├── profile_repository_impl.dart
│       └── user_repository_impl.dart
│
├── domain/
│   ├── entities/                  # Freezed domain entities (immutable)
│   │   ├── note/
│   │   │   ├── note_entity.dart
│   │   │   └── note_entity.freezed.dart
│   │   ├── profile/
│   │   │   ├── profile_entity.dart
│   │   │   └── profile_entity.freezed.dart
│   │   └── user_key/
│   │       ├── user_key_entity.dart
│   │       └── user_key_entity.freezed.dart
│   ├── inputs/                    # Input parameter classes for use cases
│   ├── repositories/              # Abstract repository interfaces
│   │   ├── note_repository.dart
│   │   ├── profile_repository.dart
│   │   └── user_repository.dart
│   └── usecases/                  # Business logic (@lazySingleton)
│       ├── get_feed_usecase.dart
│       ├── get_note_by_id_usecase.dart
│       ├── get_replies_usecase.dart
│       ├── save_note_usecase.dart
│       └── mark_seen_usecase.dart
│
├── l10n/                          # Auto-generated localization
│
│ ── ── ── FEATURE MODULES ── ── ──
│
├── onboarding/                    # Auth + identity setup flow
│   └── pages/
│       ├── splash_page.dart
│       ├── welcome_page.dart
│       ├── about_you_page.dart
│       ├── your_identity_keys_page.dart
│       └── import_identity_page.dart
│
├── home/                          # App shell (ZoomDrawer + tab nav)
│   └── pages/
│       └── home_page.dart
│
├── drawer/                        # Slide-out drawer (channels, DMs, settings nav)
│   ├── bloc/
│   │   ├── drawer_bloc.dart
│   │   ├── drawer_event.dart      # (if separate)
│   │   └── drawer_state.dart
│   └── widgets/
│       └── vishnu_drawer.dart
│
├── vishnu/                        # Feed tab (Kind 1 notes, chronological)
│   ├── bloc/
│   │   ├── vishnu_feed_bloc.dart
│   │   ├── vishnu_feed_event.dart
│   │   └── vishnu_feed_state.dart
│   ├── pages/
│   │   └── vishnu_feed_page.dart
│   └── widgets/
│       └── note_card.dart
│
├── brahma/                        # Create Note tab
│   ├── bloc/
│   │   ├── brahma_create_bloc.dart
│   │   ├── brahma_create_event.dart
│   │   └── brahma_create_state.dart
│   ├── pages/
│   │   └── brahma_create_page.dart
│   └── widgets/
│
├── shiv/                          # AI Assistant tab
│   ├── bloc/
│   │   ├── shiv_ai_bloc.dart
│   │   ├── shiv_ai_event.dart
│   │   └── shiv_ai_state.dart
│   ├── pages/
│   │   └── shiv_page.dart
│   └── widgets/
│
├── channels/                      # Public channels (NIP-28)
│   ├── bloc/
│   ├── pages/
│   └── widgets/
│
├── dms/                           # Direct messages (NIP-17)
│   ├── bloc/
│   ├── pages/
│   └── widgets/
│
└── settings/                      # User settings + profile edit
    ├── cubit/
    │   ├── settings_cubit.dart
    │   ├── settings_state.dart
    │   ├── edit_profile_cubit.dart
    │   └── edit_profile_state.dart
    └── pages/
        ├── settings_page.dart
        ├── edit_profile_page.dart
        └── privacy_policy_page.dart
```

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
