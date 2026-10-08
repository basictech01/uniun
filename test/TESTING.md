# Testing Guide — UNIUN

Single source of truth for how every test in this repo is written. Read
this before writing or modifying tests. Deviations are rejected in review.

---

## 1. Comment style (the only rule reviewers fight over)

One short factual docstring per file. State what's covered. Nothing else.

✅ Good
```dart
/// Covers: ScaleTransition + FadeTransition composition, animation ticks,
/// size prop reaches DropIcon, controller dispose.
void main() { ... }
```

❌ Bad
```dart
/// `DropLoadingIndicator` is the branded loading spinner used everywhere
/// in place of `CircularProgressIndicator`. The tests pin the structural
/// contract: the indicator IS a scale+fade transition composition (the
/// breathing animation), not just a static glyph; the size prop reaches
/// the DropIcon; the controller is disposed cleanly (no hanging ticker).
void main() { ... }
```

Inline comments only when an assertion documents a non-obvious quirk
("current behaviour: TypeError surfaces unchanged") — never narrate what
the test code already shows.

---

## 2. Shared fixtures — `test/_helpers/fixtures.dart`

Every domain entity has a factory there. **Never hand-roll a
`NoteEntity(...)` in a new test.**

### Available factories

| Function | What it builds |
|---|---|
| `aNote(...)` | Top-level Kind-1 feed note (defaults: alice author, "hello world") |
| `aReply(parent: ...)` | NIP-10 reply wired to a parent note |
| `aGroupMessage(groupId: ...)` | Kind-42 public-group message |
| `aPrivateGroupMessage(groupId: ...)` | Kind-9023 NIP-29 private-group message |
| `aDmText(conversationId: ...)` | Kind-14 DM rumor |
| `aGroup(...)` | NIP-28 public-group metadata entity (Kind-40 snapshot) |
| `aPrivateGroup(...)` | MLS private-group entity (`mlsGroupId` defaults to `mls_<groupId>`) |
| `aQuoteOf(original)` | Note quoting another by value |
| `aFeed(n: ...)` | List of `n` notes, newest first |
| `aThread(depth: ...)` | Linear reply chain root → r1 → r2 → … |
| `aProfile(...)`, `anAnonymousProfile()` | Profile entities |
| `aSavedNote(...)`, `aManas(...)`, `manyManas(n)` | Other entities |
| `aUserKey(...)` | Active-user key entity |
| `aMediaBlob(...)`, `aPdfBlob()`, `aVideoBlob()` | Media attachments |

### Shared constants

```dart
tT0    // DateTime.utc(2026, 1, 1) — "beginning of time"
tNow   // DateTime.utc(2026, 6, 30, 12, 0, 0) — default for `created`/`updatedAt`

kSelfPub, kAlicePub, kBobPub, kCarolPub, kEvePub   // stable pubkeys
pubkeyN(i), eventIdN(i)                            // synthetic ids
```

### `Content` payload class

Pre-built strings every text / markdown / preview test reuses:

```dart
Content.empty, Content.oneChar
Content.emoji, Content.unicode, Content.rtl
Content.singleNewline, Content.manyNewlines, Content.veryLong()
Content.longJustOver(maxChars)
Content.bareHttp, Content.bareHttps, Content.multipleUrls
Content.nostrUri, Content.mixedSchemes
Content.snakeCase, Content.boldOnly, Content.italicOnly, Content.codeOnly
Content.mixedInline, Content.allHeadings, Content.bulletList,
Content.numberedList, Content.blockquote
Content.alreadyBracketed, Content.urlInSentence
```

### Adding a new factory

If a test needs a shape no existing factory builds:

1. **Add the factory to `fixtures.dart`**, not the test.
2. Match the existing signature pattern: required positional/named first,
   every overrideable field as a named param with a sane default.
3. Document with a single one-line comment if the default is unusual.

---

## 2b. Shared helpers beyond fixtures — `test/_helpers/`

Fixtures are for freezed **domain entities**. Everything else that would
otherwise be duplicated across two or more test files lives in one of
these siblings. **Never** hand-roll an Isar model row, an event-queue
recorder, or a repository stub in a new test — use the shared helper
below, or add one if the shape is missing.

| Helper file | Exposes | Use for |
|---|---|---|
| `isar_test_harness.dart` | `openTestIsar()`, `groupSeed`, `privateGroupSeed`, `followedUserSeed`, `followedNoteSeed` | Opening an isolated on-disk Isar in `setUp` + one-liner seed rows for those specific collections. |
| `isar_seeds.dart` | builders `noteRow`, `unreadRow`, `relationEdge`, `reportRow`, `deletedNoteRow`, `eventQueueRow`, `profileRow`, `dmConversationRow`, `relayRow`, `savedNoteRow`, `shivConversationRow`, `shivMessageRow`, `mediaAttachmentRow`, `mediaCacheRow`, `joinRequestRow` + committers `seedNoteRow`, `seedUnreadRow`, `seedRelationEdge`, `seedReport`, `seedDeletedNote`, `seedProfile`, `seedDmConversation`, `seedRelay` | Isar model rows for `Note`, `UnreadNote`, `NoteRelation`, `Report`, `DeletedNote`, `EventQueue`, `NostrProfile`, `DmConversation`, `Relay`, `SavedNote`, `ShivConversation`, `ShivMessage`. Builders return the model (batch them in one `writeTxn`); committers wrap their own `writeTxn`. |
| `recording_event_queue.dart` | `RecordingEventQueue`, `EnqueueCall` | Any repo that publishes through `EventQueueRepository.enqueueSignedEvent`. Configure `leftOnEnqueue` / `throwOnEnqueue` to simulate failure. Inspect `.calls` to assert wire shape. |
| `fake_note_relations.dart` | `FakeNoteRelations` | Any repo that reads from `NoteRelationRepository`. Seed `.children[parentId]` / `.parents[childId]` before the test runs. |
| `stub_user_repository.dart` | `StubUserRepository` | Any repo that calls `UserRepository.getActiveKeysHex()` or `getActiveUser()` (both derive from `.keys`). Set `.keys = null` to simulate a logged-out identity. |
| `stub_followed_users.dart` | `StubFollowedUsers` | Any repo that reads the follow list via `FollowedUserRepository.getAllPubkeys()`. Seed `.pubkeys`; set `.leftOnGetAllPubkeys` to simulate failure. |
| `pdf_fixtures.dart` | `pdfFixture(name)`, `packageRoot()`, `normalizePdfText(...)`, `minimalPdf(pages, renderMode:, baseFont:)`, `imagePdf(inForm:)` | Anything touching PDFs. `pdfFixture` resolves a committed fixture from the package root; `normalizePdfText` folds ligatures/NBSP/curly quotes so assertions survive extractor differences; `minimalPdf` generates a synthetic PDF for negative cases (`renderMode: 3` = invisible text, `baseFont` for a legacy-font case); `imagePdf` is one page holding one picture, optionally wrapped in a form XObject. |
| `pdfium_test_lib.dart` | `ensurePdfium()` | Any test that opens a real PDF. `flutter test` does not run native-asset build hooks, so PDFium is missing; this downloads it once and points pdfrx at it — the same shape as `ensureIsarCore()`. Call it before `pdfrxFlutterInitialize()`, and install `FakePathProviderPlatform` first (pdfrx resolves its cache dir through path_provider). |
| `fake_pdf_text_source.dart` | `FakePdfTextSource` | Extraction code that needs page text without native PDFium. Seed `.signals[path]` for per-page OCR plans (unset = no signals, text layer only); `.renders` records each render request, `renderKey(...)` is the path each answers (key `FakeOcrTextSource.texts` on it), `.failRenderPages` fails some, and `.renderDir` writes real files so a test can check they are deleted. |
| `docx_fixtures.dart` | `docxFixture(name)`, `minimalDocx(document:, styles:, extra:, media:)`, `wDocument`, `wP`, `wTable`, `wDrawing`, `wRels`, `wStyles`, `englishHeadingStyles`, `withDeclaredSize(...)`, `withCorruptData(...)`, `writeTempDocx(...)` | Anything touching DOCX. Build each case as exact XML with `minimalDocx` rather than committing a file per case; `withDeclaredSize` rewrites a zip entry's declared size so the size-cap test needs no 50 MB fixture. `wDrawing` + `wRels` + `media:` build an embedded picture; `withCorruptData` makes one entry fail to inflate while the zip still opens. |
| `fake_docx_text_source.dart` | `FakeDocxTextSource` | Extraction and indexing code that needs DOCX sections without a real file. |
| `fake_ocr_text_source.dart` | `FakeOcrTextSource` | Anything that reads text from images. ML Kit runs only on Android/iOS, never under `flutter test`; `''` is an image with no text, `null` an unreadable one. `.reader` answers paths not known in advance (a page rendered to a temp file). Real OCR is covered in `integration_test/document_rag_e2e_test.dart`. |
| `fake_image_label_source.dart` | `FakeImageLabelSource` | Anything that labels images. A missing path means nothing recognisable (`[]`); a `null` entry is an unreadable file. Real labeling runs in `integration_test/document_rag_e2e_test.dart` against real photographs passed via `--dart-define=LABEL_PHOTOS_DIR`. |
| `fake_document_vectors.dart` | `FakeDocumentVectors` | Anything reading or writing document chunk vectors. |
| `fake_path_provider.dart` | `FakePathProviderPlatform` | Code that calls `getApplicationDocumentsDirectory()` / `getApplicationSupportDirectory()`. Install via `PathProviderPlatform.instance = FakePathProviderPlatform(docs: ..., support: ...)` pointing at temp dirs. |
| `mesh_test_helpers.dart` | `stubSecureStorageChannel()`, `MeshIdentity` | Any mesh test. The stub silences flutter_secure_storage's channel (NIP-44 PBKDF2 path) — call once at the top of `main()`. `MeshIdentity.generate()` = real Schnorr keypair + bound `MeshEventCodec`; generate a second one to play the attacker in signed-by-another-identity drop tests. |

Two mesh-only doubles live in `test/mesh/support/` (feature-scoped, not
general): `fake_signer.dart` (`FakeSigner` — deterministic handshake
`MeshSigner`) and `paired_mesh_link.dart` (two in-memory `MeshLink` ends
wired back-to-back). Also: `isar_test_harness.dart` exposes
`ensureIsarCore()` — a race-safe, HttpClient-mock-proof download of the
IsarCore native binary; `openTestIsar()` calls it for you, only call it
directly if you open Isar instances by hand (see `sync_integration_test`).
Never call `Isar.initializeIsarCore(download: true)` yourself — under
parallel `flutter test` it races and under `TestWidgetsFlutterBinding` its
download can never succeed (mocked HTTP 400).

### Keyword-ranking quality

The committed retrieval regression test reports Recall@1/3/5 and MRR for both
the existing English Gecko benchmark and the fictional Hindi/Hinglish keyword
fixture:

```bash
flutter test test/features/shiv/rag/retrieval/hybrid_ranking_quality_test.dart
```

`aranya_hindi_hinglish_keyword.retrieval.json` covers Bengali and Devanagari
OCR digits, nukta, an allow-listed chandrabindu/anusvara spelling variant and a
Devanagari joiner variant. The production tokenizer normalises the question and
each chunk only while BM25 scores them;
the stored text and the text sent to the embedder stay unchanged, so these
checks never require re-indexing. The device suite additionally exercises the
same normalisation through `IsarDocumentVectorRepositoryImpl.search`.

### Device retrieval test with your own documents

`tool/rag_docs_e2e.sh <device-id> [extra-dir]` pushes the committed Aranya PDF and
its messy-question file to the phone, indexes it with the real Gecko embedder,
runs a self-retrieval check (every stored chunk must find itself) and asks each
question, printing whether the right page came first, in the top 3, or missed.
`[extra-dir]` may hold your own `*.pdf` and a `queries.json` (same format; `doc`
is the file name without `.pdf`) — keep private documents out of the repo.
Indexing costs about 13 s a chunk, provided the phone's screen stays on (the
script wakes it): with the screen off Android runs the app on the slow cores and
it takes ~5x longer. It also prints Recall@1/3/5 and MRR for meaning-only against
hybrid ranking, and pulls a dump of all vectors to `/tmp/rag_dump.json` (holds
document text — keep it out of the repo); `flutter pub run
tool/eval_retrieval.dart` re-ranks that dump for a grid of settings offline.

### Binary fixtures — `test/_helpers/fixtures/`

Real-world binaries a test needs, with a `PROVENANCE.md` per directory recording
source URL, date, licence and sha256 for each. `pdf/` holds a public-domain NIST
PDF and three selective-OCR fixtures built for this repo (a scan, a typed page
with a pasted photo, a mixed circular); `docx/` holds two public-domain Microsoft Word templates (NIST, USPTO) and
one LibreOffice export — each proving the reader against what a real producer
writes rather than what we generated.

Rules: keep them small (< 300 KB); never re-save or re-compress them (a mutated
fixture stops being evidence); **not** in Git LFS (a CI checkout without
`lfs: true` yields a pointer file, which parsers reject with a confusing `null`);
and never referenced from `pubspec.yaml`'s `assets:` — they must not ship to
users. Load them with `dart:io` via `pdfFixture(...)` / `docxFixture(...)`, not
the asset bundle.

`shard-coverage` greps for `*_test.dart`, so a binary here is invisible to it —
but never put a `_test.dart` file in this directory.

### Constants in `fixtures.dart`

```dart
kTestPrivHex, kTestPubHex, kSigningKeys, aSigningKeys(...)  // signing keys
kSampleEventIdHex          // 64-char hex event id (for NIP-56 / nostr code paths)
kSampleTargetPubkeyHex     // 64-char hex pubkey (same, for target-user args)
tOwnProfileSentinel        // DateTime(3000,6,1) own-profile eviction sentinel
```

Isar round-trips `DateTime` as **local time** and SharedPreferences-backed
stores truncate to millis — compare instants (`isAtSameMomentAs`) or epoch
millis, never `==` against a UTC fixture.

Use `kSampleEventIdHex` / `kSampleTargetPubkeyHex` when the code under
test validates hex shape (schnorr sig, NIP-56 tag verify, etc). Use the
short `kAlicePub` / `kBobPub` when the value is just an opaque identifier.

### Adding a new shared helper

Rule of thumb: **the moment a test double is copy-pasted into a second
file, promote it.**

1. Give it a distinctive name (`RecordingEventQueue`, not `_MockQueue`)
   and move it to `test/_helpers/<snake_case>.dart`.
2. Prefer `Recording*` for capture-and-inspect doubles, `Fake*` for
   deterministic in-memory implementations, `Stub*` for
   fixed-return-value doubles. Reserve `Mock*` for mocktail.
3. Keep it self-contained — a shared helper must not depend on
   test-file-local setup. Any collaborator it needs goes through named
   fields with defaults.
4. Everything under `test/_helpers/` is excluded from the CI
   shard-coverage grep, so no CI update is needed when adding files
   here.

---

## 3. File layout — edges fold into the original

There is **one** test file per source file (or per cohesive cohort like
"all NoteCard cubit tests"). Edge cases are an `// ── Edge cases ──`
divider near the end. **Never** create `foo_edge_cases_test.dart`.

```dart
void main() {
  group('happy path', () { ... });
  group('failure modes', () { ... });

  // ── Edge cases ──────────────────────────────────────────────────

  group('unicode + emoji', () { ... });
  group('malformed input', () { ... });
  group('scale', () { ... });
  group('boundary conditions', () { ... });
}
```

### What "edge cases" means in this repo

For every behaviour-bearing module, cover at minimum:

- **Unicode / emoji / RTL** — `Content.emoji`, `Content.unicode`, `Content.rtl`
- **Empty / whitespace-only input** — `Content.empty`, `'   \t\n  '`
- **Boundary** — at the threshold, threshold-1, threshold+1
- **Scale** — `Content.veryLong()` (200 lines) or 100+ entities
- **Malformed input** — half-open JSON, type confusion, missing keys
- **Type confusion** — int where String expected, null where required
- **Concurrency** (for stateful code) — fire two events before the first
  resolves; cancel mid-flight

---

## 4. Canonical packages (no alternatives without discussion)

| Package | Version | Used for |
|---|---|---|
| `flutter_test` | (sdk) | `testWidgets`, `expect`, finders |
| `bloc_test` | `^9.1.7` | `blocTest(build:, act:, expect:, verify:)` + `MockCubit<S>` |
| `mocktail` | `^1.0.4` | `class _M extends Mock implements X {}` (no codegen) |
| `get_it` | (already in app) | DI swap via `reset()` + `registerFactory` in widget tests |
| `dartz` | (already in app) | `Either<Failure, T>` mocking |

**Do NOT use:** `mockito` (uses codegen, conflicts with our build_runner
graph), `flutter_test_ui`, hand-rolled spy classes.

---

## 5. Patterns by test type

### Bloc / Cubit tests

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../_helpers/fixtures.dart';

class _MSave extends Mock implements SaveNoteUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(aNote());           // for `any()` matchers
    registerFallbackValue(const ManasNoteLink('m', 'n'));
  });

  late _MSave save;

  setUp(() {
    save = _MSave();
    // Default stubs covering construction so unrelated tests don't crash.
    when(() => save.call(any())).thenAnswer((_) async => Right(aNote()));
  });

  blocTest<MyBloc, MyState>(
    'description',
    build: () => MyBloc(save),
    act: (b) => b.add(SomeEvent()),
    expect: () => [SomeState()],
    verify: (b) => verify(() => save.call(any())).called(1),
  );
}
```

**Critical detail for `bloc_test`:** the second type parameter must be the
ACTUAL state type (e.g. `NoteCardState`), not `dynamic`. With `dynamic`
the callback `c` is typed `Object?` and `c.state` won't resolve.

### Widget tests that read from getIt

```dart
import 'package:get_it/get_it.dart';

setUp(() async {
  await GetIt.instance.reset();
  GetIt.instance.registerFactory<MyBloc>(() => mockBloc);
  GetIt.instance.registerFactory<UseCaseA>(() => mockA);
});
```

`BlocProvider.value` at an outer level does NOT override an inner
`BlocProvider.create(getIt<X>(...))` — you must replace the getIt entry.

### Widget tests with infinite animations

```dart
// DON'T: pumpAndSettle — animation never settles, times out.
// DO: pump a finite duration.
await t.pump(const Duration(milliseconds: 300));
```

### Widget tests with localization

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: ...,
)

// When you need the strings in assertions:
final l10n = await AppLocalizations.delegate.load(const Locale('en'));
expect(find.text(l10n.actionSave), findsOneWidget);
```

### Integration tests (real Isar)

```dart
import '../_helpers/isar_test_harness.dart';
import '../_helpers/fixtures.dart';

late Isar isar;

setUp(() async { isar = await openTestIsar(); });
tearDown(() async { await isar.close(deleteFromDisk: true); });
```

The harness shard runs with `concurrency: 1` in CI (Isar's native
libmdbx races otherwise — see SIGBUS prevention in `tests.yml`).

---

## 6. Pipeline awareness

`.github/workflows/builds.yml` is separate: it compiles the app for Android
(`flutter build apk --debug`), iOS (`--debug --no-codesign`) and Windows
(`flutter build windows --debug`) on PRs, pushes to `main` and nightly. It runs
no tests; it catches Gradle, CocoaPods, MSVC and native-hook breakage the Linux
test shards cannot see.

The CI workflow (`.github/workflows/tests.yml`) shards tests by top-level
path:

```
test/data, test/domain, test/gateway,
test/features, test/integration, test/common
```

- Each `*_test.dart` file MUST live under one of these (or be one of the
  legacy root-level files listed in `shard-coverage`).
- `test/_helpers/` is excluded from the test runner by the harness — it's
  imported, not executed.
- Adding a NEW top-level test dir requires updating both the matrix and
  `shard-coverage`. Prefer adding under an existing shard.

**Isar inside `testWidgets`.** Isar needs real async, not the widget test's fake
clock: run every Isar call under `tester.runAsync` (or start it with
`Zone.root.run` from widget code), and close Isar inside the test body before
`tearDown`, or the test hangs. `test/integration/unread_flow_test.dart` shows
the pattern (`io`, `chatTest`).

The root `integration_test/` directory is **not** part of this and never runs in
CI — it is device-bound (`IntegrationTestWidgetsFlutterBinding`). CI does
analyze it (`flutter analyze lib/ test/ integration_test/`), so a device test
that no longer compiles fails the PR. Tests that need
real flutter_gemma (the chat models, or the bundled Gecko embedder) live there
because the models are Git-LFS assets CI does not check out. Run them by hand:

```
flutter test integration_test/all_tests.dart -d <device-id>
```

**Pre-set model (no download per run).** `flutter test` normally uninstalls the
app after a run, taking a downloaded model with it. So the model is pushed to
the phone once, to `/data/local/tmp/uniun_test/` (the uninstall does not touch
it), and tests install it from there with `provisionTestModel(AIModelId.…)`
from `integration_test/support/test_model.dart`:

For other device targets, place the model in the app documents directory or
set `--dart-define=UNIUN_TEST_MODEL_DIR=<device-accessible-directory>` when
running the test. The helper uses that fixture directory before its existing
default path and registers a model already present in app documents.

```
# once per model (the catalog URL gives the file name, e.g. gemma-4-E2B-it.litertlm)
adb shell mkdir -p /data/local/tmp/uniun_test
adb push gemma-4-E2B-it.litertlm /data/local/tmp/uniun_test/

# every run: keeps the app installed, so its data and the model copy stay
flutter test --no-uninstall integration_test/<file>.dart
```

`scripts/device_test.sh push-model <file>` / `run [file]` wraps exactly this and
also keeps the screen on and unlocked (a sleeping screen runs the app on slow
cores, several times slower).

- **Default model: Gemma 4 E2B** — it reads images and is small enough for most
  phones, so one model covers chat, Gana, scheduler and image tests. Qwen3 0.6B
  is enough for tests that only need text.
- `provisionTestModel` copies the file into the app's own folder once (that is
  where flutter_gemma restores a model from in every isolate, including the
  background one), registers it, and marks it active. It needs no DI. It
  returns `false` when the model was never pushed, so a test can SKIP with a
  clear message instead of failing.
- While it works it shows a plain "UNIUN test starting…" screen instead of the
  splash.
- Used by `gana_local_engine_e2e_test`, `flutter_gemma_bg_isolate_test`,
  `scheduler_preemption_test`, `scheduler_model_switch_test` and
  `chat_image_turn_test`. Use it in any new test that needs a real model.
- Real generation is slow (~2.5 tokens/s for E2B): keep prompts short, use one
  `maxTokens` per test (a different value makes flutter_gemma rebuild the whole
  model), and wait for a first token rather than a fixed delay.
- `scheduler_model_switch_test`'s second test needs two downloaded models and
  still skips with one.
- A debug build skews timing: run timing tests in profile mode with
  `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<file>.dart --profile`
  (`test_driver/integration_test.dart` is the 3-line host side). `embedding_benchmark_test` and
  `note_save_timing_e2e_test` are the examples; the latter runs unchanged on old and new code, so check
  out `main`, copy the file in, run it, and compare.

Adding one means adding an import + `main()` call to `integration_test/all_tests.dart`
— that list is the source of truth. **Never gate a device test on a silent
`return`** when the thing it needs ships with the app: `EmbeddingService.embed`
answers `[]` rather than throwing when the model is missing, so a test that skips
on that would pass while proving nothing. Assert the model loaded, and fail.
Assert it is non-empty, not a specific length: the bundled Gecko model emits 768
dimensions where the app declares 1024 (#234), so a length check fails on every
device and the test never reaches what it was written to prove.

---

## 7. Edge-case checklist (for every new module)

Run through this before declaring a test "done":

- [ ] Happy path (single typical input)
- [ ] All branches of every conditional
- [ ] Empty / null / whitespace input
- [ ] Boundary values (at, just-below, just-above)
- [ ] Unicode + emoji + RTL
- [ ] Very long input (`Content.veryLong()` or 100+ items)
- [ ] Malformed / hostile input (where applicable)
- [ ] Type confusion (cast failures, wrong shape)
- [ ] Concurrent / cancel-mid-flight (stateful only)
- [ ] Failure paths from every dependency (`Left(Failure)`)
- [ ] Idempotency (where the contract claims it)
- [ ] No exception leak (`expect(t.takeException(), isNull)` at the end
      of widget tests touching async or animations)

---

## 8. Anti-patterns to reject

- Hand-rolled entity constructors in a new test — use fixtures.
- Separate `*_edge_cases_test.dart` files — fold into the original.
- Multi-paragraph docstrings — one factual line.
- Storytelling comments ("the most-touched widget", "silently breaks",
  "tests pin the contract") — describe what's covered, not the drama.
- `dynamic` as bloc_test's state type parameter — use the real state.
- `mockito` — use `mocktail`.
- `pumpAndSettle` on an infinite-animation widget — use `pump(Duration)`.
- Tests that depend on global state from a previous test — every test
  starts from `setUp`, leaves no leak in `tearDown`.
