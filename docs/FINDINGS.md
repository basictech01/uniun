# UNIUN — Architecture Findings

---

## Finding 001 — Unread Message Tracking (Read-State Index)

**Context:** Designing unread count badges for Channels and DMs in the Drawer.

**Initial idea:** Mark all messages as read when user opens a channel. Reset `unreadCount` to 0 on open.

**Problem:** This is not how real messaging apps work. WhatsApp and Telegram only mark a message as read when the user has actually scrolled past it — not just by opening the conversation.

**Decided approach:** Track `lastReadEventId` per channel and per DM instead.

- User opens channel → badge disappears from Drawer, but messages are not yet all marked seen
- As user scrolls → UI reports the last visible message ID to the BLoC
- BLoC updates `ChannelReadStateModel.lastReadEventId`
- `unreadCount` = messages with `createdAt` after `lastReadEventId`
- User scrolls to bottom → `lastReadEventId` = latest message → `unreadCount = 0`
- User leaves mid-scroll → next open resumes from exact position (like Telegram's "you are here" marker)

**Bonus:** "Jump to first unread" feature comes for free from this model.

**Models needed:**
```
ChannelReadStateModel  { channelId, lastReadEventId, unreadCount }
DMReadStateModel       { conversationId, lastReadEventId, unreadCount }
```

**Updated by:** SyncEngine on new incoming message. Read by DrawerBloc for badge rendering.

---

## Finding 002 — Shiv AI: flutter_gemma for On-Device LLM + RAG

**Context:** Choosing an on-device LLM runtime for Shiv (AI assistant with RAG over saved notes).

**Options considered:**
- Custom Strategy pattern with multiple backends (Llama.cpp, Ollama, Phi, Gemma) — over-engineered for v1
- flutter_gemma — Flutter plugin that runs Google Gemma models natively on device via MediaPipe LLM Inference API

**Decided approach:** Use `flutter_gemma` package as the single LLM backend.

- Runs Gemma 2B / Gemma 7B models directly on mobile (no server needed)
- Uses GPU acceleration on both Android (GPU delegate) and iOS (Metal)
- Simple API: `FlutterGemmaPlugin.instance.getResponseAsync(prompt)` for full response, `.getResponseStream(prompt)` for token streaming
- Model file (.bin) bundled in app assets or downloaded on first launch

**Why not Strategy pattern:** For a basic working app, one model backend is enough. Strategy pattern adds complexity with no user benefit until we actually need multiple backends. Can always refactor later.

**RAG flow with flutter_gemma:**
1. User asks question → EmbeddingService converts to vector
2. VectorSearchService finds top-K saved notes by cosine similarity
3. PromptBuilder injects notes into prompt context
4. `flutter_gemma` streams the answer token-by-token

**Model sizes:**
- Gemma 2B — ~1.5GB, runs on any modern phone (4GB+ RAM)
- Gemma 7B — ~5GB, needs 8GB+ RAM devices

---

## Finding 003 — Feed + Chat: Same Scroll Model, Ranking Later

**Context:** Feed (Vishnu) and Chat (Channels/DMs) both need unread tracking + infinite scroll.

**Key insight from discussion:** Feed and Chat work the same way:
- Store `lastReadEventId` — the last thing the user saw
- On open, show from that position
- Scroll down = go back in time through older messages
- Hit the bottom = pull more from relays (Nostr `until` filter for pagination)

**Ranking for v1:** Chronological only. Newest first, scroll back in time. No algorithm.

**Future:** Ranking algorithm will decide what to show first (like Twitter showing "important" instead of "latest"). But that's post-MVP — first build the functioning app with simple chronological feed.

**Decision:** Same `lastReadId` + relay pagination pattern for both Feed and Chat. No separate architecture needed.

---

## Finding 004 — GraphRAG: UNIUN's Knowledge Graph Is Already a RAG Graph

**Context:** Standard vector RAG (Finding 002) retrieves notes by semantic similarity. But UNIUN builds a knowledge graph where notes reference each other via `e` tags, connect via `t` tags (topics), and users connect via follow lists. This graph can be used directly for GraphRAG — no extra extraction needed.

**The key insight:** Standard RAG fails at two things:
- **Multi-hop queries** — "show me everything connected to this idea" — it misses the linking notes between A and C
- **Global queries** — "what are my main themes?" — it can only pull a few chunks, not summarize the whole graph

GraphRAG solves both by traversing edges instead of computing similarity.

**Why UNIUN already has the graph for free:**
- Every `e` tag = note → note reference edge (already in `ReferenceEdgeModel`)
- Every `t` tag = note → topic entity edge
- Every reply thread = directed conversation graph
- Every NIP-02 contact = user → user social edge

These are user-asserted edges — more reliable than LLM-extracted ones.

**How it works at query time (3 steps):**
1. Find seed notes via vector similarity (same as standard RAG)
2. BFS traverse the graph from those seeds — fetch referenced notes, same-tag notes, reply chains
3. Verbalize the subgraph into natural language + inject into Gemma prompt

**Example:**
> User asks "what do I think about stoicism?"
> Vector RAG: returns 3 notes with "stoicism" in text
> GraphRAG: returns those 3 notes + all notes they reference + all notes tagged `#stoicism` + reply threads — full connected context

**v1 approach:** Start with standard vector RAG (already designed). Add graph traversal as a second pass on top — seed from vector, expand via graph. No community detection or heavy infrastructure needed for basic GraphRAG.

**Full technical details:** See `docs/graphrag.md`

---

## Finding 005 — User Identity Storage: Secure Storage + Isar Split

**Context:** Deciding where to store the user's Nostr keypair (nsec + npub) and profile data, and how to handle profile caching for other users seen in the feed.

**Problem with naive approach:** Storing nsec in Isar (a plain file on disk) means the private key is accessible to anyone who can read app storage — no different from a text file. On rooted Android devices this is trivially readable.

**Decided approach:** Split storage by sensitivity:

| Data | Storage | Why |
|------|---------|-----|
| nsec (bech32 private key) | `flutter_secure_storage` → Android Keystore / iOS Keychain | Hardware-backed encryption, survives app updates, wiped on uninstall |
| pubkeyHex + npub | Isar `UserKeyModel` | Public data — safe to store anywhere |
| Own profile (Kind 0) | Isar `ProfileModel` with `isOwn = true` | Never evicted, own identity must always be available offline |

On launch, `SplashPage` calls `UserRepository.getActiveUser()`:
- Reads `pubkeyHex` + `npub` from Isar
- Reads `nsec` from secure storage
- If both exist → `Right(UserKeyEntity)` → navigate to `HomePage` (no login needed)
- If either missing → `Left(notFoundFailure)` → navigate to `WelcomePage`
- On reinstall: Isar wiped + secure storage cleared → user must log in again ✅

**Profile eviction strategy (`isOwn` removed):**

`isOwn` was removed. Own profile is identified by `lastSeenAt = DateTime(3000, 6, 1)` — far enough in the future that CleanupManager's `lastSeenAt < now - 30 days` check never fires. `null` lastSeenAt = never evict (safe default for own profile).

```
Own user      → lastSeenAt = DateTime(3000,6,1)  → kept forever
DM/Channel    → lastSeenAt = null                → kept forever
Feed users    → lastSeenAt updated on view       → evicted after 30 days
Unseen        → not stored at all
```

**No backend needed for auth:** Nostr identity is purely cryptographic. Login = having the private key. Logout = deleting it from secure storage + Isar.

---

## Finding 006 — Followed Notes: Reference-Graph Subscription

**Context:** Designing a "follow a note" feature distinct from saved notes and user following.

**Concept:** "Following a note" means subscribing to its reference graph. When a user follows note A, any future Kind 1 note that includes `["e", noteA_id]` in its tags is surfaced in that note's feed. The user gets notified when new references arrive.

**How it differs from saved notes:**
- **Saved note** — stores content for the AI knowledge graph (Shiv) and personal reference. No network subscription. Static.
- **Followed note** — creates an active subscription. Any note that e-tags the followed note is captured. Dynamic, notification-driven.

**Relay subscription for a followed note:**
```json
{"kinds": [1], "#e": ["<followed_note_event_id>"], "since": <last_check_timestamp>}
```

**Storage (when built):**
- `FollowedNoteModel` (Isar) — one row per followed note: `{ eventId, contentPreview, lastCheckedAt, newReferenceCount }`
- `DrawerBloc` loads this list and shows unread badge (newReferenceCount) per note
- SyncEngine opens the `#e` filter subscription and increments `newReferenceCount` on new hits

**Drawer UI:** "Following" section lists followed notes with a badge count. Tapping opens the reference feed for that note — all notes that have cited it, in chronological order.
