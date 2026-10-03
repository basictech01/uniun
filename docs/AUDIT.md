# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

---

## 2026-10-02 — graph rewritten after Obsidian's: physics, lines, nodes, labels — work in progress

The Brahma graph's lines tangled: thick (1.6–2.5 px), full-strength, every pair repelling at O(n²), a dedicated "push nodes off unrelated lines" hack, a widget per node rebuilt every tick. It is now a d3-force-style simulation and a single painter, modelled on what Obsidian's graph does (researched from its help docs, d3-force and Quartz, whose graph mirrors it; Obsidian itself is closed source, so its numbers are inferred from those).

- **Physics** (`lib/features/brahma/graph/layout/graph_simulation.dart`, pure Dart): a heat (`alpha`) that cools to rest (~300 ticks); link springs (d3's 1/min(degree) strength), many-body repulsion with a Barnes-Hut quadtree (O(n log n)), a gentle centre pull, hard non-overlap by a grid. Constants are Quartz's scaled ×3 for finger-sized nodes (charge −500, link distance 90, centre 0.05). Nodes start on a deterministic sunflower spiral. A graph is laid out *before* it is drawn (200 ticks), and the view opens zoomed out to fit when it is wider than the screen (re-fitted once when it settles, unless the user has moved it). The ticker stops at rest, so a still graph costs nothing.
- **Lines**: 1.8 screen pixels at any zoom (3 px when lit), 80 % opacity — visible, not hairlines — batched into two paths. Selecting a node lights its links in the accent colour and fades the rest to 25 %; searching fades them to 20 %.
- **Nodes**: the original look and size — the circle's *diameter* is `24 + 3·links`, capped at 50 (an earlier pass wrongly used that as the radius, drawing nodes twice as big) — with the label under each, always shown, drawn solid (blended onto the background, so no link shows through) with the same soft glow on the selected and connected ones. The layout counts a 24 px label footprint around each circle so labels never sit on one another; its constants are scaled for these nodes (charge −1200, link 160, centre 0.08). Selection fades unrelated nodes to 20 %, as Obsidian's hover does. Obsidian-style labels that fade in with zoom exist in the painter (`fadeLabels`) but are off.
- **Opens already laid out**: the layout is run to rest (300 ticks) before the first frame, the view is fitted to the whole graph (zoomed out when it is wider than the screen), and nothing animates until the user drags a node — so a still graph costs no battery. (An opening animation — nodes scattered on a ring pulling into place, the view following — was built and then removed as too complex.)
- **Untouchable nodes — three root causes, each reproduced by a failing test first**: (1) taps were taken over the canvas's own screen-sized box, so a node laid out beyond that box was drawn but never hit — hit-testing is now over the whole canvas, converted to graph coordinates; (2) a tap with a few pixels of finger wobble was claimed as a drag (claim distance 4 px, a finger's tap wobbles more), so no tap fired — the drag now claims at 14 px, below the canvas's own pan/pinch (18 px) so it still wins drags; (3) a tap was resolved where the finger lifted, so a node the layout moved meanwhile (the opening animation) was missed — a tap now belongs to the node under the finger when it landed (read from the raw pointer-down, since a tap recogniser only reports it after its 100 ms press timeout). A drag is one-to-one with the finger at any zoom, and the 14 px used deciding it is a drag are carried into it so the node is not left behind.
- **Gestures**: tap a node or empty space (14 px of finger reach, constant on screen); a touch that starts on a node and moves 4 px drags it — pinning it while held, pulling neighbours along (heat 0.3) and releasing it on lift so the layout relaxes, as in Obsidian; a touch on empty space still pans and pinches. The camera flight, search focus, node panel and Manas scoping are unchanged.
- **Verified**: 22 simulation tests including layout-quality measures (no two circles overlap; linked nodes far closer than unlinked; ≤ 2 nodes on someone else's link; compactness; determinism; Barnes-Hut within 10 % of exact for one step; 500 nodes under 30 ms per tick), 20 canvas tests (tap, drag, release, pan, selection, labels, fit, idle), and the existing camera tests. Rendered to images and looked at: 60 nodes is clean; 250 nodes fits the screen with no lines through nodes.
- **Sabotage** — each of 12 breaks turned a test red (no collision, no repulsion, no springs, no centre pull, pins ignored, never cools, hit-test slop, node not released on drag end, ticker never stops, no fit, no selection fade, no touch reach). One break survived on purpose: exact instead of approximate repulsion gives the same answer, only slower.
- **Not done**: Obsidian's settings panel (force sliders, filters, groups, arrows, timelapse), a local-graph depth slider, hover preview. Not run on a device yet.

---

## 2026-10-01 — in-app jump to the cited page or section (#237) — work in progress

Tapping a PDF source opens pdfrx's viewer on the cited page; a Word source opens an in-app text view scrolled to and tinting the cited heading's section. Both keep an "Open in another app" action. Design and limits: `docs/SHIVA/rag.md` → "Opening a citation".

- **Verified against real PDFium** (not a double): a widget test opens the committed 7-page NIST PDF through the real viewer and reads the controller — it lands on page 5 for a citation on page 5. An out-of-range page ends on a real page.
- **A clamp I added turned out redundant:** sabotage showed pdfrx corrects an out-of-range start page by itself after it settles, so the clamp was removed rather than kept untested.
- Sabotage — each turned its tests red: viewer always page 1; non-numeric label not falling back; open-in-other-app shown for a missing file; heading disambiguation by passage; the scroll to the section; the tint on it; the tile routing to the wrong route; the tile skipping the file-exists check.
- Strings in `app_en.arb` and `app_hi.arb`.
- **Highlighting built.** The first 12 words of the cited chunk are found in the viewer's text for the cited page and painted. Two traps found by testing against real PDFium: pdfrx's multi-page `PdfTextSearcher` returned no matches here (abandoned for a direct search of the one cited page), and a page's text is empty until the page is loaded (`ensureLoaded`). The painting and its right-page filter are tested on a mock canvas; each break turns a test red.
- **On the phone (real app viewer):** a generated PDF opens on page 6 with highlights on page 6 only; a generated Word file scrolls to and tints its section; tapping a real Sources tile opens the viewer on the cited page.
- **Word tables and pictures built.** The Word view draws tables as a grid and large pictures inline, using the existing extraction (` | ` rows and picture markers); no second parser. Pictures are extracted into a temp folder that is removed when the view closes. Device-tested with a real generated .docx holding a table and a picture. Known limit: a prose line with a spaced pipe is indistinguishable from a one-row table.
- Not done: Word styling and small pictures; iOS check; the full chat-to-citation flow with a live model answer (the tile-to-viewer path and the viewer are each tested; the model step was not driven).

---

## 2026-09-29 — selective OCR for PDF pages and DOCX pictures (#242) — work in progress

A PDF is now read page by page: the text layer where it is good, OCR where a page is scanned or its text layer is garbled, and OCR of one large pasted picture beside a typed page's text. Large pictures inside a DOCX are OCRed where they sit. Rules, thresholds and costs: `docs/SHIVA/rag.md` → "Scanned pages and pasted pictures".

### Built on PDFium directly — pdfrx exposes none of the signals

- Per-page signals (text-render mode, unmapped glyphs, font names, image bounds including images wrapped in form XObjects, characters drawn over the largest image) come from `pdfium_dart` 0.2.5's bindings, run through `PdfrxEntryFunctions.instance.compute` on pdfrx's own PDFium worker with the document handle from `useNativeDocumentHandle`. PDFium is not thread-safe; a second loader or thread would race pdfrx's calls.
- Verified against real PDFium, not a double: the NIST publication plans no OCR on any page; a Pillow-built scan, a LibreOffice typed page with a pasted photo, and a `pdfunite` mixed circular each get the expected plan; invisible (render mode 3) text and a `KrutiDev010` base font are recognised; a page renders at 200 dpi to a one-channel PNG, and a region renders at the region's size.
- A fixture finding recorded in `PROVENANCE.md`: the pasted photo at 10 × 12.5 cm covered only ~20 % of an A4 page — under the 25 % region threshold, so it would have gone unread. That threshold is a guess; it must be measured on real circulars.

### Behaviour changes worth knowing

- **A scanned PDF is no longer `notSearchable`** — it is OCRed and cited by page. So is a scanned annexure inside a typed circular, which the old whole-document gate silently dropped.
- With page signals, the gate is per page (≥ 16 chars, ≥ 15 % letters), so a short but real one-page PDF is now indexed. Without signals (PDFium failed after the text layer opened) the old whole-document 200-character gate still applies.
- One page that fails to render or OCR costs only that page; one corrupt DOCX picture costs only that picture, never the document's text.
- Every render and extracted picture is a temp file deleted once read.

### Sabotage — each break turned its tests red

Service: falling back to a garbled layer when OCR finds nothing, not deleting renders, the whole-document gate over planned pages, an OCR failure failing the document, the region OCR reading the whole page, DOCX pictures not substituted, the picture folder not removed. PDFium analysis: invisible text not counted, legacy fonts not detected, images inside form XObjects missed. DOCX reader: repeats not deduplicated, the area floor, the picture cap, each pixel floor on its own, a heading label carrying a marker, a corrupt picture failing the document.

Three checks that survived their sabotage were removed rather than kept untested: PDFium's "generated character" flag (the whitespace filter already drops those), the `TargetMode="External"` check (a linked picture's URL names no zip entry) and the empty-section and blank-line cleanup in the service (the chunker already does both). A PNG/JPEG-only rule for DOCX pictures was dropped too — it rested on nothing measured; anything the decoder can size is read.

### Real-document retrieval on a phone found the search index, not OCR, was the limit

Two real phone-scanned sale-deed bundles (18 and 20 pages; both read by OCR at ~3 s a page, English text exact against the page images) were indexed with the real Gecko embedder (42 and 41 chunks) and asked 15 messy user-style questions. Result: every top-3 hit came from the first file; the second file's chunks never came back. A **self-retrieval check** — each stored chunk searching for its own text — found only **20 of 83 (24 %)** reachable. ToStore's approximate index cannot reach most vectors once it holds a few dozen, so stored chunks were invisible to every question, whatever the wording or language.

- **Fix:** vectors now live on `DocumentChunkModel` (`List<float>`, 4 KB a chunk) and search is an exact cosine scan (`IsarDocumentVectorRepositoryImpl`), 400 rows a step. The document ToStore, its module entry and its tests are gone. The indexer writes the chunk row first and attaches the vector second, so a row with no vector is never returned and a purge removes vectors with rows (no orphans). The feature was unreleased, so nothing migrates.
- Tests: exact-search unit tests (200 chunks each find themselves; >1 read batch; ordering; dimension mismatch; purge), a flow test that every chunk of the 20-chunk NIST PDF is retrievable by its own text. Sabotage: first-batch-only scan, no sort, no `minScore`, no dimension guard, null vectors counted, no kind guard, upsert writing nothing — each red (two were initially green and the tests were strengthened).
- **Measured after (same phone, screen on, clean store, 3 documents = 93 chunks):** 91 of 93 chunks (98 %) find themselves (was 24 % of 83); the 2019 deed 5/6 questions in the top 3, the Aranya PDF 12/13 answerable ones in the top 3 (11 first), all 29 questions: right page first 17, answer text in the top 3 for 20. The second (Hindi-heavy) deed now appears in results at all; its Hindi/Hinglish questions still mostly miss (Gecko is English-centred; Devanagari OCR is noisier) — 2/6 first.
- **Speed trap:** with the phone's screen off, Android ran the app on the slow cores and embedding took 65 s a chunk instead of 12 s (`tool/rag_docs_e2e.sh` now wakes and unlocks the phone and keeps it awake while plugged in). Indexing: 42 chunks in 549 s, 41 in 532 s, 10 in 123 s.
- Interrupted device runs leave stale documents that answer alongside the fresh one (every hit duplicated, self-retrieval 0/10); the test now clears `e2e*` rows first.
- **Hybrid search built and measured.** Keyword (BM25) evidence added to the cosine, stopwords dropped, identifiers boosted, a bonus that grows with match strength. 49 answerable questions over 3 documents: Recall@1 28 → 34, Recall@3 38 → 42, Recall@5 42 → 46, MRR 0.677 → 0.773. A 180-setting grid shows a plateau (any weight 0.05–1.0 gives 34–35 at Recall@1), so the default (0.3) is not a tuned point; stopword removal is worth ~2 more right-first answers; the number boost barely matters on these questions. Per document: Aranya 16 → 21 of 23 first; 2026 deed (Hindi-heavy) 3 → 5 of 11; 2019 deed 8 → 7 of 13 first but 10 → 12 in the top 5. Note search is unchanged (same exact-scan fix still to do for notes).
- **Notes still use ToStore** and very likely have the same limit past a few dozen notes. Not changed here; worth its own issue.
- Trap-question finding: scores for a question not answered anywhere (0.72) sit inside the band of real answers (0.65–0.79), so no score cutoff separates "the document doesn't say".
- Hindi digits from the Devanagari recogniser can come out as Bengali-style look-alikes (`০.০০` for `0.00`), and form rows lose label/value pairing.

### Still open

- **Not yet run on a device.** The device group (`--plain-name 'selective OCR'`) builds scanned, mixed and pasted-photo PDFs and a DOCX with a pasted notice on the phone and runs real PDFium + ML Kit + Gecko; `--dart-define=OCR_TIMING_PDF=…` prints each page's plan with render and OCR time for a real circular. Speed must be measured before the thresholds are trusted.
- Unmeasured thresholds: 50 % mostly-image, 25 % region, 20 characters over an image, the DOCX size floors, 20 pictures per DOCX.
- Pictures in DOCX text boxes and legacy VML (`w:pict`) are not read.
- iOS unverified (no Mac).
- Not committed; pending review.

---

## 2026-09-28 — images in Shiv's RAG: on-device OCR and labels (#240) — work in progress

Text inside images on the user's own feed notes and saved notes is read with ML Kit, embedded, and cited with the image itself. No LLM at index time. Design and scope: #240 and `docs/SHIVA/rag.md` → "Images — the text inside them".

### Dependency — checked before building on it

- `google_mlkit_text_recognition` 0.17.1 (plugin MIT; the ML Kit SDK beneath it is Google's free-to-use, closed binary). A debug APK was built first, as the go/no-go gate, before any code depended on it.
- **Trap found in the plugin's own build file:** it bundles only the Latin recogniser (`implementation`) and declares Devanagari, Chinese, Japanese and Korean `compileOnly`. Without an app-level `text-recognition-devanagari` dependency (`android/app/build.gradle.kts`) and the `GoogleMLKit/TextRecognitionDevanagari` pod (`ios/Podfile`), Hindi text goes unread at runtime while the build passes. Bundled cost from Google's documentation: ~4 MB per script per CPU architecture.
- The enum value is spelled `TextRecognitionScript.devanagiri` in the plugin — caught by reading its source before the first compile.
- **Settled on a device:** Google does not document whether the Devanagari recogniser also reads Latin script. On a vivo 1933 it does — a rendered mixed notice came back as `कार्यालय आदेश / सभी कर्मचारियों के लिए / OFFICE ORDER / Leave rules 2026`, both languages intact. Both recognisers still run, and English-only pages still take the Latin result.

### Code review of the OCR diff — all eight findings verified and fixed

- **The PDF prose gate buried short real text.** Images went through `looksLikeProse`'s 200-character floor, so a sign, receipt or chat caption was recorded `notSearchable` — permanently. Images now use `kMinImageTextChars` (16) with the same letter-ratio check against noise.
- **One try/catch around both recognisers** meant a failing Devanagari pass discarded a successful Latin result and marked every image unreadable. Each pass now fails on its own.
- **One misread glyph flipped the script choice** for a whole English page. The Devanagari result now needs ≥ 3 Devanagari letters and ≥ 10 % of all letters (`isMostlyDevanagari`, unit-tested).
- Two recognisers were created and closed per image; they now load once for the app's lifetime.
- **Every reconcile scanned every cached image** — thousands of feed photos, on a pass that runs after each note write — only to discard the uncitable ones. The indexer now looks up only citable files through the cache's unique index.
- The Sources thumbnail decoded full-resolution photos (~48 MB each for a 12 MP image) for a 44-point square; it now decodes at tile size.
- Tapping an image whose cached file had since been removed opened `MediaDetailPage`, which waits forever when the cache row is gone (a latent viewer defect the gallery never reaches). The tile now says the image is no longer on the device.
- `main.dart` still called the indexer idle until a document is cached; the first launch after upgrading in fact works through the backlog of existing images.

### Test findings

- A tile test passed alone and failed in its file: every image case loaded the same path, and a load left in flight by one test was reused from Flutter's image cache by the next and never completed. Fixed by clearing the image cache between those tests — not by lengthening a delay.
- The document flow test timed out once under full-suite load (30 s default, real PDF indexing with a flush per chunk). The file now carries a two-minute timeout with the reason beside it.
- Sabotage: 13 deliberate breaks (images not a kind, no gate on OCR noise, the image gate at 200, the gate's letter ratio, no `(image)` prompt marker, OS viewer instead of in-app, no "text in image" line, saving not fetching images, DM images indexed, an image labelled like a page, the stray-glyph rule, a vanished image opening the viewer, full-resolution thumbnails) — each turned its tests red.

### Image labels — what photos without text show

- ML Kit's bundled base labeler (`google_mlkit_image_labeling` 0.16.1; 400+ general labels, confidence ≥ 0.6, top 6) turns a photo into a passage `Photo showing: dog, beach, sky`, kept **separate** from the OCR text so each matches the questions it is about. No LLM.
- **The plugin hard-depends on Firebase** — `com.google.mlkit:linkfirebase` → `firebase-common` + `firebase-iid` (Firebase Instance ID) — solely for Firebase-hosted custom models, against the project's no-Firebase rule. Found by reading the resolved Gradle dependency tree, not the plugin's README. Excluded in `android/app/build.gradle.kts` (the base labeler's code path never touches it) with a matching R8 `-dontwarn`. **Verified in the minified release code:** no `com.google.firebase` package and no `linkfirebase` class; only two dangling type references in the plugin's never-called remote branch. `firebase-components`/`firebase-encoders` remain — already present through `mobile_scanner`, ML Kit plumbing rather than Firebase services.
- Labeled images need no tile or scope change: same `DocumentKind.image`, same own/saved rule. The tile line reads "Found in image" (was "Text in image") since the passage can now be either.
- Sabotage: 5 breaks (labels ignored, labels merged into the OCR passage, labels put through the prose gate, a labeling failure hiding OCR text, an unreadable file indexed) — each red.

### Release builds were broken — found by building one

- **Every release build of this branch failed in R8** once OCR landed: `google_mlkit_text_recognition` declares the Chinese/Japanese/Korean recognisers `compileOnly` and references them from a switch UNIUN never takes. Debug builds skip R8, so the debug APK, the device tests and the full suite were all green while a release build could not be produced. Fixed with `-dontwarn` for those three packages in `proguard-rules.pro`; the release build now gets through R8 and stops only at signing (no release keystore on the dev machine — expected).
- Lesson recorded: for a native plugin, **build a release APK**, not only a debug one.

### Verified on a device (vivo 1933, Android 11)

`integration_test/document_rag_e2e_test.dart`, real Gecko embedder, real ML Kit, real PDFium — **6/6 pass**:

| Test | Result |
|---|---|
| PDF, semantic retrieval | tomato question → page 2, score 0.813 |
| DOCX, semantic retrieval | → "Growing Tomatoes", score 0.811 |
| English OCR | read exactly |
| Mixed Hindi/English OCR | both languages kept |
| Image, semantic retrieval | tomato question → the tomato image, score 0.813 |
| Photo without text | `notSearchable (noTextLayer)` in 0 s |

- The first run failed 4 of 6 — in the **test**, not the app: its hand-built `SavedNoteModel` left three `late` list fields unset. The analyzer cannot see an uninitialised `late` field, and this code runs only on a phone, so it had never executed. Fixed; the re-run passed.
- **Indexing costs ~12 s per chunk on this device** (2 chunks → 24 s; one image → 12 s). That is the embedder, not OCR, and it is what made a 17-chunk DOCX take ~4 minutes. It is also the first-launch backlog cost per image.

### Still open

- **Image labels have not run on a device yet** — the phone disconnected before the labeling device tests (`--dart-define=LABEL_PHOTOS_DIR`, four real public-domain photographs) could run. How useful the labels are in practice is therefore still unmeasured.
- The manual kit (`~/Desktop/uniun-pdf-test/IMAGE_QUESTIONS_TO_ASK.md`) — real photos in the real app, Sources tile included — has not been run.
- **Selective OCR for PDFs and DOCX** (built since — see the #242 entry above): decide per page, not per document. The current whole-document gate silently drops scanned annexure pages inside otherwise born-digital PDFs. PDFium exposes every signal needed (image coverage, invisible text render mode, unmapped unicode, font names — via `pdfium_dart`, not pdfrx's API); legacy Hindi fonts (Kruti Dev and similar) extract as letter-rich gibberish that passes today's gate. Embedding (~12 s per chunk), not OCR, dominates cost — so the rule that matters is never to index OCR text on top of a good text layer for the same area.
- iOS — the Podfile change cannot be built from the Linux machine.
- Not committed; pending review.

---

## 2026-09-28 — document RAG: PDF (#226, PR #229) and DOCX (#238) — work in progress toward v2.4.0 (unreleased)

Shiv now answers from PDFs and Word files attached to notes and cites where the answer came from — the **page** of a PDF, the **heading** of a DOCX section. Design and behaviour: `docs/SHIVA/rag.md` → "Documents (PDF, DOCX)"; specs in `docs/superpowers/specs/2026-09-19-pdf-rag-design.md` and `2026-09-26-docx-rag-design.md`.

### Dependency decisions

- **PDF via `pdfrx` (MIT, PDFium).** `syncfusion_flutter_pdf` was first proposed and rejected: it is proprietary, not permissively licensed as initially assumed. PDFium is a native asset that `flutter test` does not build, so `test/_helpers/pdfium_test_lib.dart` downloads the prebuilt the way `ensureIsarCore()` already does for Isar.
- **DOCX via `archive` + `xml`**, both already in the lockfile (promoted to direct dependencies) — no new package. The PDF spec had deferred DOCX as lacking "a strong pure-Dart reader"; for text extraction a `.docx` is a zip around `word/document.xml` and needs none.
- **`tostore` pinned to 3.1.2** — see the heap bug below. 3.1.1 and 3.1.3 are retracted; 3.5.x changes both the API (`precision`/`maxDegree` gone) and the on-disk format.

### ToStore 3.1.0 overflows the heap — found, root-caused, fixed

- Symptom: the document integration tests aborted in `malloc()`/`free()` 2 runs in 3, with a different glibc message each time (`unaligned tcache chunk`, `invalid pointer`, `invalid next size (fast)`) — real heap corruption.
- Bisected, not guessed: it survived removing PDFium, then removing the DOCX reader and its isolate, and finally reproduced in a test process containing **only ToStore**. The committed PDF-only flow test from #229 also crashed (1 run in 5), so it predates this work.
- Root cause: `SystemFfiHelper` declares `struct statvfs` as 11 × 8 = **88 bytes**; glibc — and 64-bit bionic, which shares the code path via `_isPosix => _isLinux || _isAndroid` — is **112**, ending in `__f_spare[6]`. Every periodic disk-space check `calloc`s 88 bytes and lets `statvfs()` write 112. Android is therefore on the same path in the shipped app.
- Fixed upstream in 3.1.2 (`fSpare0..5` added). Verified before pinning: 3.1.2 reads a store written by 3.1.0 unchanged (25/25 rows, every vector its own top hit); per-upsert-and-flush cost is the same (~70 ms on both — an earlier "twice as slow" reading was run-to-run noise); the full suite runs with zero native crashes.

### ToStore's vector index cannot reach every stored vector — measured, not fixed

- Querying each stored vector with itself, it is its own top hit for **100 % of 10, 80 % of 25 and 33 % of 60** — and only **55 % of 60 even with topK = every row**, so nodes are unreachable from the graph's entry point, not merely ranked low. Identical on 3.1.0 and 3.1.2. Our index config (`maxDegree: 32`, `efSearch: 64`) is not the cause: a search width above the row count should find nearly everything.
- This bounds retrieval for **notes and documents alike** as a library grows. It first surfaced as three DOCX flow tests returning no hit — initially misattributed to the one-hot test embedder, which was then shown to be only part of it. The DOCX search tests now index only the DOCX, so they test DOCX wiring rather than this limit.

### ToStore cannot delete a vector without destroying the index

- Measured on 3.1.0: deleting 1 of 3 rows makes `vectorSearch` return nothing, with no recovery across a close/reopen. The document store therefore never deletes vectors — Isar owns chunk existence, search skips hits that no longer resolve and over-fetches to absorb the orphans. A rebuild path is not implemented (#233).

### DOCX reader — rules the real files forced

Tested against two public-domain Microsoft Word templates (NIST CUI SSP, USPTO initial filing) and a LibreOffice export; provenance in `test/_helpers/fixtures/docx/PROVENANCE.md`.

- **Content controls.** The USPTO template wraps every section header in a block-level `w:sdt`; the planned reader walked only direct `w:body` children and would have silently dropped that text. It now descends into `w:sdt`/`w:sdtContent`/`w:customXml`.
- **Field codes.** The NIST template holds 330 `w:instrText` (`FORMCHECKBOX`); none reach the extracted text.
- **Heading detection by style name, not id.** LibreOffice writes `Heading 1` where Word writes `heading 1`, and German Word's id is `berschrift1`. Headings are matched case-insensitively by name or outline level, following `basedOn`.
- **Real forms often have no heading styles at all** — both federal templates mark sections with table rows or custom styles. Their chunks are cited with the file name and passage and no location line, by design.

### Code review of the DOCX diff — findings verified, then fixed

- **Out-of-memory crash loop.** The parsed XML DOM costs **~10×** the XML (measured: 20 MB → 205 MB RSS) in the app's own heap — `Isolate.run` shares the isolate group. The 50 MB cap allowed ~500 MB; an OOM before the index row is written would re-extract the same file on every launch. Capped `document.xml` at 10 MB and `styles.xml` (previously uncapped) at 2 MB.
- **Kind drift.** The document kind was re-derived from `MediaCacheModel.mime` at search time, but `_upsertCache` overwrites that mime on every download or upload of the same blob — a later sender's `application/pdf` would render a heading as "Page Annual Leave". Kind is now recorded on `DocumentIndexModel.kind` at index time and read through its unique index.
- **Received `.docx` files were not openable** (pre-existing). `downloadBySha` resolves the cache file's extension from the mime alone — downloads carry no filename — and the DOCX mime was missing from `_mimeToExt`, so other people's Word files cached as a bare `<sha256>`.
- **The prose gate was PDF-shaped.** `looksLikeProse` (≥200 chars, ≥15 % letters) catches scans and broken font encodings; a DOCX has neither failure mode, so a short memo or a table of figures was permanently `notSearchable`. The gate now applies to PDFs only.
- Also fixed: tracked moves (`w:moveFrom` is ordinary `w:t`) and text boxes inside table cells were indexed twice; a 100-char heading cap could split an emoji's surrogate pair.
- **Indexing scope was wrong, found in review with the product owner.** The indexer indexed every cached PDF/DOCX — so a DM or feed attachment the user merely *opened* became citable in Shiv, while a *saved* note's document the user never opened was never indexed (saving does not download attachments; files download only on tap). Now: only documents on the user's own feed notes (kind 1) and on saved notes are indexed, matching what Shiv's note search already covers; saving downloads the note's PDF/DOCX; unsaving purges them on the next pass. The indexer now also watches saved notes and notes, because an own note's row is written after its attachment was cached.
- **Not fixed, deliberately:** `DocumentIndexer`, a feature-folder class from #229, reads and writes Isar directly, which this repo's layer rules forbid for presentation code. Restructuring it behind a repository is a design change to the PDF PR, not a DOCX fix.

### Mistakes corrected along the way

- The 768-vs-1024 embedding dimension (#234) was first blamed for empty note retrieval. Tested on host: ToStore tolerates the mismatch. The real cause was notes never being re-embedded (#231).
- The device test's gate asserted `hasLength(1024)` against a model that emits 768, so it failed on every device before reaching its retrieval assertions. It now asserts the model loaded (`isNotEmpty`).
- The manual test kit said to wait "~10 seconds" after attaching a document. On device a 17-chunk DOCX took **~4 minutes** while Gemma 4 E2B held the phone; both questions asked in that window saw notes only and looked like a retrieval failure. Established from the device's own Isar (pulled with `run-as`) against the log timeline. `DocumentIndexer` now logs start, finish (chunk count, seconds) and not-searchable reasons for every document.

### Verification

- `flutter analyze lib/ test/ integration_test/`: no errors, no warnings. Full suite **3,342 tests** green with zero native crashes; the indexer (21) and document flow (19) suites re-run green after the logging change, and again after the scope change (indexer 31, flow 20, saved-note use cases 19).
- 12 deliberate sabotages — deleted text leaking, moved text doubled, content controls skipped, headings by id, no heading folding, emoji split, table text boxes doubled, a DOCX rendered as a page in the prompt, the tile ignoring kind, kind from mime, the prose gate on DOCX, the indexer dropping DOCX — each turned its tests red.
- On device (vivo 1933): the PDF answered with correct figures and correct page tiles; the DOCX indexed 17 chunks with the expected section labels (read from the device DB), and answers with section tiles were confirmed by manual testing.

### Still open

- **Not filed yet:** ToStore's recall limit above.
- No UI indication that a document is still indexing — only the log.
- `integration_test/document_rag_e2e_test.dart` (real Gecko, PDF + DOCX) was written but not run on a device this pass.
- iOS is unverified for both PDFium (`pdfrx` is FFI) and the DOCX isolate.
- `test/gateway/outbound/outbound_pump_test.dart` flaked again under full-suite load (a read racing an async Isar write); passes 3/3 alone. Untouched by this work.
- Follow-ups tracked under epic **#228**: #231 (notes never re-embedded), #232 (version-stamped store path), #233 (orphan rebuild), #234 (declared dimension), #235 (documents in the knowledge graph), #236 (documents in Manas-scoped chat), #237 (jump to the cited page), #238 (formats beyond PDF — DOCX now done; `.doc`, `.odt`, text and CSV remain).

---

## 2026-09-16 — work in progress toward v2.4.0 (unreleased)

### flutter_gemma 1.5.2 → 1.8.3 (issues #198, #202)

- Bumped with its engine packages: `flutter_gemma_litertlm` 1.3.1 → 1.6.3, `flutter_gemma_mediapipe` 1.0.4 → 1.0.6, `flutter_gemma_embeddings` 1.0.4 → 2.1.1, pulling `dart_sentencepiece_tokenizer` 1.3.1 → 1.4.1. `background_downloader` stays pinned at 9.5.6 — 1.8.3 requires `^9.5.6`, and 9.6.x needs Flutter ≥ 3.47 while CI runs 3.44.2.
- One breaking change, handled: embeddings 2.0.0 moved `LiteRtEmbeddingBackend` into `flutter_gemma_litertlm` with no re-export shim. Every importer already imported litertlm, so the class resolved unchanged and five now-dead `flutter_gemma_embeddings` imports were removed. No inference/session/chat API changed.
- #202 needed no code to receive: flutter_gemma no longer claims `FileDownloader().updates` (upstream PR 450), and the app never listened to that stream.

### Android GPU re-enabled — and the crash that had gated it

- The OpenCL per-turn native-heap leak (flutter_gemma #348 / #402) is fixed in `flutter_gemma_litertlm` 1.4.1 (LiteRT-LM v0.16.0). The other known Android GPU native-crash classes (#209 JNI path removed in 0.14.0, #379 cancel-vs-teardown use-after-free fixed in litertlm 1.0.4) are fixed in versions older than the ones we now ship. `lib/core/utils/llm_backend.dart` therefore prefers GPU on every platform.
- Verified on device, not assumed. Merged manifest carries `libvndksupport.so`, `libcdsprpc.so` and all three `libOpenCL*.so`; the engine reports `backend=gpu` and delegates the whole graph (`Replacing 1306 out of 1306 node(s) with delegate (LITERT_CL)`).
- Measured, Qwen3 0.6B, same device: prompt prefill **19.9 s (CPU) → ~7.9 s (GPU)** across six samples — roughly 2.5×. Decode barely moved (~2.3 → ~2.8 chunks/s) because the plugin deliberately halves the GPU kernel batch on Android (`hint_kernel_batch_size=2`, upstream #364, to keep the UI smooth). First engine create went the other way: **1.5 s → 11.5 s**, OpenCL kernel compilation; the plugin already passes a `cacheDir`, so whether a later launch reuses it is unconfirmed.
- **Known, unfixed, shipped deliberately:** on a vivo 1933 / Android 11 / Adreno device, `litert_lm_engine_create` with `backend=gpu` intermittently kills the process inside the phone's GPU driver — `SIGSEGV`, `fault addr 0x0`, thread `AdrenoOsLib`, `/vendor/lib64/libgsl.so (os_thread_launcher+48)` with `pc=0`. This is the previously uncharacterised SIGSEGV that kept Android on CPU; it now has a stack trace. It is **uncatchable** — the process dies before any Dart `catch` runs, so the call-site GPU→CPU retry cannot help — and it is intermittent: the same build completed two full generations before crashing on a later run. No matching upstream issue exists. Shipping GPU on anyway was an explicit product decision; the mitigation discussed and not built is a persisted "GPU attempt in progress" marker that pins a device to CPU after a crash.

### CPU fallback was half-broken (found while enabling GPU)

- `AIModelRunner._openActiveModel` retried with no `preferredBackend` at all. In litertlm 1.6.3 `ffiBackendFallbackOrder(null)` is `[gpu, cpu]` — the same ladder as `.gpu` — so the "CPU retry" re-attempted the GPU engine create that had just failed, and `_backend` was never set to CPU, so every later open paid for it again. Now retries with an explicit `PreferredBackend.cpu` and remembers it.
- Checked the other two fallbacks rather than assuming: MediaPipe (DeepSeek R1 `.task`) has **no** internal ladder — `setPreferredBackend` is only called when non-null, so ours is the only fallback there; `LiteRtEmbeddingBackend` has none either, so `EmbeddingService`'s own retry is the only one. Both already passed `.cpu` explicitly and were left alone.

### Foreground model downloads (Android)

- `fromNetwork(..., foreground: true)`, gated to Android via `Platform.isAndroid` — iOS gains only a notification-permission prompt, since the foreground service is an Android concept and background URLSession already keeps iOS downloads alive. Upstream keys the same decision off `Platform.isAndroid` rather than `defaultTargetPlatform`.
- Needed one manifest entry: neither flutter_gemma nor background_downloader declares WorkManager's `SystemForegroundService`, and Android 14+ requires a `dataSync` type on it. Verified in the merged manifest after a rebuild (`foregroundServiceType = dataSync`).

### Shiv echoed its own answer cue (issue #220)

- Symptom: replies like `Shiv: I am Shiv, the on-device AI assistant of UNIUN.` and, once, `Shiv: /no_think`.
- Root cause proven, not inferred. The chat path never adds `/no_think` — `PromptParts.noThink` is used only by the Nataraj, translation and Gana one-shot builders — so a chat reply containing that literal string could only come from flutter_gemma's Qwen3 append, which fires solely when `isUser == true` (`!isThinking && modelType == qwen3 && message.isUser`). Passing `isUser: true` had been added during this bump on the incorrect assumption that it was inert; it appended ` /no_think` **after** `PromptBuilder._answerCue()`'s trailing `Shiv:`, and the model copied the pattern.
- Second, older defect exposed by the first: the `Shiv:` cue (added 2026-06-22, `ac468d11`) could always be echoed, and nothing stripped it — `LlmTextSanitizer.clean` handled `<think>` blocks, tool envelopes and mojibake, but not a role label.
- Fixed model-agnostically: stop passing `isUser` at all three call sites (streaming chat, one-shot, background Gana), strip a leading echoed label in `LlmTextSanitizer.clean` so any model's echo is caught on both the streaming and final paths, and share one `AppConstants.kShivLabel` between the prompt builder and the sanitizer so they cannot drift. Deliberately conservative: leading occurrence only, first match only, and a word such as "Shivam" is untouched.
- `/no_think` was **not** added to the chat prompt to compensate. `PromptParts`' own header records that chat intentionally uses the model's native `isThinking` flag instead, and DeepSeek R1 ships `isThinking: true` — a shared always-on directive would fight it.

### Verification

- `flutter analyze lib/ test/ integration_test/` clean; full suite 3,073 tests.
- Every fix checked against its own revert: dropping the label strip fails five sanitizer tests; restoring `isUser: true` fails the one-shot test and, separately, the streaming test. The first revert check was wrong — it reverted the streaming call while the test exercised the one-shot path, which is how the missing streaming coverage was noticed.
- Android debug APK built twice (once to confirm Gradle and the manifest merge, once after the download change).

### Still open

- **Untracked by decision:** the Adreno GPU crash above.
- Issues filed for follow-ups this pass surfaced: **#217** (move DeepSeek R1 to LiteRT-LM and drop MediaPipe — Google calls the MediaPipe route "maintenance mode" and a `.litertlm` build now exists), **#218** (speculative decoding for Gemma 4; the flag is never passed today, so the model file's own default applies), **#219** (the `-gpu.litertlm` bundles exist but are undocumented and may be GPU-only, which would break the CPU fallback).
- `maxOutputTokens` is still unused anywhere, so no one-shot caps generated length; a runaway repetition runs until the KV cache fills.
- `InferenceScheduler`'s T2 soft budget can stall an extract-only queue: after one `extract` job the ratio is 100 %, the picker skips tier 2, and nothing re-pumps until another job arrives or the 5-minute window trims. Latent, predates this pass.
- `test/mesh/nip77_reconciler_test.dart` still uses the 5 s reconcile timeout that flaked in CI for `sync_integration_test.dart`. `test/gateway/outbound/outbound_pump_test.dart` flaked once under full-suite load and passes 3/3 alone.
- iOS is unverified — it cannot be built from the Linux dev machine. The bump changes iOS meaningfully: `.litertlm` there is now `raw` rather than hand-formatted, because LiteRT-LM applies the chat template itself.

---

## 2026-08-22 — work in progress toward v2.4.0 (unreleased)

### Bugs found and fixed

**The Brahma graph never refreshed after replying to a note from the node panel, issue #197**
- Root cause, confirmed by reading the widget and the BLoC rather than inferring from the report: `GraphNodePanel`'s `NoteCard.onTap` (`lib/features/brahma/graph/widgets/graph_node_panel.dart`) pushed the thread route fire-and-forget — no `await`, no reload on return. `GraphBloc` cannot self-correct either: it subscribes to exactly one collection, `deletedNoteModels` (`graph_bloc.dart:57`), so note *deletions* rebuild the graph but note *creations* never do. Replying therefore left the graph drawing its pre-navigation state: the new reply missing as a node, and the replied-to note still showing its stale `cachedReplyCount`.
- The same file already had the correct pattern for the adjacent case — the draft path (`graph_page.dart:260`) awaits its push and re-dispatches `LoadGraphEvent`. The note path simply never got it.
- Fix: `await` the push, then dispatch a **scope-preserving** `LoadGraphEvent(manasId:, manasName:)`, guarded by `bloc.isClosed` (the bloc can be closed while the thread page is up). The bloc reference is captured before the await rather than reaching through `context` afterwards.
- Deliberately **not** re-selecting the node afterwards: `_onSelect` toggles, so a `SelectGraphNodeEvent` for the already-selected node would have closed the open panel. `_onLoad` leaves `selectedNodeId` untouched, so the panel re-reads the refreshed node on its own.
- Verified the reply actually renders **with its graph edge**, end to end: `PostReplyUseCase:139` always emits `['e', parent, '', 'reply']` — even when the parent is the thread root (deliberate, per #76) — so `replyToEventId` is always populated; `replyEdgeParentIds` therefore puts the parent in the node's `refEdges`, and `buildAdjacency` draws the edge because both ends are in the node set (the parent was already a node — it is what the user tapped). `getOwnNotes` applies no top-level filter, so the reply itself loads as an own node.
- Known, correct-but-surprising interaction: while the graph is **scoped to a Manas**, a fresh reply will not appear — a new note belongs to no Manas, and scoping filters to membership (`graph_bloc.dart:169-180`). Not a defect; worth knowing before manually testing the fix.

### Test coverage added

- `test/features/brahma/graph/graph_node_panel_test.dart` (new, 7 widget tests) — mock `GraphBloc` + mock `NoteCardCubit` via `getIt`, real `GoRouter` with a stub thread route so the pop is a genuine navigation pop. Pins: thread navigation happens; no reload fires while the thread is still open; exactly one reload fires on return; the reload carries the active Manas scope; an unscoped graph stays unscoped; a bloc closed mid-navigation is never dispatched to; no `SelectGraphNodeEvent` is emitted.
- Confirmed non-vacuous: reverting the fix fails exactly the 3 reload-asserting tests and leaves the 4 guards green.
- `test/features/brahma/graph/graph_bloc_test.dart` gained 3 cases for gaps this audit surfaced — a bare `LoadGraphEvent()` **clears** an existing Manas scope (the untested mechanism behind #204); DMs (kinds 14/15) are never surfaced as graph nodes; an active search re-matches against the freshly-loaded node set.
- Full sweep green: 267 tests across `test/features/brahma/`, `test/common/widgets/note_card/`, `test/data/repositories/graph_repository_impl_test.dart`.

### Still open — filed, not fixed

Auditing the graph for siblings of #197 turned up two more reload-wiring defects, both distinct failure modes rather than repeats:

- **#204 — a reload that drops Manas scope.** `LoadGraphEvent` defaults `manasId` to null, and `_onLoad` treats null as an *explicit unscope* (`clearScope: event.manasId == null`, `graph_bloc.dart:214`). Two call sites reload with a bare event and so silently kick the user out of a scoped view: `graph_page.dart:266` (returning from the draft editor) and `graph_fab.dart:25` (creating a note from the FAB). The bare `LoadGraphEvent()` at `brahma_drawer.dart:119` is **correct** — it intentionally unscopes after the active Manas is deleted — so this must not be fixed by a blanket replace.
- **#205 — a graph-relevant write the graph is never told about.** `ManasMembershipSheet._toggle` writes the membership link and refreshes only its own list; `GraphBloc` does not watch `ManasNoteLinkModel`, so adding/removing a note from the Manas the graph is currently scoped to leaves the node set stale. Not a one-liner: the sheet is shared with the Vishnu feed via `note_card_menu.dart:95`, where no `GraphBloc` exists in the tree, so the fix is a design call (preferred option: watch the link collection in `GraphBloc`, gated on `scopedManasId != null`).

---

## How to keep this file useful

- Add an entry here for anything with real technical weight behind it: a root-caused bug, a dependency decision with a rejected alternative, a verification gap that's real and worth knowing about, a discovery that contradicts existing docs.
- Don't duplicate `CHANGELOG.md` — if there's nothing more to say than what the changelog already says, it doesn't need an entry here.
- Be honest about what wasn't verified, not just what was — a gap flagged here is more useful than a claim that turns out to be wrong later.
