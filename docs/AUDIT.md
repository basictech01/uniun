# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

---

## Open items carried into v3.2.0

The detailed entries up to v3.2.0 were cleared when it shipped; they remain in git history
(`git log -p -- docs/AUDIT.md`). These are the things from them, and from the v3.0.0 and
v3.1.0 lists before them, that were not resolved. All device results were measured on one
phone, a vivo 1933 (Snapdragon 710, Android 11).

**Still open from v3.0.0**
- **Android GPU crash on one device class.** On a vivo 1933 / Android 11 / Adreno phone, creating the GPU engine intermittently kills the process inside the vendor GPU driver (`SIGSEGV` in `libgsl.so`). Shipped deliberately with GPU preferred; no fix upstream yet.
- **The graph's drag and simulation feel is untested on a device** after the Obsidian rewrite. Its performance test is `integration_test/graph_simulation_perf_test.dart`.
- **Hindi/Hinglish retrieval on real scans is still weak** (the English-centred embedder and noisy Devanagari OCR); the keyword-side fix is in, the rest needs a better embedder or OCR.
- `maxOutputTokens` is unused in `InferenceScheduler`, so a runaway one-shot generation runs until the KV cache fills.
- The OCR and chart-reading thresholds in `page_ocr_plan.dart` (50 %, 25 %, 20 characters, the Word picture sizes) are unmeasured on real documents.

**Still open from 3.1**
- **iOS is unverified for everything in 3.1 and 3.2** (it cannot be built from the Linux dev machine): Gujarati and Japanese layouts, the chat open-at-first-unread list, the unread trail, the Gana dashboard, image input in chat, logout reset, the background Gana tick, and the new DM and private-group repositories. The CI iOS build only proves it compiles.
- **Gujarati is machine-assisted**; a native review of phrasing is still wanted (#271). Japanese was not natively reviewed either.
- **Notes saved before the embedding queue (3.1) were never backfilled**: they have no vector until they are saved again (#232). Re-embedding now costs about 2.2 s a note (11.7 s if long).
- **Image input in chat**: the photo is not shown in the sent bubble or kept in the conversation, one image per message, Gemma 4 E4B and prefill time/memory with a large photo were not measured, and the engine rebuild on the first image turn is untimed.
- **Unread rules differ by surface.** Groups, private groups and DMs mark a note read when it is on screen; the Vishnu feed and the surrounding feed still mark on scroll-out (the older rule).
- **Gana**: dark theme and non-English dashboard layouts are not checked on a device; the form keeps only the first Manas when an old multi-Manas Gana is edited and saved; `gana_local_engine_e2e_test.dart` (part of `all_tests.dart`) publishes one permanent note to the relay on every run; a counter write racing an edit in another isolate can lose a count.
- **Device tests**: `scheduler_model_switch_test` failed once straight after another test and passed on re-run (cause not found); its second case needs two models; the cloud device tests still need an API key; the whole `all_tests.dart` has not been run in one go.
- **Cloud**: no device test covers the UNIUN Cloud calls (#293); the free model was failing when 3.1 was written.
- **Release builds for Android, iOS and Windows run in CI** (#268), but nothing is uploaded, so store signing and a real install are still manual.

**New in 3.2**
- **Notes over 24 pieces (~16,800 characters) are only indexed up to the cap** (#296); the piece measurement used one phone (Snapdragon 710) and English text.
- **Note deletion (#291)**: un-saving a note whose original is already gone, and mesh sync removing saved rows, do not go through `purgeNotesInTxn`; their vectors are only removed by the next launch sweep.
- **The small-model cut-off (0.72) is tuned for Qwen3 0.6B only** (re-measured with note pieces in a 46-note library: answers 0.67-0.85, unrelated up to 0.81, so it does not separate cleanly there; see `docs/SHIVA/embedding.md`) on one phone and 20 questions; other models and cloud keep 0.3. A Manas-scoped search still gives its notes score 1.0 with no cut-off (only the document side uses it), and a Manas whose notes have no vector falls back to newest-first, so unrelated notes from that Manas can appear until #232 is done.
- **A scoped search over every note id (`mergeAll`, Gana's "all notes") was timed on a development machine only** (115 ms for 3,000 notes); it was not timed on the phone.
- **Two device tests fail on a phone that already holds data**: the Vishnu feed case of `manas_membership_e2e_test` (#300, a test that assumes an empty feed) and the blank-picture case of `document_rag_e2e_test` (#301, a blank image gets indexed; cause not diagnosed). Neither is a regression of 3.2.
- **The DM and private-group repository refactor (#163) was checked by unit and flow tests and by the unread and logout device tests**, not by a live two-account DM or group conversation on a device. Behaviour was kept on purpose, including that a private-group message whose id is already stored stays in the queue.
- **The domain layer still imports `features/` and `flutter/foundation` in other files**; #163 only removed Isar and `data/` from the three DM and Marmot files.

---

## How to keep this file useful

- Add an entry here for anything with real technical weight behind it: a root-caused bug, a dependency decision with a rejected alternative, a verification gap that's real and worth knowing about, a discovery that contradicts existing docs.
- Don't duplicate `CHANGELOG.md` — if there's nothing more to say than what the changelog already says, it doesn't need an entry here.
- Be honest about what wasn't verified, not just what was — a gap flagged here is more useful than a claim that turns out to be wrong later.
