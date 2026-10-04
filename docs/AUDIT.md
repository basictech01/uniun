# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

---

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
