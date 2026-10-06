# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

---

## 2026-10-06 — device tests run from a pre-set model

Device integration tests no longer download an AI model each run. `flutter test` uninstalls the app, which wiped the model; now it is pushed once to `/data/local/tmp/uniun_test/` (the uninstall does not touch it) and `provisionTestModel(AIModelId.…)` (`integration_test/support/test_model.dart`) copies it into the app folder, registers it and marks it active. Default model Gemma 4 E2B. Runs use `--no-uninstall` so the copy survives; `scripts/device_test.sh` wraps the push, keeping the screen on/unlocked, and the run. Usage is in `test/TESTING.md`.

- **Verified on a phone (Gemma 4 E2B)**: `gana_local_engine_e2e_test`, `flutter_gemma_bg_isolate_test` (needed the copy into the app folder — the worker isolate cannot restore a model registered from outside it), `scheduler_preemption_test` (three runs, ~2.2–2.4 s), `scheduler_model_switch_test` (passed; its second test skips with one model).
- **Found by running them for real**: the two scheduler tests had never run (they skip without a model) and failed on their own bugs — mixed `maxTokens` made flutter_gemma rebuild the model (33.5 s), a fixed 500 ms wait during a cold load, a 5-minute re-queued essay, the preempted run logged as finished first, and a 1.5 s budget from a much smaller model (now 4 s). App code unchanged; see #260.
- **Not verified**: the whole `all_tests.dart` suite in one go; the "test starting" screen was never looked at (only that it does not break the run); `scheduler_model_switch_test` failed once in ~2 s straight after another test and passed on the next run, cause not found; its second test needs two models; the cloud device tests still need an API key.
- **Not done from #88**: more device tests (only the model ones were moved over), and a CI-style runner.

## 2026-10-05 — image input in Shiv chat (first slice) — work in progress

A Shiv chat message can carry one photo when the active model reads images. Which models: `AIModelId.supportsImages` (the Gemma 4 pair only — Qwen3 0.6B and DeepSeek R1 have no vision encoder, per flutter_gemma 1.8.3's model table), carried to the UI as `LlmModelInfo.supportsImages`; cloud models report false until the gateway takes images.

- **UI**: an attach button in `ShivInputComposer`, present only for a vision model (`ChatImageSupportCubit` re-reads the active model on open and after the model sheet closes); gallery pick downscaled to 1024 px by `image_picker`; a thumbnail with a remove button; sent with the next message, then cleared. A photo is dropped, not sent, if the model changed to a text-only one after it was attached, and a photo with no text does not send.
- **Engine**: vision is fixed when the engine is created (`getActiveModel(supportImage, maxNumImages)`), so the first image turn asks flutter_gemma for a vision model, which rebuilds a cached text-only engine itself (seconds, once); the vision model is then kept for text turns until the model changes. Image turns use `createChat` — a `.litertlm` engine rejects images on `openChat`'s concurrent sessions (found on a device, not by the unit tests). Text turns are unchanged: `openChat`, `supportImage` unset.
- **Verified**: unit/widget tests at every layer (flag, cubit, composer, bloc, use case, repository, data source, runner) with the plugin behind its gateway fake; each of ten deliberate breaks turned a test red (the one that slipped, the data source dropping images, got a test).
- **Verified on a phone**: `integration_test/chat_image_turn_test.dart` on Gemma 4 E2B — a solid-red image is answered "Red", and a text turn after it works.
- **Not verified**: Gemma 4 E4B; prefill time and memory with a real photo; whether the engine re-create on the first image turn is acceptable (not timed).
- **Not built**: the photo is not shown in the sent bubble or stored in the conversation (it lives for the turn); camera capture; more than one image; how image tokens count against the prompt budget (RAG context is added as for any turn).

## Open items carried into v3.0.0

The detailed entries up to v3.0.0 were cleared when it shipped; they remain in git history
(`git log -p -- docs/AUDIT.md`). These are the things from them that were not resolved:

- **Android GPU crash on one device class.** On a vivo 1933 / Android 11 / Adreno phone, creating the GPU engine intermittently kills the process inside the vendor GPU driver (`SIGSEGV` in `libgsl.so`). Shipped deliberately with GPU preferred; no fix upstream yet.
- **Note search likely has the same limit document search had.** Notes still use ToStore's approximate index, which reached only 24 % of stored vectors once it held ~80. Documents moved to an exact scan; notes did not.
- **The graph is untested on a device after the Obsidian rewrite** (simulation timing, drag and tap feel). Its performance test is `integration_test/graph_simulation_perf_test.dart`.
- **iOS is unverified** for everything in this release (it cannot be built from the Linux dev machine): document viewing, ML Kit OCR and labeling, the graph, and the GPU/engine bump.
- **Hindi/Hinglish retrieval on real scans is still weak** (the English-centred embedder and noisy Devanagari OCR); the keyword-side fix is in, the rest needs a better embedder or OCR.
- **`InferenceScheduler`'s T2 soft budget can stall an extract-only queue** (latent, predates 3.0). `maxOutputTokens` is unused, so a runaway one-shot generation runs until the KV cache fills.
- The OCR and chart-reading thresholds in `page_ocr_plan.dart` (50 %, 25 %, 20 characters, the Word picture sizes) are unmeasured on real documents.

---

## How to keep this file useful

- Add an entry here for anything with real technical weight behind it: a root-caused bug, a dependency decision with a rejected alternative, a verification gap that's real and worth knowing about, a discovery that contradicts existing docs.
- Don't duplicate `CHANGELOG.md` — if there's nothing more to say than what the changelog already says, it doesn't need an entry here.
- Be honest about what wasn't verified, not just what was — a gap flagged here is more useful than a claim that turns out to be wrong later.
