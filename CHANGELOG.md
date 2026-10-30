# Changelog

All notable changes to UNIUN are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.
The `+build` suffix on each version (e.g. `1.1.0+2`) is the Android `versionCode` /
iOS build number — it increases by **1 on every store upload**, even if the user-facing
version is unchanged.

See [docs/RELEASING.md](docs/RELEASING.md) for the full release procedure, and
[docs/AUDIT.md](docs/AUDIT.md) for the technical engineering detail behind each release —
what was actually verified, what broke, and what's still open — that doesn't belong in a
user-facing changelog.

---

## [Unreleased]

### Changed
- **The app is about 145 MB smaller, and long notes are searched through their whole text.** A
  long note is now cut into pieces of up to 700 characters that Shiv searches one by one, so a
  fact at the end of a note is found as well as one at the start. Each piece takes about 2 s to
  index (#296).

---

## [3.2.0] — 2026-10-19

Closes milestone [V3.2](https://github.com/basictech01/uniun/milestone/5). **Shiv is faster
at remembering your notes, answers a Manas question from its documents too, and stops giving
one reply to every question. Deleted notes now really disappear from Shiv.**

### Added
- **A Manas-scoped chat now reaches the documents attached to its notes.** Ask Shiv inside a
  Manas and the PDFs and Word files attached to that Manas's notes are searched and cited by
  page or heading, and documents of other Manases stay out of the answer. A Manas whose
  notes were saved before the embedding queue still puts its newest notes in the prompt
  (#236, thanks to @Mayukhga83 for the first version in #289).

### Changed
- **Embedding a note takes about 2 seconds instead of 12.** Most text (a question, a short
  note, a document passage) now uses a smaller embedding model; only a long note switches
  to the bigger one. Both give the same result, so nothing is re-embedded. The app download
  is about 114 MB larger because it carries both model files (#266).
- **Shiv's AI engine was upgraded to `flutter_edge_ai` 2.3** (the renamed `flutter_gemma`).
  Qwen3 0.6B uses a new model file, so anyone on that model downloads it again (329 MB)
  (#257).
- **Under the hood, the direct-message and private-group code no longer touches the
  database directly.** It goes through the same repositories as the rest of the app,
  keeping each save in one step. Nothing changes on screen (#163).

### Fixed
- **Shiv gave the same answer to every question.** With the small Qwen3 0.6B model, an
  unrelated note was handed to the model for any question and it copied it back. Notes and
  document passages must now really match the question for that model (#199).
- **Deleted notes lingered in Shiv.** Deleting a note now also removes its search vector, its
  summary and its graph links, so old notes no longer take the place of new ones in
  answers (#95, #288).
- **A Shiv reply that ended with no text showed a blank bubble.** It now says "No response
  from the model.", and "stopped" and "interrupted" are translated too (#123).
- **Queued knowledge extraction could stall for minutes on an idle phone** (#287).
- **Removing an unreachable relay in Settings could hang** and leave other removed relays
  open (#281).
- **A failed switch between the two embedding models** could make the note queue drop
  notes; it now keeps them for the next try.

### Under the hood
- **Test coverage rose from 75 % to 80 %** with gateway, relay-transport and widget tests
  and new flow tests; the work found the relay hang above (#283).
- **New tests for the DM and private-group paths:** a real NIP-44 send-and-receive round
  trip, every rejection path, and the MLS group flow, plus device tests for the
  Manas-scoped documents with the real embedder.
- **Known device-test failures were written up, not hidden:** the Vishnu feed case of the
  Manas membership test (#300) and the blank-picture OCR case (#301) fail on a phone that
  already holds notes or labels a blank image.

### All 12 issues in milestone [V3.2](https://github.com/basictech01/uniun/milestone/5)
| # | What it was | Where it landed |
|---|---|---|
| #94 | Own saved notes embedded again | Closed, out of scope: you can no longer save your own notes |
| #95 | Embedded notes were not removed with the note | Fixed (same cause as #288) |
| #123 | No "thinking" dots or stop button; blank reply bubble | Fixed: "No response from the model." |
| #139 | iOS crash in Nataraj and Ganas | Closed, not reproduced; a guard test was added |
| #163 | Domain layer imported Isar directly in 3 files | Changed: DM and private-group code use repositories |
| #199 | Shiv gave one reply to every question | Fixed |
| #236 | A Manas chat should reach its notes' documents | Added |
| #257 | Move from `flutter_gemma` to `flutter_edge_ai` | Changed |
| #266 | Faster note embedding | Changed: about 2 s instead of 12 |
| #281 | Relay disconnect hung when it never connected | Fixed |
| #287 | Queued extract stalled for minutes | Fixed |
| #288 | Deleted vectors still returned by search | Fixed |

---

## [3.1.0] — 2026-10-11

Closes milestone [V3.1](https://github.com/basictech01/uniun/milestone/4). **Gujarati and
Japanese are here, Shiv can look at a photo you attach, chats open where you left off, and
Ganas get a dashboard and a choice of what they know.**

### Added
- **Gujarati and Japanese.** Pick either from the language picker; Hindi is now complete too
  (#203, #227).
- **Ask Shiv about a photo.** With a vision-capable model (Gemma 4 E2B or E4B) you can attach
  a picture to a chat message and ask about it (#255).
- **A dashboard for Ganas.** One screen with totals, the Ganas that need attention, how each
  one has been doing, and the full reason behind a failed run (#87).
- **Ganas can use all of Brahma, a single Manas, or no knowledge at all.** Choose "No
  knowledge" for a Gana that doesn't need your notes. Picking Brahma with a cloud model now
  warns you that your notes are sent to that model (#262).
- **Chats open where you left off.** Public groups, private groups and DMs open at the first
  note you haven't read, under a "New notes" line, and the jump-to-latest button shows how
  many are waiting (#201).
- **New replies in a followed note are easy to find.** A reply to a reply now counts, the
  note shows "New", and the notes above it show "New reply inside" so you can follow the
  trail down (#201).
- **A logout option to keep your downloaded AI models** for the next account (#251).
- **Public and private groups show an unread count in the drawer**, like DMs do (#201).

### Changed
- **Every note you save now gets embedded, and none is skipped.** A note is put in a queue
  and embedded one at a time, so closing the app, a crash, or an AI that isn't ready yet no
  longer loses it: it is picked up again and made searchable later. A question you ask Shiv
  goes ahead of that queue instead of waiting behind it (#231). Notes saved before this
  version are not re-embedded automatically.
- **Notes are found more reliably.** Search over your notes used to miss many of them once
  you had more than about a hundred; the search index was upgraded and it now finds them
  (#232). The vector size now matches what the embedding model produces (#234).
- **The note-search database now runs in its own background isolate**, off the main
  thread, so saving and searching notes no longer makes scrolling stutter (#232).
- **A new Gana starts on Brahma**, so you can save one without first creating a Manas (#262).

### Fixed
- **The notification dot stayed on after you read a chat.** Notes are now marked read as
  they appear on screen, so reading a few and going back leaves the right count (#201).
- **Logging out didn't fully reset the account.** Notes, DMs, media, AI choices and sign-ins
  from the previous account are cleared before the next one signs in (#251).
- **Creating a Manas from a Gana said "Gana not found"** even though the Manas was created,
  and lost what you had typed. Your draft is kept now (#262).
- **The Manas check mark in the graph followed the wrong note** after selecting another one
  (#261).
- **The app version in the privacy footer was stale** ("v1.0.0-beta"); it now shows the
  installed version in every language.
- **Gana cards overflowed on narrow screens and large text.**

### Under the hood
- **A new build pipeline checks Android, iOS and Windows.** Every pull request to `main`,
  every push to `main` and a nightly run now build the real app as a release for all three
  (Android App Bundle, iOS without code-signing, Windows). They run side by side, so one
  failing platform doesn't hide the others, and a summary check reports the result. Gradle,
  CocoaPods and native-library breakage now show up before a release, not on someone's
  machine (#268).
- **The test pipeline checks more.** Static analysis now also covers the on-device tests
  (`integration_test/`), so one that stops compiling fails the pull request, and test
  coverage is reported on every pull request (#253).
- **Device tests start from a pre-pushed AI model** instead of downloading one each run, the
  scheduler device tests that had never really run were fixed, and the device-test script
  now says clearly that a test is running (#258, #260).
- **The note vector store is stamped with a format version,** so a future search-index
  upgrade can never read an old store as empty (#232).

### All 14 issues in milestone [V3.1](https://github.com/basictech01/uniun/milestone/4)
| # | What it was | Where it landed |
|---|---|---|
| #87 | Dashboard for Ganas | Added |
| #201 | The notification dot took too long to clear | Fixed, plus chats open at the first unread |
| #203 | Gujarati language | Added |
| #227 | Japanese language | Added |
| #231 | Notes with no vector were never embedded later | Changed: every note is queued and embedded |
| #232 | Version-stamp the vector store path so an upgrade can't read empty | Changed: search index upgrade, own isolate, format version |
| #233 | Rebuild path for orphaned chunk vectors | Closed, not needed: documents use exact search since 3.0.0 |
| #234 | Declared embedding size didn't match the model | Changed: now matches (768) |
| #240 | Images in Shiv's search: the text inside attached images | Shipped in 3.0.0 (tracked in this milestone) |
| #251 | Logout didn't fully reset the previous account | Fixed, plus the keep-models option |
| #255 | Attach an image in Shiv chat for vision models | Added |
| #260 | Scheduler device tests failed only because of how they were written | Under the hood |
| #261 | Manas check mark followed the wrong note | Fixed |
| #262 | Creating a Manas from a Gana said "Gana not found"; Brahma scope | Fixed, plus Brahma and no-knowledge scopes |

---

## [3.0.0] — 2026-10-04

The biggest release so far. **Shiv can now read your documents and photos** — PDFs, Word
files, scans and pictures — and tell you exactly where an answer came from. The knowledge
graph has been rebuilt to feel like Obsidian's, and any note can now be translated.

### Added
- **Shiv answers from your PDFs and Word documents.** Attach one to a note (or save the
  note) and ask Shiv about it. Every answer shows its source: the page of a PDF or the
  heading of a Word file.
- **Tap a source to jump straight to it.** A PDF opens on the cited page with the passage
  highlighted; a Word file opens on the cited section, with its tables and large pictures.
  "Open in another app" is still one tap away.
- **Scanned pages and photographed documents are read on the phone.** Shiv reads English and
  Hindi text in scans, in pictures pasted into a document, and in photos — and only reads
  the pages that actually need it, so typed documents stay fast.
- **Photos without text are found by what they show**, such as "a dog on a beach".
- **Translate any note** into another language with the on-device AI.
- **Graph search and connection stepper.** Search the graph, fly to a match, and step
  through a note's connections one by one.
- **Saving a draft is now the main action when writing a note in Brahma.**
- **Hindi and Hinglish questions find the right passage more often.** Numbers, names and
  codes in your question now count alongside meaning, and Hindi spelling and digit
  variants are treated as the same word. Contributed by Mayukhga83.

### Changed
- **The graph has been redesigned after Obsidian's.** Clearer, visible links that light up
  around the note you select; nodes that spread out cleanly instead of tangling; drag any
  node and its neighbours follow, then settle when you let go; and large graphs open
  already laid out and fitted to the screen.
- **Document search is now exact.** Shiv can find a passage anywhere in your documents —
  previously only a fraction of stored passages could ever be found.
- **The on-device AI uses the phone's graphics chip on Android**, making the first word of
  an answer appear about 2.5× sooner on the phone it was measured on. The AI engine was
  updated to the latest version.
- **Model downloads keep going in the background on Android**, with a notification.

### Fixed
- **Replying to a note from the graph's note panel didn't refresh the graph** — it does now.
- **Reloading the graph while viewing a Manas silently dropped you out of it**, and adding
  or removing a note from that Manas didn't update the graph. Both fixed.
- **Some graph nodes could not be tapped.** Taps now land on the node under your finger,
  even for nodes far from the centre or while the layout is still moving.
- **Shiv sometimes repeated its own prompt** ("Shiv:" or "/no_think") at the start of an
  answer.
- **If the phone's graphics chip couldn't run the AI model, the app retried the same thing
  instead of falling back to the processor** — it now switches properly.

---

## [2.3.0] — 2026-08-13

A reliability-focused release for Shiv, Nataraj, and Ganas — plus QR sign-in for the
web and automatic on-device storage cleanup.

### Added
- **QR sign-in for the web.** Approve a browser login by scanning a QR code from a phone
  that's already signed in — no password, no key to paste.
- **Leftover model file cleanup.** The model picker can now detect and remove stray or
  partial model files left behind by an interrupted download or an earlier app version,
  reclaiming storage that was previously invisible to the app.
- **Ganas can now run on a UNIUN Cloud model**, pinned per-agent independently of
  whichever model the rest of the app is using — in both the foreground and while the
  app is closed in the background (#162).

### Changed
- **Onboarding interest picker now loads its list from UNIUN's backend**, so new
  suggested accounts can be added without an app update. Shows a proper loading/retry
  state instead of a fixed in-app list.
- **Model selection is now one consistent picker used everywhere** — Shiv chat,
  Nataraj, and Gana previously each had their own different, inconsistent model
  picker; there's now a single shared sheet across all three (#158, #161).
- Updated the on-device AI engine (`flutter_gemma`) to the latest version for improved
  reliability under sustained use (#149).

### Fixed
- **Model pickers (Shiv chat, Gana) were showing a model's internal routing id to
  users** — now only ever show the friendly display name.
- **Nataraj could show a misleading "AI model couldn't run on this device" error**
  even when the model was working fine and simply didn't come up with a usable idea
  for one note combination — now shows an honest "no idea this time, try again"
  message instead.
- **Switching your on-device AI model didn't always take effect immediately** —
  the app could keep quietly generating with the old model until restarted (#160).
- **Switching or deleting an AI model while a chat or idea generation was still in
  progress could cause errors.** Model changes now wait for or safely interrupt
  in-progress generation instead of racing it (#167).
- **Ganas with no specific model pinned now correctly follow whichever AI backend
  (on-device or cloud) is currently active** — previously they always assumed
  on-device and would silently do nothing if cloud was selected.
- **Cloud-based idea and agent generation could occasionally hang indefinitely, or
  fail without a clear error, when two requests overlapped** — fixed (#166).
- **Empty, abandoned Shiv conversations no longer clutter your chat history** (#159).
- **Leaving a Shiv chat while the AI was still replying no longer leaves a
  permanently blank response** — whatever had been generated (or a note that it was
  interrupted) is saved when you come back.
- A small accuracy improvement to Shiv's on-device knowledge-graph search: it could
  occasionally count the same connection twice, using up a slot that could have
  surfaced a genuinely new one (#144).

---

## [2.2.0] — 2026-08-02

This release expands UNIUN's inference, identity, and offline networking capabilities.

### Added
- **UNIUN cloud inference.** Use hosted AI models from Shiv with built-in model selection,
  credit usage, and mobile payment support alongside on-device inference.
- **QR identity recovery.** Sign in on another device by scanning a secure QR code instead of
  manually transferring identity credentials.
- **Offline mesh sync.** Nearby devices can discover each other over local transports and securely
  synchronize notes, follows, groups, Manas collections, Ganas, and other user-owned data.
- **Surrounding notes.** Discover notes shared by nearby mesh peers in a dedicated feed.

### Changed
- Onboarding interest recommendations are now loaded from UNIUN's service so suggested accounts
  can be updated without an app release.
- Expanded repository, gateway, mesh, and integration test coverage.

### Fixed
- Improved cloud-model selection, credit accounting, inference UI, login, and sync reliability.

## [2.1.0] — 2026-07-03

A follow-up release focused on **theming**, **reliability of the followed-notes badge**, and a
significant expansion of the test suite.

### Added
- **Dark mode.** Full dark theme across every screen and component, with a new theme system built
  on `AppCustomColors` and a `ThemeCubit`. A **theme-mode setting** (System / Light / Dark) is
  available in Settings and persists across launches via `AppSettingsStore`. All shared widgets —
  note cards, composer, floating nav, QR views, thread views, drop indicators, media views, etc. —
  were updated to use theme-aware colors instead of hard-coded values.
- **Broader test coverage.** New tests for the theme system (`AppThemeMode`, `ThemeCubit`, theme-mode
  persistence, Settings theme row), the media pipeline (`BlossomClient`, `MediaCacheDataSource`,
  `MediaRepositoryImpl`, media use cases, gallery/detail cubits, media tile & settings row, and an
  end-to-end media pipeline integration test), and additional common-layer tests.

### Changed
- **Followed-notes badge is now derived from unread rows.** The unread-reference indicator on
  followed notes is computed directly from the unread rows rather than a cached counter, so the
  badge stays consistent with what the user actually sees.

### Fixed
- CI pipeline fix.
- Blossom media-upload failure path hardened, with matching backend `DEPLOY.md` guidance.

---

## [2.0.0] — 2026-06-30

A major release: the public **Channels** feature is now **Groups**, the app gets a visual
redesign, and UNIUN goes **multilingual** with full Hindi support.

### Added
- **Multi-language support — English + Hindi.** UNIUN can now run fully in **Hindi** (हिन्दी,
  Devanagari). An in-app language switcher is available on the welcome screen (a quick EN / हिन्दी
  toggle), on a dedicated **language-selection page**, and in **Settings**; the choice persists
  across launches. Several more languages are listed as "coming soon". *(The Hindi translation is
  machine-generated and pending native-speaker review.)*
- **Onboarding interest picker.** After creating an identity, new users pick topics they care about;
  UNIUN batch-follows a set of house accounts in a single transaction (one Kind-3 contact-list
  republish) so the feed is alive from the first scroll instead of empty.
- **Reporting & content moderation (NIP-56).** Users can file **Kind 1984** reports on notes and
  users (nudity, spam, impersonation, illegal content, etc.), optionally block the author in the
  same step, and review their own report history. Reporting a note also tombstones it locally so it
  leaves the reporter's feed and threads.

### Changed
- **Channels are now "Groups".** The public-chat feature was renamed **Channel → Group** across the
  entire app — UI, all strings, and the codebase — while preserving existing on-device data.
  ("Group ID" terminology is kept where users copy/share identifiers.)
- **Redesigned application.** A broad visual refresh across the app's screens and components.
- **Smarter on-device AI scheduling.** Improvements to the inference scheduler that arbitrates chat,
  foreground, knowledge-extraction, and background (Gana / Nataraj) AI work so the device stays
  responsive under contention.
- **Apple App Store compliance.** Edit-profile, Gana, and header fixes plus the other changes
  required to pass App Store review; the companion website was shipped.

### Fixed
- Direct thread replies that were missing their NIP-10 reply marker.
- Shiv UI not refreshing in some states.
- Draft deep-link handling.
- Assorted bug fixes and background-worker stability improvements.

---

## [1.3.0] — 2026-06-24

### Added
- **Manas — scoped note collections.** Users can group their notes into named **Manas** and use
  them to scope where AI looks. Picking a Manas narrows Shiv's RAG retrieval, Gana's input pool,
  and the composer-chat context to just that collection (falling back to the whole library when
  none is selected). Manas search now includes drafts and the user's own notes.
- **Nataraj — AI swipe-deck idea generator.** A swipe deck that synthesizes 2–3 of the user's own
  notes into a single new note suggestion, reusing the on-device generation substrate. Cards are a
  local cache, not Nostr events. (Shipped as "Manthan", renamed to **Nataraj** before release.)
- **Gana — autonomous AI agents.** User-owned agents that watch an input surface, infer over
  selected Manas(es), and autonomously publish. Includes scheduled/background generation
  (own isolate + own Isar) and a foreground engine. The trigger config was collapsed into a single
  **"When should this run?"** preset radio (five presets covering the trigger matrix).
- **Composer-chat — inline AI in the composer.** Tap the avatar in any composer (thread / channel /
  DM / private channel) to pick a Manas and chat with an on-device model grounded in the surface's
  recent messages plus the selected Manas.
- **Embed-by-value note sharing with full-note composer.** The share sheet now carries the original
  note **by value** as a self-contained `embeddedNoteJson` snapshot (no `q`/`k`/`p` pointer, no Isar
  lookup, retention-immune) and lets the user author a full note — text, references, and images —
  alongside the embed. The snapshot's signature is verified once at inbound; failures render an
  "unverified" badge.
- **Receive shares from other apps into UNIUN.** UNIUN now registers as a system share target, so
  content shared from other apps lands in the composer.
- **DM replies.** Direct messages support replying to a specific message.
- **OpenRouter (cloud) LLM backend, opt-in.** A backend-agnostic `LlmRepository` now dispatches
  between the on-device `localGemma` runner and a remote **OpenRouter** backend; API keys are stored
  in `flutter_secure_storage` (Keychain / Keystore), never in Isar or SharedPreferences.
- **Media attachments in drafts + BlurHash placeholders** for smoother image loading.
- **"How it works" intro carousel** on the onboarding entry screen.
- **Reddit-style source attribution** shown in Shiv answers.
- **Configurable recent-sync window.** History sync from relays can be capped to a configurable
  recent window to limit how far back the Gateway pulls.
- **Dockerized backend.** The Go relay (`uniun-backend/`) now ships with a Docker setup for
  reproducible deployment.

### Changed
- **On-device AI generation moved to the main isolate** (off the dedicated isolate) for the
  foreground path, with a UI performance pass across onboarding and the feed.
- **Per-user cap on AI note generation** plus assorted generation-flow UI improvements.
- Removed the color picker from Manas.
- Updated `flutter_gemma`.

### Fixed
- Shiv: sanitize the live-streaming message bubble and anchor the Shiv persona near the question.
- Guard against `add`/`emit` after BLoC close during long LLM generation (no more
  "emit after close" crashes on slow inference).
- Saved-note logic bugs.
- Manas search missing drafts and own notes.
- Background worker stability fixes.

---

## [1.1.0] — 2026-06-17

### Added
- **Media support (images, video, files).** Notes, channel messages, DMs, and private-channel
  messages can now carry attachments. Uploads go through the **Blossom** content-addressed
  blob store (BUD-01), and each attachment is described on the event with a NIP-92 `imeta`
  tag. Attachments are stored on `NoteModel.attachments` and joined to on-device files by
  SHA-256 via `MediaCacheModel`.
- **Save media to device.** Media blobs referenced by a note can be downloaded and persisted
  to local storage; the gallery lets the user remove them again (user-driven, no automatic GC).
- **Markdown rendering** for note text.

### Changed
- **Redesigned welcome / front page.** The onboarding entry screen was reworked for a cleaner
  first-run experience. (Design spec: `docs/ui-ux/2026-06-17-welcome-screen-redesign-design.md`.)
- **Shiv (AI) ignores raw media.** The RAG pipeline no longer feeds media payloads into the
  model, so on-device inference stays focused on note text.
- General UI polish across the feed, media viewer, and back-button behaviour.

### Fixed
- DM and feed bugs — channel routing issue, feed/DM sync glitches, and assorted general bugs.
- DeepSeek R1 model failing to load/run.
- Production builds no longer upload debug logs.

---

## [1.0.0] — Initial release

First public release of UNIUN — a decentralized, offline-first social and knowledge network
built on the Nostr protocol.

### Added
- **Vishnu** — chronological Kind 1 note feed with offline-first Isar storage and unread tracking.
- **Brahma** — note composition and publishing, with reference (graph-edge) support and drafts.
- **Shiv** — on-device AI assistant (`flutter_gemma`) running GraphRAG over the user's saved notes,
  with no cloud calls.
- **Channels** — public chat (NIP-28: Kind 40 create / 41 metadata / 42 message) with QR join.
- **Private channels** — encrypted group messaging with admin-controlled membership.
- **DMs** — private direct messages (NIP-17 / NIP-44 encryption).
- **Saved notes** and **followed notes** (subscribing to a note's reference graph).
- **Sharing** — NIP-18 quote/share across feed, channels, and DMs.
- Nostr identity onboarding (key generation + import), local-only private key storage.

[2.0.0]: #130--2026-06-30
[1.3.0]: #114--2026-06-24
[1.1.0]: #110--2026-06-17
[1.0.0]: #100--initial-release
