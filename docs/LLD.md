# UNIUN — Low Level Design (LLD)
## Senior Architect Document · Domain Driven Design · Offline-First

---

## Mermaid Class Diagram

```mermaid
classDiagram

    %% ════════════════════════════════════════
    %% PROTOCOL BASE — everything is an event
    %% ════════════════════════════════════════

    class NostrEvent {
        +String id
        +String pubkey
        +int kind
        +List~NostrTag~ tags
        +String content
        +int createdAt
        +String sig
        +toJson() Map
        <<protocol base>>
    }

    %% ════════════════════════════════════════
    %% DOMAIN ENTITIES (local projections of NostrEvents)
    %% ════════════════════════════════════════

    class NoteEntity {
        +String id
        +String sig
        +String authorPubkey
        +String content
        +NoteType type
        +List~String~ eTagRefs
        +List~String~ pTagRefs
        +List~String~ tTags
        +int cachedReactionCount
        +DateTime created
        +bool isSeen
        <<Kind 1 — immutable once signed — no delete, feed freedom>>
    }

    class DraftNoteModel {
        +String localId
        +String content
        +List~String~ referenceIds
        +String? imageUrl
        +List~String~ taggedPubkeys
        +DateTime created
        +DateTime updated
        <<local only — not a Nostr event yet>>
    }

    class SavedNoteModel {
        +String noteId
        +DateTime savedAt
        +String? collectionName
        +List~double~? embedding
        <<local bookmark + RAG embedding index>>
    }

    class ChannelReadStateModel {
        +String channelId
        +String lastSeenEventId
        +int unreadCount
        <<local unread counter per channel>>
    }

    class DMReadStateModel {
        +String conversationId
        +String lastSeenEventId
        +int unreadCount
        <<local unread counter per DM>>
    }

    class NostrProfile {
        +String pubkey
        +String? name
        +String? username
        +String? about
        +String? avatarUrl
        +String? nip05
        +String? walletId
        <<Kind 0 — user IS their pubkey>>
    }

    class NostrChannelView {
        +String channelId
        +String name
        +String? about
        +String? picture
        +List~String~ relays
        +String creatorPubkey
        +bool isMember
        <<Kind 40 local view — NOT an entity>>
    }

    class MessageEntity {
        +String id
        +String content
        +NostrProfile sender
        +String conversationId
        +DateTime created
        +MessageType type
        +bool isRead
        <<Kind 42 channel / Kind 14 DM>>
    }

    class AIModelEntity {
        +String modelId
        +String name
        +String description
        +double sizeGB
        +AIModelType type
        +bool isDownloaded
        +bool isRecommended
        +String quantization
        +int contextWindow
    }

    class AIConversationEntity {
        +int id
        +String title
        +String modelId
        +DateTime created
        +DateTime? updated
    }

    class AIMessageEntity {
        +int id
        +int conversationId
        +String content
        +MessageRole role
        +DateTime created
        +int? tokensUsed
    }

    class ReferenceEdgeEntity {
        +String sourceNoteId
        +String targetNoteId
        +ReferenceType edgeType
        +double weight
        +DateTime created
        <<derived from e-tags>>
    }

    class RelayEntity {
        +String url
        +RelayStatus status
        +bool isConnected
        +DateTime? lastSynced
        +int priority
    }

    %% ════════════════════════════════════════
    %% ENTITY RELATIONSHIPS
    %% ════════════════════════════════════════

    %% Protocol base → domain projections
    NostrEvent --> NoteEntity : kind1
    NostrEvent --> NostrProfile : kind0
    NostrEvent --> NostrChannelView : kind40
    NostrEvent --> MessageEntity : kind42or14

    %% Entity → Entity relationships
    NoteEntity --> ReferenceEdgeEntity : eTags
    NoteEntity --> NostrProfile : resolvedLazily
    SavedNoteModel --> NoteEntity : bookmarks
    DraftNoteModel --> NoteEntity : publishedAs
    MessageEntity --> NostrProfile : sentBy
    MessageEntity --> NostrChannelView : postedIn
    ChannelReadStateModel --> NostrChannelView : tracks
    DMReadStateModel --> MessageEntity : tracks
    AIConversationEntity --> AIModelEntity : uses
    AIConversationEntity --> AIMessageEntity : contains
    RelayEntity --> EmbeddedServer : managedBy

    %% ════════════════════════════════════════
    %% REPOSITORY INTERFACES (Domain Layer)
    %% ════════════════════════════════════════

    class NoteRepository {
        <<interface>>
        +getFeed(GetFeedInput) Either~Failure,List~NoteEntity~~
        +getNote(GetNoteInput) Either~Failure,NoteEntity~
        +publishNote(CreateNoteInput) Either~Failure,NoteEntity~
        +markSeen(noteId) Either~Failure,bool~
        +getNoteReferences(noteId) Either~Failure,List~ReferenceEdgeEntity~~
        +searchNotes(query) Either~Failure,List~NoteEntity~~
    }

    class SavedNoteRepository {
        <<interface>>
        +saveNote(noteId) Either~Failure,SavedNoteModel~
        +unsaveNote(noteId) Either~Failure,bool~
        +getSavedNotes() Either~Failure,List~SavedNoteModel~~
        +getEmbeddings() Either~Failure,List~SavedNoteModel~~
        +updateEmbedding(noteId, vector) Either~Failure,bool~
    }

    class DraftNoteRepository {
        <<interface>>
        +saveDraft(DraftNoteModel) Either~Failure,DraftNoteModel~
        +getDrafts() Either~Failure,List~DraftNoteModel~~
        +deleteDraft(localId) Either~Failure,bool~
        +publishDraft(localId) Either~Failure,NoteEntity~
    }

    class ChannelRepository {
        <<interface>>
        +getChannels() Either~Failure,List~NostrChannelView~~
        +getChannel(id) Either~Failure,NostrChannelView~
        +subscribeChannel(id) Either~Failure,bool~
        +unsubscribeChannel(id) Either~Failure,bool~
        +getChannelFeed(GetChannelFeedInput) Either~Failure,List~MessageEntity~~
        +createChannel(CreateChannelInput) Either~Failure,NostrChannelView~
    }

    class AIRepository {
        <<interface>>
        +getAvailableModels() Either~Failure,List~AIModelEntity~~
        +downloadModel(modelId) Stream~DownloadProgress~
        +deleteModel(modelId) Either~Failure,bool~
        +setActiveModel(modelId) Either~Failure,bool~
        +getActiveModel() Either~Failure,AIModelEntity~
        +sendMessage(AIMessageInput) Stream~String~
        +getConversations() Either~Failure,List~AIConversationEntity~~
        +getConversation(id) Either~Failure,AIConversationEntity~
        +createConversation(modelId) Either~Failure,AIConversationEntity~
        +deleteConversation(id) Either~Failure,bool~
    }

    class RelayRepository {
        <<interface>>
        +getRelays() Either~Failure,List~RelayEntity~~
        +addRelay(url) Either~Failure,RelayEntity~
        +removeRelay(url) Either~Failure,bool~
        +connectRelay(url) Either~Failure,bool~
        +disconnectRelay(url) Either~Failure,bool~
        +publishEvent(NostrEvent) Either~Failure,bool~
        +getRelayStatus(url) RelayStatus
    }

    class MessageRepository {
        <<interface>>
        +getConversations() Either~Failure,List~MessageConversation~~
        +getMessages(conversationId) Either~Failure,List~MessageEntity~~
        +sendMessage(SendMessageInput) Either~Failure,MessageEntity~
        +markAsRead(messageId) Either~Failure,bool~
    }

    class UserRepository {
        <<interface>>
        +importKey(nsec) Either~Failure,NostrProfile~
        +generateKey() Either~Failure,NostrProfile~
        +getProfile(pubkey) Either~Failure,NostrProfile~
        +updateProfile(UpdateProfileInput) Either~Failure,NostrProfile~
        +logout() Either~Failure,bool~
        <<keypair-based — no email/password>>
    }

    class GraphRepository {
        <<interface>>
        +buildGraph(rootNoteId) Either~Failure,GraphData~
        +getLinkedNotes(noteId) Either~Failure,List~NoteEntity~~
        +getBacklinks(noteId) Either~Failure,List~NoteEntity~~
        +addReference(AddReferenceInput) Either~Failure,ReferenceEdgeEntity~
    }

    %% ════════════════════════════════════════
    %% USECASES (Domain Layer)
    %% ════════════════════════════════════════

    class GetFeedUseCase {
        -NoteRepository noteRepository
        +call(GetFeedInput) Either~Failure,List~NoteEntity~~
    }

    class CreateNoteUseCase {
        -NoteRepository noteRepository
        -RelayRepository relayRepository
        +call(CreateNoteInput) Either~Failure,NoteEntity~
    }

    class SaveNoteUseCase {
        -NoteRepository noteRepository
        +call(SaveNoteInput) Either~Failure,bool~
    }

    class GetSavedNotesUseCase {
        -NoteRepository noteRepository
        +call(NoInput) Either~Failure,List~NoteEntity~~
    }

    class SendAIMessageUseCase {
        -AIRepository aiRepository
        +call(AIMessageInput) Stream~String~
    }

    class SelectAIModelUseCase {
        -AIRepository aiRepository
        +call(SelectModelInput) Either~Failure,bool~
    }

    class GetAvailableModelsUseCase {
        -AIRepository aiRepository
        +call(NoInput) Either~Failure,List~AIModelEntity~~
    }

    class BuildNoteGraphUseCase {
        -GraphRepository graphRepository
        +call(BuildGraphInput) Either~Failure,GraphData~
    }

    class AddNoteReferenceUseCase {
        -GraphRepository graphRepository
        +call(AddReferenceInput) Either~Failure,ReferenceEdgeEntity~
    }

    class SyncWithRelayUseCase {
        -RelayRepository relayRepository
        +call(SyncInput) Either~Failure,bool~
    }

    %% UseCase → Repository links
    GetFeedUseCase --> NoteRepository
    CreateNoteUseCase --> NoteRepository
    CreateNoteUseCase --> RelayRepository
    SaveNoteUseCase --> NoteRepository
    GetSavedNotesUseCase --> NoteRepository
    SendAIMessageUseCase --> AIRepository
    SelectAIModelUseCase --> AIRepository
    GetAvailableModelsUseCase --> AIRepository
    BuildNoteGraphUseCase --> GraphRepository
    AddNoteReferenceUseCase --> GraphRepository
    SyncWithRelayUseCase --> RelayRepository

    %% Repository → Entity return type links
    NoteRepository --> NoteEntity : returns
    SavedNoteRepository --> SavedNoteModel : returns
    DraftNoteRepository --> DraftNoteModel : returns
    ChannelRepository --> NostrChannelView : returns
    MessageRepository --> MessageEntity : returns
    AIRepository --> AIModelEntity : returns
    AIRepository --> AIConversationEntity : returns
    AIRepository --> AIMessageEntity : returns
    RelayRepository --> RelayEntity : returns
    GraphRepository --> ReferenceEdgeEntity : returns
    UserRepository --> NostrProfile : returns

    %% ════════════════════════════════════════
    %% BLOCS (Presentation Layer)
    %% ════════════════════════════════════════

    class VishnuFeedBloc {
        -GetFeedUseCase getFeedUseCase
        -SaveNoteUseCase saveNoteUseCase
        +on~LoadFeedEvent~()
        +on~LoadMoreFeedEvent~()
        +on~SaveNoteEvent~()
        +on~VoteNoteEvent~()
        +on~RefreshFeedEvent~()
        +on~UpdateFeedReadPositionEvent~()
    }

    class FeedReadStateModel {
        +String lastReadEventId
        +DateTime lastReadTimestamp
        <<Isar @collection — single row>>
    }

    class BrahmaCreateBloc {
        -CreateNoteUseCase createNoteUseCase
        -AddNoteReferenceUseCase addReferenceUseCase
        -BuildNoteGraphUseCase buildGraphUseCase
        +on~UpdateContentEvent~()
        +on~AddReferenceEvent~()
        +on~RemoveReferenceEvent~()
        +on~SubmitNoteEvent~()
        +on~PreviewReferenceGraphEvent~()
        +on~AttachImageEvent~()
        +on~TagUserEvent~()
    }

    class ShivAIBloc {
        -SendAIMessageUseCase sendMessageUseCase
        -SelectAIModelUseCase selectModelUseCase
        -GetAvailableModelsUseCase getModelsUseCase
        +on~SendMessageEvent~()
        +on~SelectModelEvent~()
        +on~LoadConversationsEvent~()
        +on~CreateConversationEvent~()
        +on~DeleteConversationEvent~()
    }

    class GraphBloc {
        -BuildNoteGraphUseCase buildGraphUseCase
        +on~LoadGraphEvent~()
        +on~FocusNodeEvent~()
        +on~ExpandNodeEvent~()
        +on~CollapseNodeEvent~()
    }

    class DrawerBloc {
        -ChannelRepository channelRepository
        -MessageRepository messageRepository
        +on~LoadChannelsEvent~()
        +on~LoadDMsEvent~()
        +on~OpenChannelEvent~()
        +on~OpenDMEvent~()
    }

    class SavedNotesBloc {
        -GetSavedNotesUseCase getSavedNotesUseCase
        -SaveNoteUseCase saveNoteUseCase
        +on~LoadSavedNotesEvent~()
        +on~UnsaveNoteEvent~()
        +on~FilterSavedNotesEvent~()
    }

    %% BLoC → UseCase links
    VishnuFeedBloc --> GetFeedUseCase
    VishnuFeedBloc --> SaveNoteUseCase
    VishnuFeedBloc --> FeedReadStateModel
    BrahmaCreateBloc --> CreateNoteUseCase
    BrahmaCreateBloc --> AddNoteReferenceUseCase
    BrahmaCreateBloc --> BuildNoteGraphUseCase
    ShivAIBloc --> SendAIMessageUseCase
    ShivAIBloc --> SelectAIModelUseCase
    ShivAIBloc --> GetAvailableModelsUseCase
    GraphBloc --> BuildNoteGraphUseCase
    SavedNotesBloc --> SavedNoteRepository
    BrahmaCreateBloc --> DraftNoteRepository

    %% DrawerBloc → Repository + ReadState links
    DrawerBloc --> ChannelRepository
    DrawerBloc --> MessageRepository
    DrawerBloc --> ChannelReadStateModel
    DrawerBloc --> DMReadStateModel

    %% ════════════════════════════════════════
    %% DATA LAYER — EMBEDDED SERVER
    %% ════════════════════════════════════════

    class EmbeddedServer {
        -RelayConnector relayConnector
        -SyncEngine syncEngine
        -EventQueue eventQueue
        +start() Future~void~
        +stop() Future~void~
        +publishEvent(UniunEvent) Future~void~
        +subscribeToRelay(RelayFilter) void
        +getStatus() ServerStatus
    }

    class RelayConnector {
        -Map~String,WebSocketChannel~ connections
        -List~RelayEntity~ relays
        +connect(url) Future~bool~
        +disconnect(url) Future~bool~
        +publish(RelayEvent) Future~bool~
        +subscribe(RelayFilter) Stream~RelayEvent~
        +reconnectAll() Future~void~
        +getConnectionStatus(url) RelayStatus
    }

    class SyncEngine {
        -IsarDataSource localDB
        -RelayConnector relayConnector
        -EventQueue queue
        +syncFeed() Future~void~
        +processIncomingEvent(RelayEvent) Future~void~
        +queueOutgoingEvent(UniunEvent) void
        +flushQueue() Future~void~
        +resolveConflict(local, remote) NoteModel
    }

    class EventQueue {
        -List~UniunEvent~ pendingEvents
        +enqueue(event) void
        +dequeue() UniunEvent?
        +isEmpty() bool
        +retryFailed() void
        +clear() void
    }

    class CleanupManager {
        -IsarDataSource localDB
        -int retentionDays
        +deleteOldNotes() Future~int~
        +deleteOldChannelMessages() Future~int~
        +fetchOnDemand(eventId) Future~NostrEvent?~
        +runCleanupCycle() Future~void~
        <<retention policy enforcer>>
    }

    class AIModelRunner {
        -FlutterGemmaPlugin gemma
        -String? activeModelPath
        -bool isLoaded
        +loadModel(path) Future~bool~
        +unloadModel() Future~void~
        +run(prompt) Stream~String~
        +isReady() bool
        <<flutter_gemma 0.13.1 — user-selected model>>
        <<Qwen3 0.6B / DeepSeek R1 / Gemma 4 E2B / E4B>>
    }

    %% ════════════════════════════════════════
    %% RAG PIPELINE (Shiv)
    %% ════════════════════════════════════════

    class EmbeddingService {
        -EmbeddingModel model
        +loadModel() Future~bool~
        +embed(text) Future~List~double~~
        +embedBatch(texts) Future~List~List~double~~~
        +isLoaded() bool
        <<converts text to vector>>
    }

    class VectorSearchService {
        +cosineSimilarity(a, b) double
        +topK(queryVector, allVectors, k) List~ScoredNote~
        <<ranks notes by semantic similarity>>
    }

    class PromptBuilder {
        +build(question, relevantNotes, history) String
        +estimateTokens(text) int
        +truncateToFit(notes, maxTokens) List~NoteEntity~
        <<assembles LLM prompt with context>>
    }

    class ScoredNote {
        +String noteId
        +double score
        +NoteEntity note
    }

    %% RAG flow connections
    EmbeddingService --> SavedNoteModel : generates embeddings for
    VectorSearchService --> SavedNoteModel : searches embeddings in
    VectorSearchService --> ScoredNote : returns
    PromptBuilder --> AIModelRunner : feeds prompt to
    SendAIMessageUseCase --> EmbeddingService : 1 embed question
    SendAIMessageUseCase --> VectorSearchService : 2 find relevant notes
    SendAIMessageUseCase --> PromptBuilder : 3 build context prompt
    SendAIMessageUseCase --> AIModelRunner : 4 stream LLM response

    class IsarDataSource {
        -Isar db
        +getNotes(filter) Future~List~NoteModel~~
        +saveNote(note) Future~void~
        +deleteNote(id) Future~void~
        +getChannels() Future~List~ChannelModel~~
        +saveAIMessage(msg) Future~void~
        +getAIConversations() Future~List~AIConversationModel~~
        +getRelays() Future~List~RelayModel~~
        +saveRelay(relay) Future~void~
        +getReferenceEdges(noteId) Future~List~ReferenceEdgeModel~~
    }

    %% Embedded server internal links
    EmbeddedServer --> RelayConnector
    EmbeddedServer --> SyncEngine
    EmbeddedServer --> EventQueue
    EmbeddedServer --> CleanupManager
    SyncEngine --> RelayConnector
    SyncEngine --> IsarDataSource
    SyncEngine --> EventQueue
    CleanupManager --> IsarDataSource
    CleanupManager --> RelayConnector : fetchOnDemand

    %% AIModelRunner links
    AIModelRunner --> AIRepository : usedBy
    AIModelRunner --> IsarDataSource : loadsModelFrom

    %% IsarDataSource used by repositories
    IsarDataSource --> NoteRepository : feeds
    IsarDataSource --> SavedNoteRepository : feeds
    IsarDataSource --> DraftNoteRepository : feeds
    IsarDataSource --> ChannelRepository : feeds
    IsarDataSource --> AIRepository : feeds
    IsarDataSource --> RelayRepository : feeds
    IsarDataSource --> MessageRepository : feeds
    IsarDataSource --> GraphRepository : feeds
```

---

## PART 1 — System Understanding

### What is UNIUN?

UNIUN is a **decentralized, offline-first note network** — a hybrid of:
- **Twitter** → short notes, threads, reactions
- **Obsidian** → knowledge graph, note references, linking
- **Discord/Slack** → channel-based feed, direct messaging, drawer navigation
- **Local AI assistants** → on-device LLMs, no cloud required

### Core Technical Architecture

```
┌──────────────────────────────────────────────────────┐
│  FLUTTER UI (Presentation Layer)                     │
│  Vishnu Feed | Brahma Create | Shiv AI | Drawer     │
└──────────────────────┬───────────────────────────────┘
                       │ reads from
┌──────────────────────▼───────────────────────────────┐
│  ISAR DATABASE (Local Source of Truth)               │
│  Notes · Channels · Messages · AI Conversations      │
└──────────────────────▲───────────────────────────────┘
                       │ writes to
┌──────────────────────┴───────────────────────────────┐
│  EMBEDDED SERVER (Dart isolate — separate team)      │
│  SyncEngine · EventQueue · RelayConnector            │
└──────────────────────┬───────────────────────────────┘
                       │ WebSocket (NIP-01)
┌──────────────────────▼───────────────────────────────┐
│  uniun-backend  (Go relay — Khatru + BadgerDB)       │
│  Event storage · Blossom media · MySQL mirror        │
│  See docs/BACKEND.md for full details                │
└──────────────────────────────────────────────────────┘
                       │ Azure Blob Storage
┌──────────────────────▼───────────────────────────────┐
│  Media Files (images uploaded via Brahma)            │
└──────────────────────────────────────────────────────┘

                       +
┌──────────────────────────────────────────────────────┐
│  AI MODEL RUNNER (On-Device — Shiv)                  │
│  flutter_gemma ^0.13.1 (Qwen3 0.6B / DeepSeek R1 /  │
│  Gemma 4 E2B / Gemma 4 E4B) — user downloads once   │
│  + all-MiniLM-L6-v2 embedding model (bundled ~80MB) │
└──────────────────────────────────────────────────────┘
```

### Key Architectural Principle

> The Flutter UI **never** talks to the relay or API directly.
> It only reads from Isar.
> The Embedded Server syncs with relays and writes to Isar.
> This is what makes the app truly offline-first.

### Architectural Style

**Domain Driven Design (DDD) + Clean Architecture + BLoC**

- **DDD Bounded Contexts:** Note, Channel, AI, Relay, Communication, Identity
- **Clean Architecture:** 3 layers — Data, Domain, Presentation
- **BLoC:** Event-driven reactive state management

---

## PART 2 — Module Breakdown

### Module 1: Vishnu (Notes Feed)

**Responsibility:** Display the note feed, handle reactions, filter by channel, manage feed state.

**Bounded Context:** Note Domain

**Key Classes:**
```
VishnuFeedBloc
  ├── VishnuFeedState (initial | loading | success | failure | refreshing)
  ├── LoadFeedEvent
  ├── RefreshFeedEvent
  ├── FilterByChannelEvent
  ├── SaveNoteEvent
  └── VoteNoteEvent

GetFeedUseCase → NoteRepository → IsarDataSource
```

**Widgets:**
- `NoteCard` — single note display (text/image/link/reference type)
- `NoteCardActions` — vote, save, comment, share
- `ChannelFilterChip` — horizontal filter bar at top
- `NoteCardRenderer` — selects correct renderer by NoteType (Factory pattern)

---

### Module 2: Brahma (Create Note)

**Responsibility:** Create notes, attach images, tag users, reference other notes, show graph preview before posting.

**Bounded Context:** Note Domain + Graph Domain

**Key Classes:**
```
BrahmaCreateBloc
  ├── BrahmaCreateState (idle | composing | referencesAdded | graphPreview | submitting | success | failure)
  ├── UpdateContentEvent
  ├── AddReferenceEvent
  ├── RemoveReferenceEvent
  ├── AttachImageEvent
  ├── TagUserEvent
  ├── PreviewReferenceGraphEvent
  └── SubmitNoteEvent

CreateNoteUseCase → NoteRepository + RelayRepository
AddNoteReferenceUseCase → GraphRepository
BuildNoteGraphUseCase → GraphRepository (for preview)
```

**Widgets:**
- `BrahmaEditorWidget` — rich text editor
- `ReferencePickerWidget` — search and attach note references
- `GraphPreviewWidget` — mini graph before posting
- `ImageAttachmentWidget` — attach/preview images
- `UserTagWidget` — tag search and selection

---

### Module 3: Shiv (AI Assistant)

**Responsibility:** Chat with local AI models, select models, manage conversations, run prompts on-device.

**Bounded Context:** AI Domain

**Key Classes:**
```
ShivAIBloc
  ├── ShivAIState (idle | modelLoading | responding | error | modelSelection)
  ├── SendMessageEvent
  ├── SelectModelEvent
  ├── LoadConversationsEvent
  ├── CreateConversationEvent
  └── DeleteConversationEvent

SendAIMessageUseCase → AIRepository → AIModelRunner
SelectAIModelUseCase → AIRepository → AIModelRunner
GetAvailableModelsUseCase → AIRepository → IsarDataSource
```

**Widgets:**
- `ShivChatPage` — full chat conversation UI
- `ShivMessageBubble` — message with markdown rendering
- `ShivModelSelectorPage` — grid/list of available models
- `ShivModelCard` — model details (size, capabilities, recommended badge)
- `ShivStreamingText` — renders streaming token output

---

### Module 4: Drawer / Communication

**Responsibility:** Slack-like drawer, channels list, direct messages, navigation shortcuts.

**Bounded Context:** Channel Domain + Communication Domain

**Key Classes:**
```
DrawerBloc
  ├── DrawerState (loading | loaded | error)
  ├── LoadChannelsEvent
  ├── LoadDMsEvent
  ├── OpenChannelEvent
  └── OpenDMEvent

ChannelRepository → IsarDataSource
MessageRepository → IsarDataSource
```

**Widgets:**
- `UniunDrawer` — full-screen drawer (Slack-like)
- `ChannelListTile` — channel item
- `DMListTile` — direct message conversation item
- `DrawerSection` — labeled section (Channels, DMs, Shortcuts)

---

### Module 5: Graph (Note Reference Graph)

**Responsibility:** Visualize note connections, expand node, navigate via graph.

**Bounded Context:** Graph Domain

**Key Classes:**
```
GraphBloc
  ├── GraphState (loading | rendered | focused | error)
  ├── LoadGraphEvent
  ├── FocusNodeEvent
  ├── ExpandNodeEvent
  └── CollapseNodeEvent

BuildNoteGraphUseCase → GraphRepository → IsarDataSource
```

**Widgets:**
- `GraphCanvasWidget` — full interactive graph (uses flutter_graph_view or force_directed_graph)
- `GraphNodeWidget` — single node (note)
- `GraphEdgeWidget` — connection line with edge type
- `GraphControlsWidget` — zoom, focus, filter controls

---

### Module 6: Settings / System

**Responsibility:** App settings, relay config, AI model settings, theme, preferences.

**Bounded Context:** Identity Domain + Relay Domain

**Key Classes:**
```
SettingsBloc / UniunBloc (existing)
  ├── theme settings
  ├── font scale settings
  ├── relay settings
  └── AI model preferences

RelayRepository → IsarDataSource
AIRepository → IsarDataSource
```

---

### Module 7: Saved Notes

**Responsibility:** View saved/bookmarked notes, filter by collection.

**Bounded Context:** Note Domain

**Key Classes:**
```
SavedNotesBloc
  ├── SavedNotesState (loading | loaded | empty | error)
  ├── LoadSavedNotesEvent
  ├── UnsaveNoteEvent
  └── FilterSavedNotesEvent

GetSavedNotesUseCase → NoteRepository → IsarDataSource
```

---

## PART 3 — Folder to Responsibility Mapping

### Proposed Folder Structure

```
lib/
├── main.dart                        # App bootstrap + EmbeddedServer.start()
│
├── common/                          # Shared across whole app
│   ├── constants.dart
│   ├── locator.dart                 # DI setup
│   └── widgets/                     # Truly global widgets (avatar, snackbar)
│
├── core/                            # Infrastructure (no business logic)
│   ├── api/                         # HTTP client (Dio)
│   ├── bloc/                        # Global BLoCs (app, user, theme)
│   │   ├── uniun/                   # App-wide settings
│   │   ├── user/                    # Auth state
│   │   └── server/                  # EmbeddedServer state ← NEW
│   ├── constants/                   # Endpoints, keys, status codes
│   ├── enum/                        # Shared enums (SortType, ThemeType etc)
│   ├── error/                       # Failure, Exception classes
│   ├── extensions/                  # Dart extension methods
│   ├── router.dart                  # Navigation (GoRouter)
│   └── theme/                       # Theme cubit
│
├── data/                            # Data Layer
│   ├── datasources/
│   │   ├── local/                   # Isar-based datasources ← per domain
│   │   │   ├── note_local_datasource.dart
│   │   │   ├── channel_local_datasource.dart
│   │   │   ├── ai_local_datasource.dart
│   │   │   ├── relay_local_datasource.dart
│   │   │   └── message_local_datasource.dart
│   │   └── remote/                  # Relay/API datasources
│   │       ├── relay_datasource.dart       # WebSocket relay
│   │       └── ai_model_datasource.dart    # Model download
│   │
│   ├── models/                      # Isar @collection models (DTOs)
│   │   ├── note_model.dart
│   │   ├── channel_model.dart
│   │   ├── message_model.dart
│   │   ├── ai_model_model.dart
│   │   ├── ai_conversation_model.dart
│   │   ├── ai_message_model.dart
│   │   ├── reference_edge_model.dart
│   │   └── relay_model.dart
│   │
│   ├── repositories/                # Repository implementations
│   │   ├── note_repository_impl.dart
│   │   ├── channel_repository_impl.dart
│   │   ├── ai_repository_impl.dart
│   │   ├── graph_repository_impl.dart
│   │   ├── relay_repository_impl.dart
│   │   ├── message_repository_impl.dart
│   │   └── user_repository_impl.dart
│   │
│   └── server/                      # Embedded server ← NEW
│       ├── embedded_server.dart
│       ├── relay_connector.dart
│       ├── sync_engine.dart
│       └── event_queue.dart
│
├── domain/                          # Domain Layer
│   ├── entities/
│   │   ├── note/
│   │   │   └── note_entity.dart
│   │   ├── channel/
│   │   │   └── channel_entity.dart
│   │   ├── message/
│   │   │   └── message_entity.dart
│   │   ├── ai/
│   │   │   ├── ai_model_entity.dart
│   │   │   ├── ai_conversation_entity.dart
│   │   │   └── ai_message_entity.dart
│   │   ├── graph/
│   │   │   ├── reference_edge_entity.dart
│   │   │   └── graph_data_entity.dart
│   │   ├── relay/
│   │   │   └── relay_entity.dart
│   │   └── user/
│   │       └── user_entity.dart
│   │
│   ├── repositories/                # Abstract interfaces
│   │   ├── note_repository.dart
│   │   ├── channel_repository.dart
│   │   ├── ai_repository.dart
│   │   ├── graph_repository.dart
│   │   ├── relay_repository.dart
│   │   ├── message_repository.dart
│   │   └── user_repository.dart
│   │
│   ├── usecases/
│   │   ├── note/
│   │   │   ├── get_feed_usecase.dart
│   │   │   ├── create_note_usecase.dart
│   │   │   ├── save_note_usecase.dart
│   │   │   ├── delete_note_usecase.dart
│   │   │   └── get_saved_notes_usecase.dart
│   │   ├── channel/
│   │   │   ├── get_channels_usecase.dart
│   │   │   ├── join_channel_usecase.dart
│   │   │   └── get_channel_feed_usecase.dart
│   │   ├── ai/
│   │   │   ├── send_ai_message_usecase.dart
│   │   │   ├── select_ai_model_usecase.dart
│   │   │   ├── get_available_models_usecase.dart
│   │   │   └── download_ai_model_usecase.dart
│   │   ├── graph/
│   │   │   ├── build_note_graph_usecase.dart
│   │   │   └── add_note_reference_usecase.dart
│   │   └── relay/
│   │       ├── add_relay_usecase.dart
│   │       └── sync_with_relay_usecase.dart
│   │
│   └── inputs/
│       ├── note_input.dart
│       ├── channel_input.dart
│       ├── ai_input.dart
│       ├── graph_input.dart
│       ├── relay_input.dart
│       └── user_input.dart
│
├── vishnu/                          # Notes Feed Feature
│   ├── bloc/
│   │   ├── vishnu_feed_bloc.dart
│   │   ├── vishnu_feed_event.dart
│   │   └── vishnu_feed_state.dart
│   ├── pages/
│   │   └── vishnu_feed_page.dart
│   ├── widgets/
│   │   ├── note_card.dart
│   │   ├── note_card_actions.dart
│   │   ├── note_card_renderer.dart       # Factory for note types
│   │   └── channel_filter_bar.dart
│   └── utils/
│       └── feed_helpers.dart
│
├── brahma/                          # Create Note Feature
│   ├── bloc/
│   │   ├── brahma_create_bloc.dart
│   │   ├── brahma_create_event.dart
│   │   └── brahma_create_state.dart
│   ├── pages/
│   │   ├── brahma_create_page.dart
│   │   └── brahma_graph_preview_page.dart
│   ├── widgets/
│   │   ├── brahma_editor.dart
│   │   ├── reference_picker.dart
│   │   ├── user_tagger.dart
│   │   └── image_attachment.dart
│   └── utils/
│       └── editor_helpers.dart
│
├── shiv/                            # AI Assistant Feature
│   ├── bloc/
│   │   ├── shiv_ai_bloc.dart
│   │   ├── shiv_ai_event.dart
│   │   └── shiv_ai_state.dart
│   ├── pages/
│   │   ├── shiv_chat_page.dart
│   │   ├── shiv_model_selection_page.dart
│   │   └── shiv_conversations_page.dart
│   ├── widgets/
│   │   ├── shiv_message_bubble.dart
│   │   ├── shiv_model_card.dart
│   │   ├── shiv_streaming_text.dart
│   │   └── shiv_input_bar.dart
│   └── utils/
│       └── ai_helpers.dart
│
├── drawer/                          # Navigation Drawer Feature
│   ├── bloc/
│   │   ├── drawer_bloc.dart
│   │   ├── drawer_event.dart
│   │   └── drawer_state.dart
│   ├── pages/
│   │   └── uniun_drawer_page.dart
│   └── widgets/
│       ├── channel_list_tile.dart
│       ├── dm_list_tile.dart
│       └── drawer_section.dart
│
├── graph/                           # Note Graph Feature
│   ├── bloc/
│   │   ├── graph_bloc.dart
│   │   ├── graph_event.dart
│   │   └── graph_state.dart
│   ├── pages/
│   │   └── graph_page.dart
│   └── widgets/
│       ├── graph_canvas.dart
│       ├── graph_node.dart
│       └── graph_edge.dart
│
├── saved/                           # Saved Notes Feature
│   ├── bloc/
│   │   ├── saved_notes_bloc.dart
│   │   ├── saved_notes_event.dart
│   │   └── saved_notes_state.dart
│   ├── pages/
│   │   └── saved_notes_page.dart
│   └── widgets/
│       └── saved_note_card.dart
│
├── settings/                        # Settings Feature
│   ├── pages/
│   │   ├── settings_page.dart
│   │   ├── relay_settings_page.dart
│   │   └── ai_model_settings_page.dart
│   └── widgets/
│       └── settings_tile.dart
│
└── user/                            # Auth Feature (existing)
    ├── bloc/
    ├── pages/
    └── widgets/
```

---

## PART 4 — Design Patterns

### Pattern 1: Repository Pattern ✅ (Already in use — keep it)

**Where:** All data access (`NoteRepository`, `AIRepository`, `RelayRepository`)

**Why:** UI never directly touches Isar or the relay. All access is via abstracted interfaces.

**Dart direction:**
```dart
abstract class NoteRepository {
  Future<Either<Failure, List<NoteEntity>>> getFeed(GetFeedInput input);
  Future<Either<Failure, NoteEntity>> createNote(CreateNoteInput input);
}

@Injectable(as: NoteRepository)
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;
  // ...
}
```

---

### Pattern 2: Factory Pattern — Note Renderer

**Where:** `vishnu/widgets/note_card_renderer.dart`

**Why:** Notes have different types (text, image, link, reference). Instead of one massive widget with `if/switch`, a factory selects the correct renderer.

**Dart direction:**
```dart
abstract class NoteRenderer extends StatelessWidget {
  final NoteEntity note;
  const NoteRenderer({required this.note});
}

class NoteRendererFactory {
  static NoteRenderer create(NoteEntity note) {
    return switch (note.type) {
      NoteType.text      => TextNoteRenderer(note: note),
      NoteType.image     => ImageNoteRenderer(note: note),
      NoteType.link      => LinkPreviewNoteRenderer(note: note),
      NoteType.reference => ReferenceNoteRenderer(note: note),
    };
  }
}
```

**Do NOT use pattern for:** simple one-type widgets like `SavedNoteCard` — just write a widget directly.

---

### Pattern 3: Strategy Pattern — AI Model Runner

**Where:** `data/server/ai_model_runner.dart`

**Why:** The app supports multiple AI models (llama, mistral, phi, etc). Each may have different loading/inference logic. Strategy lets you swap models without changing BLoC code.

**Dart direction:**
```dart
abstract class AIInferenceStrategy {
  Future<bool> load(String modelPath);
  Stream<String> run(String prompt, List<AIMessageEntity> context);
  Future<void> unload();
}

class LlamaStrategy implements AIInferenceStrategy { ... }
class OllamaStrategy implements AIInferenceStrategy { ... }
class PhiStrategy implements AIInferenceStrategy { ... }

class AIModelRunner {
  AIInferenceStrategy? _strategy;

  void setStrategy(AIInferenceStrategy strategy) {
    _strategy = strategy;
  }

  Stream<String> run(String prompt, List<AIMessageEntity> context) {
    return _strategy!.run(prompt, context);
  }
}
```

---

### Pattern 4: Facade Pattern — Embedded Server

**Where:** `data/server/embedded_server.dart`

**Why:** The embedded server internally manages a `RelayConnector`, `SyncEngine`, and `EventQueue`. This is complex. The rest of the app (BLoC, repositories) should not know this internal complexity. `EmbeddedServer` is the single clean face.

**Dart direction:**
```dart
// Simple public API — hides internal complexity
class EmbeddedServer {
  final RelayConnector _relay;
  final SyncEngine _sync;
  final EventQueue _queue;

  Future<void> start() async {
    await _relay.connectAll();
    _sync.start();
  }

  Future<void> publishNote(NoteEntity note) async {
    _queue.enqueue(NotePublishEvent(note));
    await _sync.flushQueue();
  }
}
```

---

### Pattern 5: Command Pattern — Offline Note Queue

**Where:** `data/server/event_queue.dart`

**Why:** When offline, notes cannot be published to relay immediately. They are queued as commands and flushed when connection is restored.

**Dart direction:**
```dart
abstract class UniunCommand {
  Future<void> execute(RelayConnector connector);
  Map<String, dynamic> serialize();   // for persistent queue
}

class PublishNoteCommand implements UniunCommand {
  final NoteModel note;

  @override
  Future<void> execute(RelayConnector connector) async {
    await connector.publish(note.toRelayEvent());
  }
}

class EventQueue {
  final List<UniunCommand> _pending = [];
  final IsarDataSource _db;

  void enqueue(UniunCommand cmd) {
    _pending.add(cmd);
    _db.persistCommand(cmd);   // survives app restart
  }

  Future<void> flush(RelayConnector connector) async {
    for (final cmd in _pending) {
      await cmd.execute(connector);
    }
    _pending.clear();
  }
}
```

---

### Pattern 6: Adapter Pattern — Relay Protocol

**Where:** `data/datasources/remote/relay_datasource.dart`

**Why:** Different relay implementations may have different wire protocols (Nostr, custom WebSocket, etc). An adapter normalizes them to one interface the app understands.

**Dart direction:**
```dart
abstract class RelayAdapter {
  Stream<RelayEvent> subscribe(RelayFilter filter);
  Future<bool> publish(RelayEvent event);
  Future<void> connect(String url);
}

class NostrRelayAdapter implements RelayAdapter { ... }
class CustomWebSocketAdapter implements RelayAdapter { ... }
```

---

### Pattern 7: Observer Pattern — Sync to UI

**Where:** Implemented via BLoC Streams (already in use)

**Why:** When `SyncEngine` writes new data to Isar, the relevant BLoC must be notified to reload. This is done via BLoC event dispatch or stream watching on Isar collections.

**Dart direction:**
```dart
// Isar supports reactive queries natively
Stream<List<NoteModel>> watchFeed(int channelId) {
  return isar.noteModels
    .filter()
    .channelIdEqualTo(channelId)
    .watch(fireImmediately: true);
}
// VishnuFeedBloc subscribes to this stream
// When SyncEngine writes new notes → UI auto-updates
```

---

### Pattern 8: Singleton — EmbeddedServer + Isar

**Where:** `EmbeddedServer` and `Isar` instance in DI container

**Why:** Only one embedded server should run. Only one Isar instance should exist. Both are registered as `@Singleton` in injectable.

**Dart direction:**
```dart
@Singleton()
class EmbeddedServer { ... }

@Singleton()
Future<Isar> provideIsar() async {
  return await Isar.open([...schemas...]);
}
```

---

### Where NOT to Use Patterns

| Situation | Why Skip |
|---|---|
| `SavedNoteCard` widget | Too simple. Just write a StatelessWidget. |
| `SettingsPage` | No polymorphism needed. Simple BLoC is enough. |
| `DrawerBloc` events | Just 4 events. Factory is overkill. |
| Login/Signup forms | Simple Cubit + form validation is enough. |

---

## PART 5 — Interfaces and Contracts

### Key Input Classes

```dart
// Note Inputs
@freezed class GetFeedInput {
  int? channelId;
  int page;
  SortType sortType;
}

@freezed class CreateNoteInput {
  String content;
  NoteType type;
  int channelId;
  List<String> referenceIds;
  List<String> tags;
  String? imageUrl;
}

@freezed class SaveNoteInput {
  int noteId;
  bool save;
}

// AI Inputs
@freezed class AIMessageInput {
  int conversationId;
  String prompt;
  String modelId;
}

@freezed class SelectModelInput {
  String modelId;
}

// Graph Inputs
@freezed class BuildGraphInput {
  String rootNoteId;
  int depth;    // how many hops to expand
}

@freezed class AddReferenceInput {
  String sourceNoteId;
  String targetNoteId;
  ReferenceType type;
}

// Relay Inputs
@freezed class AddRelayInput {
  String url;
  int priority;
}
```

### Key Enums

```dart
enum NoteType { text, image, link, reference }
enum ChannelType { public, private, dm }
enum MessageRole { user, assistant, system }
enum RelayStatus { connected, disconnected, connecting, error }
enum ReferenceType { quote, thread, mention, backlink }
enum AIModelType { llama, mistral, phi, gemma, custom }
enum ServerStatus { running, stopped, syncing, error }
enum DownloadStatus { idle, downloading, paused, completed, failed }
```

### Key State Shapes

```dart
// Vishnu Feed State
class VishnuFeedState {
  final FeedStatus status;
  final List<NoteEntity> notes;
  final int? activeChannelId;
  final bool hasMore;
  final String? error;
}

// Brahma Create State
class BrahmaCreateState {
  final CreateStatus status;
  final String content;
  final List<NoteEntity> references;
  final String? imageUrl;
  final List<String> taggedUsers;
  final GraphData? graphPreview;
  final String? error;
}

// Shiv AI State
class ShivAIState {
  final AIStatus status;
  final AIConversationEntity? activeConversation;
  final List<AIConversationEntity> conversations;
  final List<AIModelEntity> availableModels;
  final AIModelEntity? selectedModel;
  final String streamingResponse;   // partial token output
  final String? error;
}

// Graph State
class GraphState {
  final GraphStatus status;
  final GraphData? graphData;
  final String? focusedNodeId;
  final double zoom;
  final String? error;
}
```

---

## PART 6 — Scalability and Maintainability

### Offline-First Behavior

- **Single Source of Truth:** Isar is always the data source for the UI — never the relay directly.
- **Write-Ahead Queue:** All outgoing events (new notes, reactions) go into `EventQueue` first, then the relay.
- **Conflict Resolution:** `SyncEngine` uses a `resolveConflict(local, remote)` method. Default strategy: last-write-wins based on timestamp. Customizable via Strategy pattern.
- **Reactive Queries:** Isar's `watch()` means UI auto-refreshes when sync writes new data.

### Multiple AI Models

- New model = new `AIInferenceStrategy` implementation. BLoC and UI code unchanged.
- `AIModelRunner` uses the active strategy — swapped at runtime when user selects model.
- Model download is a separate use case (`DownloadAIModelUseCase`) with progress stream.

### Future Web Support

- All business logic lives in Domain/Data layers (pure Dart) — platform agnostic.
- Replace `AIModelRunner` with API-based inference strategy for web.
- Replace Isar with a web-compatible local DB (like `drift` with SQLite WASM) by swapping the `LocalDataSource` implementation only.
- BLoC, UseCases, Entities — untouched.

### Future Relay Providers

- `RelayAdapter` interface already abstracts protocol differences.
- Add new relay type = add new `RelayAdapter` class. Zero changes elsewhere.

### Future Plugin/Extensions

- Feature modules (`vishnu/`, `brahma/`, `shiv/`) are self-contained.
- New feature = new folder with its own BLoC, pages, widgets, utils.
- Registered in DI via `@injectable` — no manual wiring.

### Testing

```
Unit Test → UseCases (mock repository)
Widget Test → BLoC with mock usecases
Integration Test → Real Isar in-memory + mock relay
```

Each layer is independently testable because of interface abstractions.

---

## PART 7 — Data Flow Examples

### Flow 1: Load Notes Feed

```
User opens Vishnu tab
  ↓
VishnuFeedPage → VishnuFeedBloc.add(LoadFeedEvent())
  ↓
VishnuFeedBloc → GetFeedUseCase.call(GetFeedInput(channelId: null))
  ↓
GetFeedUseCase → NoteRepository.getFeed(input)
  ↓
NoteRepositoryImpl → NoteLocalDataSource.getNotes(filter)
  ↓
NoteLocalDataSource → Isar.noteModels.where().findAll()
  ↓
Returns List<NoteModel>
  ↓
NoteRepositoryImpl.toDomain() → List<NoteEntity>
  ↓
VishnuFeedBloc emits VishnuFeedState(status: success, notes: [...])
  ↓
UI rebuilds with NoteCard list
```

### Flow 2: Create Note (Offline-First)

```
User writes note in Brahma, hits Submit
  ↓
BrahmaCreateBloc.add(SubmitNoteEvent())
  ↓
CreateNoteUseCase.call(CreateNoteInput(...))
  ↓
NoteRepositoryImpl:
  1. Save to Isar immediately (offline-safe)
  2. Call EmbeddedServer.publishNote(note)
     ↓
     EventQueue.enqueue(PublishNoteCommand(note))
     ↓
     if (online) → SyncEngine.flushQueue()
       ↓
       RelayConnector.publish(event)
     else → stays in queue until reconnection
  ↓
NoteRepositoryImpl returns Right(NoteEntity)
  ↓
BrahmaCreateBloc emits success state
  ↓
Router navigates back to Vishnu feed
  ↓
Isar reactive query fires → VishnuFeedBloc auto-refreshes
```

### Flow 3: Send AI Message

```
User types prompt in Shiv, hits Send
  ↓
ShivAIBloc.add(SendMessageEvent(prompt))
  ↓
SendAIMessageUseCase.call(AIMessageInput(conversationId, prompt, modelId))
  ↓
AIRepositoryImpl → AIModelRunner.run(prompt, context)
  ↓
AIModelRunner uses active AIInferenceStrategy (e.g. LlamaStrategy)
  ↓
LlamaStrategy streams tokens back
  ↓
ShivAIBloc receives Stream<String>
  ↓
For each token → emits ShivAIState(streamingResponse: accumulated_text)
  ↓
ShivStreamingText widget rebuilds character by character
  ↓
On stream complete → save full message to Isar via AILocalDataSource
```

### Flow 4: Select AI Model

```
User opens model selection page
  ↓
ShivAIBloc.add(LoadModelsEvent())
  ↓
GetAvailableModelsUseCase → AIRepository.getAvailableModels()
  ↓
AIRepositoryImpl → AILocalDataSource.getModels() from Isar
  ↓
AIModelRunner.getSystemCapabilities() → CPU/RAM check
  ↓
AIRepositoryImpl marks recommended models based on capabilities
  ↓
Returns List<AIModelEntity> with isRecommended flags set
  ↓
UI shows model grid with "Recommended" badge
  ↓
User selects model
  ↓
ShivAIBloc.add(SelectModelEvent(modelId))
  ↓
SelectAIModelUseCase → AIRepository.setActiveModel(modelId)
  ↓
AIModelRunner.setStrategy(strategyFor(modelId))
  ↓
AIModelRunner.loadModel(path)
  ↓
Model ready for inference
```

### Flow 5: Build Reference Graph

```
User opens Graph view (or previewing before post)
  ↓
GraphBloc.add(LoadGraphEvent(rootNoteId: noteId, depth: 2))
  ↓
BuildNoteGraphUseCase.call(BuildGraphInput(rootNoteId, depth))
  ↓
GraphRepositoryImpl:
  1. getLinkedNotes(rootNoteId) → direct references
  2. getBacklinks(rootNoteId) → notes that reference this note
  3. For each found note, repeat up to depth
  ↓
Returns GraphData(nodes: [...], edges: [...])
  ↓
GraphBloc emits GraphState(status: rendered, graphData: graphData)
  ↓
GraphCanvasWidget renders force-directed layout
```

---

## PART 8 — Risks and Improvements

### Risk 1: Embedded Server Lifecycle
**Problem:** The embedded server must survive screen rotations and app backgrounding.
**Solution:** Run it as a Flutter background service (use `flutter_background_service` package) or as an Isolate. Register as Singleton in DI.

### Risk 2: AI Model Memory
**Problem:** Large LLMs (7B+ params) may crash on low-end devices.
**Solution:** `AIModelRunner.getSystemCapabilities()` checks available RAM. Only recommend models that fit. Show warnings for borderline devices.

### Risk 3: Relay Connection Drops
**Problem:** WebSocket connections to relays drop on mobile networks.
**Solution:** `RelayConnector` implements exponential backoff reconnect. `EventQueue` persists to Isar so events survive crashes.

### Risk 4: Graph Performance
**Problem:** A note with hundreds of references creates a huge graph that's unresponsive.
**Solution:** `BuildGraphUseCase` accepts a `depth` parameter (max 3). Paginate node expansion via `ExpandNodeEvent`.

### Risk 5: DI Circular Dependencies
**Problem:** `EmbeddedServer` depends on `SyncEngine` which depends on `IsarDataSource` which might be shared with repositories.
**Solution:** Register `Isar` as a top-level `@preResolve @Singleton`. All other services receive it via constructor injection.

### Improvement 1: Reactive Feed Updates
Instead of polling or manual refresh — use Isar's reactive `watch()` stream in `VishnuFeedBloc`. When `SyncEngine` writes new notes, UI auto-updates with zero manual refresh calls.

### Improvement 2: Drift over Isar for Web
Isar does not support web. For future web builds, abstract `LocalDataSource` interface allows swapping Isar with Drift (SQLite WASM) without touching any domain or presentation code.

### Improvement 3: Note Conflict Resolution Strategy

Make `SyncEngine.resolveConflict()` configurable — start with last-write-wins, allow custom strategies via the Strategy pattern for future CRDT-based conflict resolution.

---

## Core Principles

### Feed Freedom — No Delete
Notes are permanent. Once signed and published, a Nostr event cannot be taken back. UNIUN does not implement NIP-09 deletion, local soft-delete, or hidden flags. The `deleted` field has been removed from `NoteEntity`. This is intentional — the app is built on the idea that speech is permanent and the feed is free.

---

## Resolved UML Updates

All previously pending items have been added to the class diagram:

- **Pending 1** ✅ — `CleanupManager` added as dependency of `EmbeddedServer`, connected to `IsarDataSource` and `RelayConnector` (for on-demand fetch)
- **Pending 2** ✅ — Embedding field lives on `SavedNoteModel.embedding` (not `NoteEntity`). Only saved notes get embeddings. Backfill job needed when embedding model is first installed.
- **Pending 3** — `PrivateGroupModel`, `ChannelPermissionModel` deferred to future scope. Not in current basic app.
- **Pending 4** ✅ — `AIModelRunner` simplified to use `flutter_gemma` package directly. No Strategy pattern needed — single Gemma model via flutter_gemma plugin.
