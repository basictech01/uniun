<p align="center">
  <img src="assets/images/uniun-logo.png" alt="UNIUN" width="120" />
</p>

# UNIUN

[![Tests](https://github.com/basictech01/uniun/actions/workflows/tests.yml/badge.svg)](https://github.com/basictech01/uniun/actions/workflows/tests.yml)
[![Builds](https://github.com/basictech01/uniun/actions/workflows/builds.yml/badge.svg)](https://github.com/basictech01/uniun/actions/workflows/builds.yml)
[![codecov](https://codecov.io/gh/basictech01/uniun/graph/badge.svg)](https://codecov.io/gh/basictech01/uniun)

> *Your notes, your network, your identity.*
>
> A decentralized, offline-first social and knowledge network on the Nostr protocol —
> with an on-device AI that reasons over your own mind.

**UNIUN is live today.** Get it on the
[App Store](https://apps.apple.com/in/app/uniun/id6778077321) or
[Google Play](https://play.google.com/store/apps/details?id=in.uniun.app), or learn more at
[uniun.in](https://www.uniun.in/). No account needed — your identity is a keypair you generate
on first launch. Available in English, Hindi, Gujarati and Japanese.

## We are nothing but the sum of our thoughts

Give every one of your thoughts to another person — every belief, every connection between
ideas, every way you weigh one thing against another — and that person becomes you. They would
decide what you would decide. You would have made a perfect copy of yourself.

That copy is immortality. It is, quietly, what the whole species has always been fighting for.
**You die twice: once when you stop speaking, and again when people stop speaking about you.**
A faithful copy of your mind never stops speaking.

This is what we believe the AI race is actually about. Not chatbots, not productivity — **a way
to replicate yourself.** Call it an assistant, an agent, a model; the goal underneath is the same.

### The race has split in two

To replicate a human, you need two things, and the industry is racing on both:

- **The race of compute** — who can produce *better* thoughts from existing thoughts.
- **The race of thoughts** — who simply *has more* thoughts to begin with.

Humans are the ultimate processing machine. Language models are climbing toward us, and fast —
but we don't believe they ever truly surpass the original. The compute race has a ceiling, and
the biggest players will own it.

So if you cannot win the race of compute, **the only race left is the race of thoughts — your
data, your mind.** You can make your AI better in exactly two ways: give it a faster processor,
or tell it more about yourself. The first is bought by giants. The second is yours alone — if you
bother to keep it.

**UNIUN exists to let you keep it.** It hands you control of your own thoughts and your own data,
so that even if you lose the AI race on compute, you keep an edge through the knowledge you've
collected. A copy of you is only as good as the thoughts you fed it. Start collecting them now,
in a place you own.

## Your thoughts are a graph — your Brahman

A thought is never alone. It points at other thoughts, answers them, contradicts them, builds on
them. The honest way to store a mind is therefore not a list but a **graph** — nodes of thought,
edges of connection.

In UNIUN your complete graph — every note you've made and every connection between them — is your
**Brahman**. It isn't a feature you switch on; it *emerges* from what you do. Every reference you
draw between two notes is an edge. Every topic is a node. Every reply thread is a small directed
conversation inside the larger whole. Nothing is extracted by a machine — the connections are the
ones *you* asserted.

Take any subset of your Brahman — the notes about one project, one obsession, one version of you —
and you have a **Manas** (a *Manasaputra*, a "mind-born" child of your larger mind). A Manas is a
focused lens: a named, curated slice of your knowledge you can point your AI at, so it reasons as
a specialist instead of a generalist. One note can belong to many Manas at once; nothing is moved,
only linked.

## Three ways to build your Brahman

Your knowledge graph grows three ways — and UNIUN is built as those three, named for the trinity
that creates, sustains, and transforms.

### Brahma — create your own thoughts

<p align="center">
  <img src="assets/images/tabs/brahma.svg" alt="Brahma" height="84" />
</p>

Brahma is the act of creation. Here you author notes and, in authoring them, build the graph.

- **Write notes** — the atomic unit of UNIUN: plain thoughts, captured permanently.
- **Draw connections** — reference existing notes as you write; each reference is a graph edge.
  Tag topics, tag people, attach images.
- **See the graph** — an interactive canvas of your Brahman. Compose new notes directly over it,
  wiring them to what you already know; preview the edges before you publish.
- **Manas** — curate named subsets of your notes into focused knowledge bases, the lenses you
  later hand to your AI.
- **Drafts** — work in progress that lives only on your device until you choose to publish.
- **Translate any note** into another language with the on-device AI.

### Vishnu — take in and share the thoughts of others

<p align="center">
  <img src="assets/images/tabs/vishnu.svg" alt="Vishnu" height="84" />
</p>

Vishnu is the preserver — the social membrane where your Brahman meets everyone else's. You absorb
thoughts worth keeping, and you offer your own.

- **The Feed** — a chronological stream of notes from the people you follow. No ranking algorithm
  deciding what you think about; time only.
- **Threads** — follow any conversation as a tree of replies, and *ask a question of the thread
  itself* (via the inline AI) when you need its context explained.
- **Nearby** — a feed of public notes from people physically around you, exchanged directly
  over Bluetooth and Wi-Fi with no internet (the same layer syncs your own devices when they meet).
  See [`docs/Mesh`](docs/Mesh).
- **Groups** — public rooms for many-to-many conversation.
- **Private Groups** — invite-only, MLS-encrypted group spaces with admin-controlled membership.
- **Direct Messages** — end-to-end encrypted one-to-one conversations (NIP-17 gift-wrapped; only
  the recipient is visible on the relay), with media attachments.
- **Chats that pick up where you left off** — groups, private groups and DMs open at your first
  unread note under a "New notes" line, with an unread count on the jump-to-latest button.
- **Saved & Followed notes** — bookmark a thought to keep forever (and feed it to your AI), or
  subscribe to a single note's *reference graph* and watch new connections arrive — replies to
  replies included, with "New" and "New reply inside" marks that lead you down the trail.
- **Sharing** — re-publish any thought into any surface (feed, channel, DM) as a self-contained,
  signature-verified snapshot, with your own commentary riding alongside.

### Shiv — churn your own thoughts into new ones

<p align="center">
  <img src="assets/images/tabs/shiva.svg" alt="Shiv" height="84" />
</p>

Shiv is the transformer. You already hold the answer; you just haven't drawn the line yet. Gravity
was always there — Newton only made the *connection* when the apple fell. Shiv is the falling apple:
it looks at the Brahman you already have and helps you forge connections latent in it all along.
**All of it runs on your device. None of it calls the cloud.**

- **Shiv (AI chat)** — talk to yourself, or to a single Manas. Every answer is grounded in *your
  own* notes through GraphRAG: your question is matched against your knowledge, expanded one hop
  across the graph, enriched with your memory summaries, and answered by an on-device model. Branch
  any conversation into a tree of alternatives. With a vision-capable model you can attach a photo
  and ask about it.
- **Your documents and photos** — attach a PDF, a Word file, a scan or a picture to a note and ask
  Shiv about it. Scanned pages and photographed text are read on the phone (English and Hindi), and
  every answer shows where it came from — the page or section — which you can tap to open.
- **Nataraj** — the churning of the ocean: a swipe-deck that fuses two or three of your own notes
  into a brand-new idea note. Keep the ones that spark; publish them back into your Brahman. This is
  how new thought is *made* from old.
- **Ganas** — your autonomous agents, Shiv's attendants. A Gana watches an input surface, reasons
  over all of your Brahma, one Manas, or no knowledge at all, and acts on its own — summarizing,
  curating, replying, publishing — on a schedule or whenever something new arrives. A dashboard
  shows what each one has done, what needs attention, and why a run failed. Your mind reaching out
  and interacting with the world (*prakriti*) without you in the loop.
- **Composer-chat** — the same on-device intelligence, inline in every conversation: ask, grounded
  in the recent messages plus a Manas, and turn the answer into a note.

**On-device models you can choose:** Qwen3 0.6B, DeepSeek R1, Gemma 4 E2B, Gemma 4 E4B —
auto-recommended to your phone's RAM (the two Gemma 4 models also read images). An optional UNIUN
Cloud backend exists for those who want it (sign in with your own Nostr key, no separate account),
but the default and the philosophy are local: your thoughts never have to leave your device to be
reasoned over. A Gana pinned to a cloud model that also uses Brahma warns you that its notes would
be sent to that model.

## Under the hood

Strip away the philosophy and here is the machine — a decentralized, offline-first Nostr client
with a native knowledge graph and on-device AI.

- **Decentralized by protocol.** UNIUN is built entirely on the open **Nostr** protocol (NIP-01) —
  no account, no central server, no company that can lock you out. Your identity is a **secp256k1
  keypair**: a public `npub` you share and a private `nsec` only you hold, kept in the device
  keychain and never uploaded. Your data syncs to **relays you choose** — switch them, run your own,
  or fan out to several.
- **The knowledge graph is native, not bolted on.** The Nostr event graph *is* the knowledge graph.
  A Kind-1 note is a node, every `e` tag an edge, every `t` tag a topic node, every reply thread a
  directed subgraph. There is no machine entity-extraction step — the connections are the ones you
  asserted, captured as protocol-native tags.
- **Offline-first by architecture.** A local **Isar** database is the single source of truth; the UI
  reads only from Isar and works with no network at all. A dedicated **Gateway sync isolate** owns
  every relay **WebSocket** connection and mirrors events both ways when you're online.
- **On-device GraphRAG.** Shiv embeds your query, runs a vector similarity search over your notes,
  expands one hop across the graph, folds in your memory summaries, and answers with an on-device
  LLM (**flutter_edge_ai**, formerly flutter_gemma), using the phone's GPU where it can. Every saved note is queued and
  embedded one at a time, so it is never lost if the app closes, and the vector store runs in its
  own isolate so searching never stutters the UI. Prompts never leave the device.
- **Encrypted where it matters.** Direct messages are **NIP-17** rumors sealed and gift-wrapped with
  **NIP-44** (ChaCha20-Poly1305) — only the recipient is visible on the relay. Private groups carry
  MLS-encrypted group messages.
- **Content-addressed media.** Images, video, and files live on **Blossom** servers keyed by
  **SHA-256** — the same file is the same URL on any server — referenced inline via **NIP-92**
  `imeta` tags.
- **Offline peer-to-peer.** A mesh layer exchanges Nostr events directly with nearby devices over
  Bluetooth and Wi-Fi: it syncs your own devices (NIP-77 negentropy) and powers the Nearby feed.
- **Clean, layered Flutter.** Flutter + **BLoC**, three strict layers (data / domain / presentation)
  with unidirectional dependencies. See `CLAUDE.md` for the rules.
- **Self-hostable relay, already deployed.** The companion relay (`uniun-backend/`) is a **Go**
  service on **Khatru** + **BadgerDB**, with a **Blossom** media handler backed by **Azure Blob
  Storage** and an optional **MySQL** mirror. UNIUN runs its own instance that every install
  connects to by default — see `RELAY_URL` in [`docs/Architecture/BACKEND.md`](docs/Architecture/BACKEND.md)
  for the deployment config. You don't have to trust ours: run your own and you own the entire stack.

### NIP stack

| NIP | Used for |
|-----|----------|
| NIP-01 | Base event format + relay WebSocket protocol |
| NIP-02 | Contact list — scopes the feed |
| NIP-05 | Human-readable `name@domain` identifiers |
| NIP-10 | Reply threading (the graph's edges) |
| NIP-17 | Private direct messages |
| NIP-28 | Public groups |
| NIP-29 | Private, relay-managed groups (paired with MLS for message encryption) |
| NIP-44 | Payload encryption (ChaCha20-Poly1305) |
| NIP-56 | Reports & content moderation |
| NIP-77 | Negentropy-based relay reconciliation (efficient re-sync) |
| NIP-92 | Inline media metadata (`imeta`) |
| Blossom (NIP-B7) | Content-addressed media blobs |
| MLS (Marmot) | End-to-end encryption for private-group messages |

For the deeper architecture and conventions, see [`docs`](docs) and `CLAUDE.md`.

## Principles we will not break

- **Your thoughts are permanent.** No delete, no soft-delete, no NIP-09 — once a note exists, it
  exists. A mind you can erase is not a mind worth copying. *(We call this Feed Freedom.)*
- **On-device by default.** The most personal data — the shape of your mind — is reasoned over
  locally. Cloud AI is opt-in, never the default.
- **You hold the keys and pick the relays.** No account to be banned, no server that owns your graph.
  Lose faith in us and you walk away with your `nsec` and your data intact.

---

## Running locally

Requirements:

- Flutter SDK **3.44.2** (channel: stable) — the version CI builds with
  ([`tests.yml`](.github/workflows/tests.yml), [`builds.yml`](.github/workflows/builds.yml):
  `FLUTTER_VERSION`); the project needs Dart `>=3.12`. Verify with `flutter --version`.
- **Git LFS** — the bundled embedding model (`assets/models/embedding/`, about 114 MB) is an LFS
  file. Run `git lfs install && git lfs pull` after cloning, or notes will not embed.
- Dart SDK is bundled with Flutter — no separate install.
- Platform toolchain for whichever target you're building (Android Studio + JDK for Android, Xcode
  for iOS/macOS, Visual Studio with C++ workload for Windows).

Steps from a clean checkout:

```bash
# 1. Resolve packages
flutter pub get

# 2. Regenerate Isar / Freezed / Injectable / json_serializable code
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Regenerate localizations (after editing an .arb file)
flutter gen-l10n

# 4. Run on a connected device or simulator
flutter run
```

You **must** run step 2 every time you change a `@freezed`, `@Collection`, or `@injectable`-annotated
class. The build order (freezed before isar_generator) is locked in `pubspec.yaml` under `global_options`.

To pick a specific target when several are attached:

```bash
flutter devices              # list available devices
flutter run -d <device-id>   # e.g. emulator-5554, macos, windows
```

The first launch will prompt you to download an AI model (~700 MB to ~3 GB depending on the model).
Models live in flutter_edge_ai's managed storage — uninstall via Settings → AI Model.

---

## Running the tests

Read [`test/TESTING.md`](test/TESTING.md) before writing or changing a test. New and changed code is
expected to be fully covered by tests under `test/`; run them in increasing order of cost.

### 1. Unit and widget tests (fast, no device)

```bash
# Whole suite
flutter test

# A focused area — e.g. the on-device LLM scheduler
flutter test test/data/datasources/llm/

# With coverage (read coverage/lcov.info for the files you touched)
flutter test --coverage test/features/dm
```

### 2. Vertical-slice integration tests (fast, no device)

Wire the real production classes across `presentation → domain → data` over a real Isar and
assert the chain behaves end to end. Catches DI and signature-drift regressions.

```bash
flutter test test/integration/
```

### 3. Real-device tests (need a connected device)

These load native libraries (flutter_edge_ai, MLS, …) and real scrolling, so they live at the repo
root in `integration_test/` (the folder name is a Flutter convention). Run them through the
script, which keeps the screen awake and does not uninstall the app:

```bash
# Once per model: push it where an uninstall does not wipe it
scripts/device_test.sh push-model <path-to-model-file>

# One file, or the whole suite in one install
scripts/device_test.sh run integration_test/unread_dots_e2e_test.dart
scripts/device_test.sh run
```

The script prints "Building and installing, then the test is running on the phone…" and stays
quiet for a minute or two while it builds. Tests that need a model fail loudly if it is not
provisioned. `gana_local_engine_e2e_test.dart` publishes one real, permanent note to the relay on
every run.

### What CI runs

- **Tests** ([`tests.yml`](.github/workflows/tests.yml)) — the analyzer over `lib/`, `test/` and
  `integration_test/`, then the test suite in eight parallel shards, with coverage reported to
  Codecov. Every test file has to belong to a shard.
- **Builds** ([`builds.yml`](.github/workflows/builds.yml)) — a release build for Android, iOS
  (no code-signing) and Windows on every pull request, every push to `main` and nightly.

See [`docs/SHIVA/scheduling.md`](docs/SHIVA/scheduling.md) for the algorithm under test and the
verification scenarios behind the scheduler tests.

---

## Platform support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Supported | Flutter's default minimum SDK (API 24). GPU inference where available. QR scan, image / video / file picker, on-device AI all work. Release build checked in CI. |
| **iOS** | ✅ Supported | iOS 16+. Metal-backed inference. Universal Links wired to `www.uniun.in`. Release build (no code-signing) checked in CI; features are not all verified on a device from the Linux dev machine — see the audit's open items. |
| **macOS** | ✅ Supported | Tested locally. Isar, Gateway sync, and on-device AI all work. |
| **Windows** | ✅ Supported | Release build checked in CI. NPU dispatch available on Intel Lunar/Panther Lake via `flutter_edge_ai`. Note: discrete-GPU support on Windows is currently broken upstream in the `flutter_edge_ai_litertlm` engine (1.2.0+) — CPU/NPU are the working fallback there. |

The platforms compile from the same `lib/` codebase; there is no platform fork.

---

## Project layout

```
lib/                  Flutter app (see CLAUDE.md for the layer rules)
  ├── core/           Routing, theme, constants, base classes
  ├── data/           Isar models + repository implementations
  ├── domain/         Freezed entities, abstract repos, use cases
  ├── gateway/        Relay sync isolate (WebSocket + inbound handlers)
  ├── features/       Feature modules (vishnu, brahma, shiv, groups, private_groups, dm, mesh, surrounding, …)
  ├── common/         Cross-feature widgets and helpers
  └── l10n/           Localizations (en, hi, gu, ja) and generated delegates
test/                 Unit, widget and vertical-slice tests (CI shards; see test/TESTING.md)
integration_test/     Real-device tests, run through scripts/device_test.sh
uniun-backend/        Go Nostr relay (Khatru + BadgerDB + Blossom + Azure)
docs/                 Architecture notes (media, GraphRAG, mesh, Shiv, releasing, audit log)
CHANGELOG.md          What changed in each release
DESIGN.md             Design system and screen spec
```

---

## Roadmap

What is planned or being looked at, from the open issues. No dates are promised.

- **Creator monetization.** A way for users to earn from what they publish — the same
  ownership principle as your notes and keys, extended to your income. In line with UNIUN's
  Nostr-native philosophy, this leans on the protocol's own payment rails (zaps) rather than a
  walled-garden payment system.
- **Documents in the graph.** Let documents contribute nodes to the knowledge graph (#235) and let a
  Manas-scoped chat reach its notes' attached documents (#236).
- **Search and highlights over Nostr.** Global search with NIP-50 (#247) and text highlights with
  NIP-84 (#246).
- **Faster on-device translation** with ML Kit, keeping the LLM as a fallback (#241).
- **Editable memory nodes** — surface and edit the wiki-style summaries Shiv builds over your graph.
- **Export a backup** from settings (#121).
- **Deeper graph reasoning** — multi-hop retrieval and stronger synthesis as on-device models improve.
- **Automated release artifacts** and store uploads after a release PR merges (#276).

Have an idea or a use case we haven't thought of? Open an issue — the roadmap changes based on
what people actually ask for.

---

## Contributing

UNIUN is open source and welcomes contributions. Start with
[`CONTRIBUTING.md`](CONTRIBUTING.md) — it covers project setup, the architecture rules that are
enforced (not stylistic preferences: no NIP-09, no Reddit-style models, `isar_community` only,
Freezed 3.x `abstract class`, all UI strings via `AppLocalizations`), testing, commit/branch
conventions, and how to submit a pull request. For the deeper technical detail behind each
subsystem, see [`docs`](docs) and `CLAUDE.md`. Releases are cut as described in
[`docs/RELEASING.md`](docs/RELEASING.md).

Bug reports and feature requests go through the [issue tracker](../../issues). Don't commit
`*.g.dart` or `*.freezed.dart` files — they are ignored and reproduced by `build_runner`. The
localization delegates in `lib/l10n/app_localizations*.dart` *are* committed: after editing an
`.arb` file, run `flutter gen-l10n` and commit the result.

Everyone participating in the project — issues, PRs, discussions — is expected to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

---

## License

UNIUN is licensed under the [GNU General Public License v3.0 or later](LICENSE).
