# PDF test fixtures — provenance

Real-world PDFs committed for testing `PdfrxTextSource`. A generated PDF only
proves we can read back our own text operator; these prove pdfrx reads documents
produced by a real publishing pipeline — subset-embedded fonts, letter-spaced
headings, headers/footers, multi-page layout.

**Do not re-save, re-compress, or optimise these files.** A mutated fixture stops
being evidence about real-world PDFs. Page selection with `qpdf --pages` is the
only acceptable edit, and must be recorded here.

These are **test-only**. They are deliberately not in `pubspec.yaml`'s `assets:`
(they must never ship to users) and deliberately not in Git LFS (a CI checkout
without `lfs: true` would hand the test a pointer file, which `PdfDocument.openFile`
rejects as a confusing `null` rather than a clear error).

---

## `nist_sp800-145.pdf`

| | |
|---|---|
| Title | *The NIST Definition of Cloud Computing* (Special Publication 800-145) |
| Publisher | National Institute of Standards and Technology, U.S. Department of Commerce |
| Source | https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-145.pdf |
| Retrieved | 2026-09-23 |
| Size | 85,781 bytes |
| PDF version | 1.5 |
| Pages | **7** (confirmed with `pdfinfo` and PDFium; note `file` reports 5 for this document and is wrong) |
| sha256 | `7b0c1a9fdfc67218b8ba2098f448c100c27070db91736b3c87fed63bfa21d418` |
| Licence | Public domain. A work of the U.S. federal government, not subject to copyright in the United States under **17 U.S.C. § 105**. |

### Why this document

Chosen because it is genuinely public domain, small, and structurally close to
the government circulars this feature targets: cover page, letterhead, numbered
sections, headers and footers, multi-page prose.

Indian government sources (India Code, RBI, e-Gazette) were preferred for
subject-matter realism but were unreachable from the development sandbox
(bot/CAPTCHA challenges and timeouts). **Swapping in an Indian circular later is
supported**: drop the file in this directory, add a row here, and update the
phrase constants at the top of
`test/features/shiv/rag/extraction/pdf_text_source_test.dart`.

### Page-unique phrases used by tests

Each of these appears on exactly one page (verified with `pdftotext -f N -l N`).
They are what make the page-ordering assertion meaningful — an implementation
that concatenated every page into `pages[0]` would fail on them.

| Page (1-based) | Phrase |
|---|---|
| 1 | `Recommendations of the National Institute` |
| 3 | `Reports on Computer Systems Technology` |
| 4 | `Acknowledgements` |
| 5 | `Federal Information Security Management Act` |
| 6 | `Cloud computing is a model for enabling ubiquitous` |

Page 6 carries the document's actual definition of cloud computing. That makes it
the natural target for the retrieval tests: a query like *"what is cloud
computing?"* must come back with the page-6 chunk, which is what proves the
embeddings are doing semantic work rather than the plumbing merely running.

**Avoid asserting on** `C O M P U T E R` / `S E C U R I T Y` (page 2) — the source
sets them letter-spaced, so the extracted text contains single characters
separated by spaces. Assertions must also survive curly quotes (page 5), which is
what `normalizePdfText()` in `test/_helpers/pdf_fixtures.dart` is for.

---

## Selective-OCR fixtures (#242)

Built for this repository to exercise the per-page OCR decision with a real PDF
producer — each page's structure is known, so the expected plan is known.
Photo source: `record_room_notice_photo.jpg`, a rendered notice photographed-style
image made for the manual test kit (no third-party content).

| File | Built with | Structure | Expected plan |
|---|---|---|---|
| `scanned_notice.pdf` | Pillow: the notice photo, grayscale, alone on one page (150 dpi) | 1 page, one full-page image, **no text layer** | OCR the whole page |
| `typed_report_with_pasted_notice.pdf` | LibreOffice 24.2 from `typed_report_with_pasted_notice.source.html` | 1 A4 page: ~700 characters of typed text + the notice pasted at 12.5 × 15.5 cm (~31 % of the page) | keep the text layer and OCR the image region |
| `mixed_circular_with_scanned_annexure.pdf` | LibreOffice (`…source.html`) for page 1, `pdfunite` with `scanned_notice.pdf` | page 1 typed, page 2 scanned | page 1 text layer, page 2 OCR |

sha256:
- `scanned_notice.pdf` — `0e599cbf914cc30c9b57366e3c52b2c234ebfdefc9ae23a004b5512eef8ed8cc`
- `typed_report_with_pasted_notice.pdf` — `d2fc3ad18e22bd75a598b4fc9ce792920764f3bd7242f52d18d122fbc38cdfae`
- `mixed_circular_with_scanned_annexure.pdf` — `957010123eac5e5f54697e1d4a0fa03409b5b6b5680dc7088fe8a79b07d957cc`

Measured while building: at 10 × 12.5 cm the pasted notice covered only ~20 % of
the page — under the 25 % region threshold, so it would have been left unread.
That threshold is unmeasured on real documents (#242: measure on a device
first); the fixture uses the larger size to exercise the region path.

## Aranya land-records review (device retrieval test)

`aranya_land_records_review_q2_2026.pdf` — a fictional 8-page government review
(state "Aranya", invented figures) built for `integration_test/document_rag_e2e_test.dart`
by `aranya_land_records_review_q2_2026.build.py` (LibreOffice for the typed pages,
Pillow for the skewed scan, the phone-photo notice and the Hindi/English scan,
matplotlib for the chart; `pdfunite` joins them). One page type each: typed,
typed + photographed notice, scanned order, logo/signature + Hindi, chart,
blank scan, Hindi/English scan, table. 385 KB — Over the 300 KB guideline
because three fonts and a photo are embedded; scans are downsampled to keep it
there. No real person or record. `aranya_land_records_review_q2_2026.queries.json`
holds 16 messy user-style questions (typos, Hinglish, Hindi script, fragments)
with the page each answer is on. Run with `tool/rag_docs_e2e.sh <device-id>`.

`aranya_hindi_hinglish_keyword.retrieval.json` is a text-only, fictional
companion fixture covering Devanagari and Bengali digit look-alikes, nukta,
an allow-listed chandrabindu/anusvara spelling variant and a Devanagari joiner
variant. Its `legacy` metrics were measured with the exact-token tokenizer from
the parent commit.
