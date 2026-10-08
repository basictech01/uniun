 > ⚠️ **Historical "basics" primer.** This explains the core RAG idea in the simplest possible terms and predates the actual build — some details below (embeddings stored directly on `NoteModel`, "future: migrate to sqlite-vec") don't match what shipped. For the real, current implementation (ToStore vector DB, GraphRAG expansion, per-model prompt budgets), read `docs/SHIVA/graphrag.md` and `docs/SHIVA/SHIV_AI.md`'s RAG Pipeline section instead. Keep reading below only for the plain-English mental model.

 What is RAG?
                                                                                
  RAG = Retrieval Augmented Generation                      
                                                                                
  Without RAG, Shiv only knows what the LLM was trained on. It has no idea what 
  YOU wrote in your notes.
                                                                                
  With RAG, Shiv can answer questions like:                                     
  - "What did I write about machine learning?"
  - "Summarize my notes on project X"                                           
  - "Find everything I saved about Nostr"                   
                                                                                
  ---                                                                           
  The Core Idea
                                                                                
  Normal LLM:                                               
    User asks → LLM answers from training data only                             
                                                                                
  RAG:                                                                          
    User asks → Find relevant notes → Give notes + question to LLM → Better     
  answer                                                                        
  
  The LLM's context window becomes a temporary "working memory" that you fill   
  with the user's own notes before asking the question.     
                                                                                
  ---                                                       
  How It Works — Step by Step
                             
  Step 1: When a note is SAVED → generate embedding
                                                                                
  User saves a note
          ↓                                                                     
  Note content → Embedding Model → [0.12, -0.45, 0.89, ...] (384 numbers)       
          ↓                                                                     
  Store: NoteModel.embedding = [0.12, -0.45, 0.89, ...] in Isar                 
                                                                                
  An embedding is just a list of numbers that captures the semantic meaning of  
  the text. Notes about similar topics produce similar number patterns.         
                                                                                
  ---                                                       
  Step 2: When user asks Shiv a question → find relevant notes

  User types: "what did I write about relays?"
          ↓                                                                     
  Same Embedding Model → [0.08, -0.41, 0.92, ...] (question as numbers)
          ↓                                                                     
  Compare against ALL saved note embeddings in Isar         
          ↓                                                                     
  Cosine Similarity:                                                            
    Note A (about relays) → similarity: 0.91  ✅ very relevant
    Note B (about Python)  → similarity: 0.23  ❌ not relevant                  
    Note C (about Nostr)   → similarity: 0.78  ✅ relevant                      
          ↓                                                                     
  Pick top 3-5 most similar notes                                               
                                                                                
  Cosine similarity = a formula that measures how "close" two vectors are.      
  Result is 0 (unrelated) to 1 (identical meaning).                             
                                                                                
  ---                                                       
  Step 3: Build the LLM prompt with context
                                           
  final prompt = """
  You are Shiv, a personal AI assistant.                                        
  Use the following notes from the user to answer their question.
                                                                                
  --- USER NOTES ---                                        
  Note 1: ${relevantNotes[0].content}                                           
  Note 2: ${relevantNotes[1].content}                                           
  Note 3: ${relevantNotes[2].content}
  --- END NOTES ---                                                             
                                                            
  User question: what did I write about relays?                                 
                                                            
  Answer based on the notes above:                                              
  """;                                                      

  ---
  Step 4: LLM streams back the answer
                                     
  The LLM reads the injected notes + the question and generates a grounded
  answer. It's not guessing from training data — it's reading the user's own    
  notes.
                                                                                
  ---                                                       
  The Two Models Needed
                                                                                
  ┌────────────────┬─────────────────┬──────────────────────────────────────────┐
  │     Model      │       Job       │                Size                      │
  ├────────────────┼─────────────────┼──────────────────────────────────────────┤
  │ Embedding      │ Converts text   │ ~80MB (all-MiniLM-L6-v2) — bundled       │
  │ model          │ to vector       │ always available, no download needed      │
  ├────────────────┼─────────────────┼──────────────────────────────────────────┤
  │ LLM (user-     │ Generates the   │ 586MB–4.3GB depending on model chosen     │
  │ selected, via  │ answer          │ flutter_gemma ^1.5.1                      │
  │ flutter_gemma) │                 │ GPU-accelerated on Android + iOS          │
  │                │                 │ Downloaded once on first Shiv open        │
  └────────────────┴─────────────────┴──────────────────────────────────────────┘

  These run separately. The embedding model runs fast, synchronously. The LLM
  (flutter_gemma) runs slower, streams tokens via getResponseStream().

  For available LLM options see docs/SHIV_AI.md — Model Selection section.
                                                                                
  ---                                                       
  The Challenge: Vector Search in Isar
                                                                                
  Isar has no native vector search. So how do you find similar notes?
                                                                                
  For small corpus (<5,000 saved notes):                                        
  Load all embeddings from Isar into memory                                     
  For each → compute cosine similarity with query vector                        
  Sort by score → pick top K                                                    
  This is fast enough in Dart for small collections.
                                                                                
  For large corpus (future):                                                    
  - Migrate to sqlite-vec (SQLite vector extension) or usearch                  
  - Or maintain a separate HNSW index on device                                 
                                                            
  For UNIUN's use case (personal notes app), most users will have <1,000 saved  
  notes. In-memory Dart computation is totally fine.                            
   
  ---                                                                           
  Full Flow Diagram                                         

  SAVE TIME:
  Note saved → Embedding model → vector → stored in Isar (NoteModel.embedding)
                                                                                
  QUERY TIME:
  User question                                                                 
        ↓                                                                       
  Embedding model → query vector
        ↓                                                                       
  Load all saved note embeddings from Isar                  
        ↓
  Cosine similarity → rank notes
        ↓                                                                       
  Top 3-5 notes retrieved
        ↓                                                                       
  Build prompt: [system prompt + notes + question]          
        ↓                                                                       
  LLM → streams answer token by token
        ↓                                                                       
  ShivStreamingText widget shows it live                                        
   
  ---                                                                           
  Why Only Saved Notes?                                     
                                                                                
  Because:
  1. Regular notes get cleaned up after 7 days (CleanupManager)                 
  2. The user explicitly chose to save these — they're the "important" ones
  3. Generating embeddings for every note ever seen would be wasteful      
  4. Saved notes = the user's personal knowledge base                           
                                                                                
  ---                                                                           
  What Shiv Can Do With This                                                    
                                                                                
  - "Summarize everything I saved this week"                
  - "What are my notes about <topic>?"                                          
  - "Do I have anything related to <question>?"
  - "Find contradictions in my notes about <topic>"                             
  - Future: RAG over referenced notes graph (follow e tags to pull thread
  context)                                                                      
                                                            
  ---                                                                           
  Build Sequence for Shiv                                   

  1. Embedding model integration  (runs offline, no relay needed)
  2. Save note → generate + store embedding                                     
  3. Query pipeline: embed → cosine sim → top-K                                 
  4. Prompt builder (inject notes into LLM context)                             
  5. ShivAIBloc: handle streaming response                                      
  6. Chat UI: ShivStreamingText (token-by-token render)                         
  7. Model selection page (AIModelSelectionPage — see docs/SHIV_AI.md)                 
                                                                                
  This is why Shiv is built last — it needs:
  - Vishnu (so notes exist)
  - Brahma (so user can create notes)
  - Saved notes (so embeddings exist)

  ---
  Next Level: GraphRAG

  Standard vector RAG only finds notes that are semantically similar to the query.
  GraphRAG also traverses the knowledge graph — following note references (e tags),
  topic links (t tags), and reply chains to find connected context that vector
  similarity would miss.

  UNIUN's knowledge graph (already built via Nostr tags) can be used directly as
  a GraphRAG graph — no extra entity extraction needed.

  See docs/graphrag.md for full details.                       
                                                            
---

## Notes: how a note gets its vector (#231)

A note is queued in a `PendingEmbedding` table and embedded by `NoteEmbeddingWorker`, one at a time and newest first, with the row deleted only after its vector is stored. Every embed (note, PDF/DOCX chunk, Shiv question) goes through one gate that serves a question first. Full explanation, diagram, rules and measurements: [`embedding.md`](embedding.md).

---

## Documents and images (PDF, DOCX, images)

A PDF, a Word (`.docx`) file or an **image** attached to a note has its text
extracted, chunked and embedded, so Shiv can answer from it and cite where it
came from — the **page** of a PDF, the **heading** of a DOCX section, or the
**image itself**, whose text is read by on-device OCR. Designs:
`docs/superpowers/specs/2026-09-19-pdf-rag-design.md` (PDF) and
`docs/superpowers/specs/2026-09-26-docx-rag-design.md` (DOCX).

`DocumentKind` (`lib/core/enum/document_kind.dart`) is the single answer to
"which mimes are documents": the indexer's filter, the vector search and the
citation resolver all ask it. `image` matches every `image/*` mime by prefix.
Legacy `.doc` and `.odt` are not documents — they attach and open, and are
never read.

### How a document becomes searchable

```
 You attach a PDF or DOCX to a note and publish
                │
                ▼
   MediaCacheModel row written      (sha256 → /path/file, its mime)
                │
                │   DocumentIndexer watches this table
                ▼
 ┌──────────────────────────────────────────────────────────┐
 │ 1. READ    by DocumentKind:                              │
 │            PDF  → PdfrxTextSource → PDFium, pages 1..N   │
 │                   → labels "1", "2", …                   │
 │                   each page planned: text layer, OCR the │
 │                   page, OCR one pasted image, or skip    │
 │            DOCX → ArchiveDocxTextSource (zip + XML, in   │
 │                   Isolate.run) → one section per heading │
 │                   → labels "Annual Leave", …, or ""      │
 │                   large pictures OCRed where they sit    │
 ├──────────────────────────────────────────────────────────┤
 │ 2. GATE    looksLikeProse()                              │
 │            PDF: per page, ≥16 chars AND ≥15% letters     │
 │            (whole document ≥200 chars if PDFium gave no  │
 │            page signals)                                 │
 │            nothing left → notSearchable, stop            │
 │            YES ↓                                         │
 ├──────────────────────────────────────────────────────────┤
 │ 3. CHUNK   chunkSections() — ≤700 chars, never across    │
 │            a page or section boundary                    │
 │            ★ every chunk KEEPS its label ★               │
 ├──────────────────────────────────────────────────────────┤
 │ 4. EMBED   EmbedAndStoreChunkUseCase, per chunk          │
 │            Gecko embedder → vector                       │
 │            (embedding only — no LLM call)                │
 ├──────────────────────────────────────────────────────────┤
 │ 5. STORE   text + vector → Isar DocumentChunkModel       │
 │            (row first, then the vector is attached)      │
 │            keyed  "<sha256>:<ordinal>"                   │
 ├──────────────────────────────────────────────────────────┤
 │ 6. MARK    DocumentIndexModel = indexed   ← written LAST │
 │            so a crash retries rather than lying          │
 └──────────────────────────────────────────────────────────┘
```

### How a citation knows its page

The page number is **carried, never recomputed**. The chunk id is the thread that
ties the vector store to the text, and the text to the page:

```
 CHUNK ID  =  "<sha256 of the pdf>:<chunk number>"      e.g.  "a3f9…:12"
                       │                    │
                       │                    └── which chunk
                       └── which document

 ┌── one Isar row holds everything ──────────────────────────────┐
 │  DocumentChunkModel                                           │
 │  ──────────────────                                           │
 │  sha256  : "a3f9…"     ordinal : 12                           │
 │  label   : "5"   ← THE PAGE                                   │
 │  text    : "Expense Reimbursement…"                           │
 │  vector  : [0.02, -0.11, …]   (768 float32)                   │
 └───────────────────────────────────────────────────────────────┘

 "what is the deadline for expense claims?"
            │
            ▼
   embed the question → query vector
            │
            ▼
   exact cosine scan of every chunk vector  →  "a3f9…:12"
            │
            ▼
   parseChunkId()  →  (sha256 "a3f9…", ordinal 12)
            │
            ▼
   Isar lookup on the (sha256, ordinal) composite index
            │            →  label "5",  text "Expense Reimbursement…"
            │
            ├──────────► into the PROMPT:  "(p.5) Expense Reimbursement…"
            │                               the model sees the page too
            │
            └──────────► id carried in RagMessage.sourceChunkIds
                                  │
                          user taps "Sources"
                                  │
                                  ▼
                    DocumentSourceRepository.resolve(id)
                        title : filename of the attaching note
                        label : "5"          ──►  tile shows "Page 5"
                        path  : cached file  ──►  tap opens the PDF
```

The vector store never needs to know what a page is — it only returns an id, and
every later step carries the label that the chunker stamped on at split time.

### Why a DOCX cites a heading, not a page

A Word file has no fixed pages: pagination depends on fonts, paper size and the
app rendering it. "Page 5" is true everywhere for a PDF and nowhere for a DOCX,
and a wrong page number is worse than none. So a DOCX chunk is labelled with the
nearest heading above it and rendered differently at both ends:

| | PDF | DOCX |
|---|---|---|
| Label | `"5"` | `"Annual Leave"` · `""` above the first heading |
| Prompt line (LLM-facing, English) | `• (p.5) …` | `• (Annual Leave) …` · `• …` when empty |
| Sources tile | PDF icon · "Page 5" | document icon · "Section: Annual Leave" · no line when empty |

The kind is recorded on `DocumentIndexModel.kind` when the document is indexed
and read back through its unique index when a hit or citation is resolved. It is
deliberately not re-derived from `MediaCacheModel.mime`: every download or upload
of the same blob overwrites that mime with whatever the sender claimed, and a
heading must never render as a page.

What `ArchiveDocxTextSource` reads, and why each rule exists:

- **Headings by style *name*** (`heading 1`–`9`, `Title`, any case) or an
  `outlineLvl` 0–8, following `basedOn` — never by style id. Ids are localised
  (German Word writes `berschrift1`) and free-form in other editors; LibreOffice
  names the style `Heading 1` where Word writes `heading 1`.
- **Content controls (`w:sdt`) are walked into.** Word templates wrap whole
  paragraphs in them — the USPTO fixture's every section header lives in one —
  and a reader visiting only direct `w:body` children silently drops that text.
- **Skipped:** `w:delText` (tracked-change deletions, still in the file),
  `w:instrText` (field codes — the NIST fixture has 330 `FORMCHECKBOX`), text
  boxes (their fallback copy would repeat them), headers, footers, footnotes.
- **Tables** become `a | b` lines inside the section they sit in.
- A heading with no body of its own folds into the next section, so
  `Chapter 3` directly above `3.1 Scope` yields no title-only chunk.
- Runs in `Isolate.run` — XML parsing is synchronous Dart and would stall the UI.
- A `document.xml` over 10 MB uncompressed is refused and a `styles.xml` over
  2 MB ignored: these files arrive from other people over relays, and the
  parsed DOM costs ~10x the XML in the app's own heap (`Isolate.run` shares the
  isolate group), so an unbounded file could crash the app on every launch.
- **Skipped too:** `w:moveFrom` — a tracked move keeps its old copy as ordinary
  `w:t`, which would index the moved text twice.

Real-world Word forms often use **no heading styles at all** (both committed
federal templates mark sections with table rows or custom styles); their chunks
are cited with the file name and passage and no location line.

**Pipeline** — `DocumentIndexer` (`lib/features/shiv/rag/indexing/`, main isolate,
started in `main.dart`) watches `MediaCacheModel` and reconciles it against
`DocumentIndexModel` by SHA-256:

```
citable document cached, no index row      -> index it
index row, document not cached or no longer
  citable                                  -> purge its chunks and index row
```

**Which documents Shiv may cite** — the same notes Shiv's note search covers:

| Document attached to | Indexed |
|---|---|
| one of your own **feed notes** (kind 1) | yes |
| a **saved note** — any kind, including a saved DM or group message | yes, **whether or not you opened it**: saving downloads its PDF/DOCX and images (`SaveNoteUseCase`) |
| someone else's feed note, a group, or a DM, merely opened | no — opening a file is not asking Shiv to learn it; saving is |
| your own DM or group message | no |

Unsaving the note removes its document from Shiv on the next pass, unless another saved note carries the same file. The indexer watches the media cache, saved notes and notes (debounced 500 ms), because an own note is written after its attachment was already cached. A saved note's document that fails to download (offline) is indexed when the user next opens it.

Reconciling state rather than reacting to a "blob arrived" event is what makes
this correct: `MediaRepositoryImpl._upsertCache` has **four** call sites (upload,
download cache-hit, fresh download, staged draft) and runs inside a write
transaction where embedding cannot be awaited; deletion happens in two more
places, one of them `CleanupManager` in the Gateway isolate, which deletes cache
rows directly. A crash mid-index is retried because the index row is written
**last**.

Vectors live on the chunk rows themselves (`DocumentChunkModel.vector`, 4 KB
each), never in the note ToStore. Embedding goes through `EmbeddingQueue`,
bounding concurrency at 2.

**Retrieval** — unscoped chat only. `RagPipeline` searches notes and chunks
independently (chunk top-K = `max(1, topK ~/ 2)`); chunks skip memory and graph
expansion, since they are not graph nodes. `PromptBuilder` renders them under
`## Relevant Documents`, and `RagMessage.sourceChunkIds` carries them to the
Sources sheet, which resolves them on open via `DocumentSourceRepository`.

A Manas-scoped chat never searches documents: it scopes by note membership, and
a document blob has none (#236).

### Images — the text inside them, and what they show

An image is read twice, both **on device**, and each result goes through the
same chunker, embedder, store and citation path as a document. No LLM is
involved at index time.

- **Its text** — OCR (`MlKitOcrTextSource`, `lib/data/datasources/ocr/`, ML Kit
  Text Recognition v2).
- **What it shows** — labeling (`MlKitImageLabelSource`,
  `lib/data/datasources/image_labels/`, ML Kit's bundled base labeler, 400+
  general categories, confidence ≥ 0.6, top 6). The labels become one passage,
  `Photo showing: dog, beach, sky` (English, LLM-facing, not localised).

Text and contents are **separate passages**, so "the photo of my dog" matches
the labels and "what does the notice say" matches the OCR text. A photo with
no readable text is still indexed by its labels; one with neither is
`notSearchable`.

- **Two recognisers, both bundled:** Latin and Devanagari, ~4 MB each per CPU
  architecture (so ~8 MB per install from the Play Store). ML Kit's Flutter
  plugin bundles only Latin and declares the rest `compileOnly`, so the app
  adds `text-recognition-devanagari` in `android/app/build.gradle.kts` and
  `GoogleMLKit/TextRecognitionDevanagari` in `ios/Podfile`.
- **Both run on every image, independently.** Whether the Devanagari model
  also reads Latin text is undocumented, so its result is used only when
  Devanagari is a real part of it — at least three Devanagari letters and a
  tenth of all letters (`isMostlyDevanagari`), so one misread glyph cannot flip
  an English page — and the Latin result otherwise. Each pass has its own
  failure handling: a missing or failing Devanagari recogniser still leaves
  English readable. The recognisers load once and live for the app's lifetime.
  On a device the Devanagari recogniser also reads Latin: a rendered mixed
  Hindi/English notice came back with both languages intact (the device test
  requires it).
- **Label** `''` — an image has no pages or headings. The prompt marks the
  passage `• (image) …` so the model does not present OCR text as something the
  user wrote. The Sources tile shows a **thumbnail** and "Found in image", and
  tapping opens the in-app image viewer (`AppRoutes.mediaDetail`) — or says
  the image is no longer on the device, since that viewer waits forever for a
  cache row that is gone. The thumbnail decodes at tile size, not the photo's.
- **A gate, with a much lower floor than PDFs:** at least
  `kMinImageTextChars` (16) characters and the usual 15 % letters. A sign, a
  receipt or a chat caption is short and genuine, and the PDF floor of 200
  would bury it for good; the letter ratio still rejects OCR noise. A photo
  without text is recorded `notSearchable` once, never re-read. Such a photo is still found through its note's text, which is
  embedded like any note.
- **Same scope as documents:** only images on the user's own feed notes and on
  saved notes; saving a note downloads its images for this.
- **The first launch after upgrading works through a backlog:** every image
  already on the user's own and saved notes is read and embedded, one at a
  time, in the background. The indexer looks up only citable files through the
  cache's unique index, never a scan of every cached image.
- ML Kit runs only on Android and iOS — never under `flutter test`. CI covers
  images through `FakeOcrTextSource`; `integration_test/` runs real OCR.

**Labeling ships without Firebase.** `google_mlkit_image_labeling` hard-depends
on `com.google.mlkit:linkfirebase` — which brings `firebase-common` and
`firebase-iid` — solely for Firebase-hosted custom models. UNIUN uses only the
bundled base labeler, so `android/app/build.gradle.kts` excludes `linkfirebase`
and `proguard-rules.pro` tells R8 the unused branch's references are expected.
The `firebase-components`/`firebase-encoders` utility libraries that remain
were already in the app through `mobile_scanner`; they are ML Kit plumbing, not
Firebase services.

Not built: CLIP-style image embeddings (TinyCLIP is MIT but weak; MobileCLIP's
weights are research-only; SigLIP 2 is too large for a phone), and captions
from a vision LLM.

**Indexing is not instant, and says so in the log.** Each chunk is embedded on
device, competing with the LLM for the phone: a 17-chunk DOCX took ~4 minutes on
a vivo 1933 while Gemma 4 E2B was extracting knowledge from the note it was
attached to. A document becomes searchable only when its index row is written,
so a question asked mid-index sees notes only — which looks exactly like a
retrieval bug. Watch it with `adb logcat | grep DocumentIndexer`:

```
📄 DocumentIndexer: indexing 62e59f9e (docx)…
📄 DocumentIndexer: indexed 62e59f9e (docx) — 17 chunks in 231s
📄 DocumentIndexer: 3f9a01c2 (pdf) not searchable (noTextLayer) in 2s
📄 DocumentIndexer: embedder not ready, will retry 62e59f9e (docx)
```

Nothing in the app UI shows indexing progress yet.

**Scans are read by OCR, page by page** — see *Scanned pages and pasted
pictures* below. A PDF where no page yields readable text, even after OCR, is
recorded `notSearchable`: the document still attaches and opens, it is simply
never cited. The same holds for a DOCX that cannot be read (not a zip,
password-protected, malformed XML) or holds no text at all. The prose gate itself
is **PDF-only**: it catches scans and broken font encodings, which a DOCX cannot
have, so a short DOCX memo or a table of figures is indexed. An embedder that is not ready is different — it leaves the
document *unindexed* so a later reconcile retries it.

### Scanned pages and pasted pictures (selective OCR, #242)

OCR costs about a second a page and every chunk it adds costs an embedding, so
only the pages and pictures that need it are read. OCR text never lands on top
of a good text layer for the same area — that would index each passage twice.

**PDF: one plan per page** (`planPage`, `lib/features/shiv/rag/extraction/page_ocr_plan.dart`),
from what PDFium reports about the page (`PdfPageSignals`, read in
`pdfium_page_analysis.dart` on pdfrx's own PDFium worker — pdfrx exposes none
of it):

| Page | Plan |
|---|---|
| < 10 characters and no image ≥ 25 % of the page | skip |
| garbled layer: < 15 % letters, > 10 % unmapped glyphs, or a legacy Hindi font (Kruti Dev, DevLys, Chanakya…) | OCR the page, drop the layer |
| images ≥ 85 % of the page and < 200 characters (a scan) | OCR the page |
| images ≥ 50 % and < 200 characters (a photo with a header line) | OCR the page, keep the longer of the two readings |
| one image ≥ 25 % of the page with < 20 characters drawn over it | keep the layer **and** OCR just that image |
| otherwise | the text layer |

A scan with a good invisible OCR layer (≥ 200 real characters) is trusted, not
re-read. Legacy Hindi fonts are caught by name because their text extracts as
Latin gibberish that passes the letter ratio. On a rotated page the image rule
reads the whole page instead of mapping the rectangle.

A page to OCR is rendered at 200 dpi (long side capped at 3000 px) to a
grayscale PNG, read by `OcrTextSource`, and deleted. Each page is gated on its
own (≥ 16 chars, ≥ 15 % letters), so a page OCR could not read — or a render or
OCR failure — costs only that page.

**DOCX: large pictures only.** With a picture directory, the reader writes out
each embedded picture drawn at least 2.5 in wide and about 5 × 4 in in area,
with at least 500 × 100 pixels, and leaves a marker in its section's text; the
service swaps each marker for the picture's OCR text, so it keeps its place
and its heading. Logos, signatures, vector drawings (EMF/WMF/SVG), linked
pictures and repeats of one picture are skipped; at most 20 per document.

**The thresholds are unmeasured.** The 85 % scan and 10-character/10 % unmapped
figures come from published tools (bibr, Apache Tika); the 50 %, 25 %,
20-character and DOCX sizes are guesses. Measure on real circulars on a phone
before trusting them — the device test prints each page's plan and its render
and OCR time:

```
flutter test integration_test/document_rag_e2e_test.dart -d <device-id> \
  --plain-name 'selective OCR' \
  --dart-define=OCR_TIMING_PDF=/sdcard/Download/circular.pdf
```

### Opening a citation (#237)

Tapping a document source opens `DocumentViewerPage`
(`lib/features/shiv/document_viewer/`) at the cited place, not at the top:

- **PDF** — pdfrx's `PdfViewer` on the cited page (`initialPageNumber`), with the
  start of the cited passage highlighted on that page. The chunk is the PDF's own
  extracted text, so its first 12 words are searched in the viewer's text for the
  cited page only (whitespace-tolerant: the viewer re-flows lines), and the match
  is painted. A page that was read with OCR has no text layer, so it gets the
  page but no highlight. Pages are placeholders until loaded, so the page is
  loaded before its text is read; pdfrx's multi-page `PdfTextSearcher` was tried
  first and found nothing here, so the single cited page is searched directly.
- **Word** — no Word renderer exists in the app, so the view is built from what
  the reader already extracts: one block per heading section, scrolled to the
  cited section and tinted. Paragraphs are text; a table (extracted as
  `cell | cell` rows) is drawn as a grid, scrollable sideways; a large picture
  (the same ones the reader writes out for OCR) is drawn inline. The section is
  found by heading, and by the start of the cited passage when headings repeat
  (`locateSection`). Styling, small pictures (logos, signatures) and page layout
  are not shown, and a note says so. A prose line that uses a spaced ` | ` looks
  exactly like a table row and is drawn as one.
- **Both** — an "Open in another app" action hands the file to the OS viewer,
  which is the better place to *read* rather than check. A file that left the
  cache since the answer shows a message instead of a blank viewer. Images still
  open in the media viewer.

The citation travels as the route's `extra` (a path cannot carry the heading); a
cold deep link has none and is redirected home. iOS rendering through pdfrx is
unverified (no Mac here).

### Constraints worth knowing before changing this

**Chunks are capped at 700 characters** because `PromptBudget` gives the
smallest local model 1024 tokens total and `buildUserMessage` drops any section
that would overshoot. A page-sized chunk would make the document silently vanish
from the prompt.

**Search is an exact scan, not an index.** `IsarDocumentVectorRepositoryImpl`
compares the question with every chunk's vector (read 400 rows at a time,
keeping the best K). ToStore's approximate index was tried first and dropped:
on a phone only **20 of 83 chunks** (24 %) found themselves as their own top
hit, so a stored chunk could never come back for any question — every hit came
from the first file indexed and none from the second. A scan is exact, and at a
few thousand 768-dim vectors it costs milliseconds. Purging a document deletes
its chunk rows, and its vectors with them — so there are no orphaned vectors.
The document feature had not shipped, so no stored data needed migrating. If a
library ever reaches hundreds of thousands of chunks, revisit an index — an
exact-recall one.

**ToStore is on 3.5.1** (#232). 3.1.0 declared `struct statvfs` as 88 bytes where glibc and 64-bit bionic use 112 (random `malloc`/`free` aborts); 3.1.2 fixed that and was pinned for a while. 3.5.1 also replaces the vector index: see below. 3.5 removed `precision`, `maxDegree` and `efSearch` from the schema (it owns them now), and a store written by 3.1.x opens under 3.5 with every vector present but an empty index, so search finds nothing. So the store path carries a format number (`kNoteVectorStoreFormat`, `tostore_<dim>d_v<N>`): bump it when an upgrade changes the format and the store opens empty at a new path.

**Ranking is meaning plus keywords (hybrid).** Meaning-only search blurs exact
things — a helpline number, a registration number, a name — because such tokens
look alike to an embedder. `HybridRanker` (`lib/core/text/hybrid_ranker.dart`)
adds keyword evidence to each chunk's cosine similarity: BM25
(`lib/core/text/bm25.dart`) over the question's words, with

- **keyword-only normalisation on both sides of scoring**: lower-casing;
  Devanagari and Bengali OCR digit look-alikes mapped to ASCII; common
  Devanagari nukta forms folded; the allow-listed Hindi spelling pairs
  (`कहाँ`/`कहां`, `आँख`/`आंख`, `माँ`/`मां`, `गाँव`/`गांव`, `चाँद`/`चांद`)
  unified without a global nasal-mark fold; zero-width joiners removed only
  between Devanagari characters and kept as token boundaries in other scripts,
- **stopwords dropped** (English, Hinglish and Hindi function words — and, or,
  the, kya, hai, है — `lib/core/text/stopwords.dart`),
- **identifiers boosted** (a word of 3+ characters with a digit counts double),
- **a saturating bonus**: `weight × s / (s + 2)` for a chunk with BM25 score `s`,
  so a weak match on a common word adds little and a strong match on rare words
  nearly the full `weight` (0.3). The returned `ScoredChunk.score` stays the
  cosine.

Normalisation happens only inside the tokenizer, for the question and each
chunk at ranking time. Stored chunk text and text sent to Gecko are unchanged,
so enabling or changing this layer does not require re-indexing or re-embedding
documents.

Only the question's words are scored, in the same pass that computes cosines.
Chosen on a phone-indexed set of 3 documents, 93 chunks and 49 answerable
questions (typos, Hinglish, Hindi script, fragments), scored by Recall@1/3/5 and
MRR where a chunk is relevant if it is from the right document and on the right
page **or** contains the answer text:

| | R@1 | R@3 | R@5 | MRR |
|---|---|---|---|---|
| meaning only | 28/49 | 38/49 | 42/49 | 0.677 |
| hybrid (default) | 34/49 | 42/49 | 46/49 | 0.773 |

The gain is not one lucky setting: any keyword weight from 0.05 to 1.0 scores
34–35/49 at Recall@1, and dropping stopwords is worth about two more right-first
answers. The committed English Gecko benchmark remains 22/23 at Recall@1 and
23/23 at Recall@3/5 (MRR 0.978). On the fictional Hindi/Hinglish fixture,
normalisation raises Recall@1/3/5 from 3/12 to 12/12 and MRR from 0.250 to
1.000.

Run the committed regression set with
`flutter test test/features/shiv/rag/retrieval/hybrid_ranking_quality_test.dart`.
The device run also dumps every chunk and question vector; use
`flutter pub run tool/eval_retrieval.dart` to try ranking settings offline in
seconds without re-indexing.

**The notes' vector search had the same limit on 3.1.x, and 3.5.1 fixes it.** Querying each stored vector with itself, it was its own top hit for 25 % of 80 vectors, 7 % of 300 and 2 % of 1,000 on 3.1.2, against 99-100 % at every size on 3.5.1 (synthetic vectors, laptop; the device figures are in `docs/AUDIT.md`). Notes therefore still use ToStore's index; documents keep the exact scan.

**The note store runs in its own isolate** (`NoteVectorStore`, `lib/data/datasources/note_vector_store.dart`). On the main isolate 600 saves and 600 searches stalled the UI for up to 522 ms (12 stalls over 16 ms); in its own isolate the worst was 13 ms. Exactly one isolate may open the store — ToStore keeps per-isolate state, so a second opener does not see the first one's writes — which is why `TostoreVectorRepositoryImpl` talks to it by message and nothing else opens it. Inside, a delete is flushed (or search keeps returning the id) and saving an id again deletes the old entry first (or the old vector stays in the index).

### Testing

| Tier | Where | Real | Faked |
|---|---|---|---|
| Unit | `test/features/shiv/rag/extraction/`, `test/domain/entities/shiv/`, `test/core/enum/` | chunker, gate, extraction dispatch, per-page OCR plans, chunk ids, `DocumentKind` | PDF/DOCX/OCR sources |
| Component | `test/features/shiv/rag/indexing/`, `test/data/...` | real PDFium + the committed PDFs (page signals and OCR renders too), the real DOCX reader + committed Word/LibreOffice files, real Isar (vectors on the chunk rows) | embedder |
| Pipeline | `test/integration/document_rag_flow_test.dart` | everything above, assembled, PDF, DOCX and images | embedder, OCR |
| Device | `integration_test/document_rag_e2e_test.dart` | **everything, incl. the real Gecko embedder and real ML Kit OCR** | nothing |

The device tier exists because the embedder loads a 145 MB Git-LFS asset that
CI does not check out, and `EmbeddingService.embed` returns `[]` instead of
throwing when the model is missing — so a CI run would go green while embedding
nothing. Run it by hand:

```
flutter test integration_test/document_rag_e2e_test.dart -d <device-id>
```

`flutter test` does not run native-asset build hooks, so PDFium is absent under
a plain `flutter test`. `test/_helpers/pdfium_test_lib.dart` downloads it once
and points pdfrx at it, mirroring what `ensureIsarCore()` already does for
Isar's native binary.

**Not built:** documents in Manas-scoped chat
(#236), a `notSearchable` badge, OCR of pictures inside DOCX text boxes, headers or tables' VML, `.doc`/`.odt`, DOCX headers,
footers and footnotes.
