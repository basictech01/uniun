// Device-bound end-to-end test for document RAG with the REAL Gecko embedder.
//
// Why this cannot live under `test/`: the embedder loads through flutter_gemma
// from `assets/models/embedding/gecko_1024_quant.tflite`, a 145 MB Git-LFS
// asset. Headless `flutter test` has no such asset, and CI checks out without
// LFS, so the file there is a ~130-byte pointer. Worse, `EmbeddingService.embed`
// returns `[]` rather than throwing when the model is missing — a CI run would
// go green while embedding nothing. Hence: device only, and each test first
// checks that the model really loaded.
//
// Everything else about the pipeline (real PDFium, the real DOCX reader, real
// chunking, real Isar, real ToStore, purge, idempotency) is proven in CI by
// `test/integration/document_rag_flow_test.dart`. What ONLY this test can
// prove is that genuine Gecko vectors retrieve the *semantically right* chunk
// — and, for a DOCX, that the chunk carries the right heading — and that real
// ML Kit OCR reads text (English and Hindi) out of an image, which never runs
// under `flutter test`.
//
// Run:
//   flutter test integration_test/document_rag_e2e_test.dart -d <device-id>
//
// The image-labeling group needs real photographs (a drawing proves nothing
// about what ML Kit recognises). Copy them into the app's private cache, then
// pass the directory:
//   for f in labrador_dog_photo.jpg food_plate_photo.jpg \
//            snowy_street_car_photo.jpg computer_desk_photo.jpg; do
//     adb push $f /data/local/tmp/$f
//     adb shell run-as in.uniun.app sh -c \
//       "mkdir -p cache/label_photos && cp /data/local/tmp/$f cache/label_photos/"
//   done
//   flutter test integration_test/document_rag_e2e_test.dart -d <device-id> \
//     --dart-define=LABEL_PHOTOS_DIR=/data/user/0/in.uniun.app/cache/label_photos
//
// By default the PDF test indexes a generated two-page PDF whose pages are
// about clearly different subjects. To run it against a real document instead:
//   adb push test/_helpers/fixtures/pdf/nist_sp800-145.pdf /sdcard/Download/
//   flutter test integration_test/document_rag_e2e_test.dart -d <device-id> \
//     --dart-define=PDF_FIXTURE_PATH=/sdcard/Download/nist_sp800-145.pdf
//
// Selective OCR (#242) runs on PDFs built on the device, so it needs nothing
// pushed. To time it on a real circular, page by page — the measurement to
// take before trusting the thresholds in `page_ocr_plan.dart`:
//   adb push circular.pdf /sdcard/Download/
//   flutter test integration_test/document_rag_e2e_test.dart -d <device-id> \
//     --plain-name 'selective OCR' \
//     --dart-define=OCR_TIMING_PDF=/sdcard/Download/circular.pdf

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/image_labels/image_label_source.dart';
import 'package:uniun/data/datasources/ocr/ocr_text_source.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/extraction/page_ocr_plan.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/notes/media_attachment.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/core/text/hybrid_ranker.dart';
import 'package:uniun/data/repositories/isar_document_vector_repository_impl.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';

/// Two pages (or sections) on plainly different subjects, so a semantic query
/// can only reach the right one by meaning rather than by luck.
const _cloudPage =
    'Cloud computing is a model for enabling ubiquitous, convenient, on-demand '
    'network access to a shared pool of configurable computing resources such '
    'as networks, servers, storage, applications and services, which can be '
    'rapidly provisioned and released with minimal management effort. The '
    'service models include software as a service, platform as a service and '
    'infrastructure as a service, and the deployment models include private, '
    'community, public and hybrid clouds.';

const _gardeningPage =
    'Tomato plants grow best in well drained soil with full sunlight for at '
    'least six hours each day. Water them deeply at the base rather than over '
    'the leaves, mulch to retain moisture, and stake or cage the plants early '
    'so the stems are supported before the fruit becomes heavy. Prune the side '
    'shoots to concentrate growth in the main stem and harvest when the fruit '
    'is firm and fully coloured.';

/// A notice as it would be photographed or scanned: short lines, distinctive
/// words the OCR assertions look for.
const _notice =
    'RECORD ROOM NOTICE\nThe record room stays closed\nfrom 3 to 7 November '
    'for the\ndigitisation of old files.\nUrgent certified copies\nmay be '
    'requested at the\nTehsil office.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late EmbeddingService embedding;
  late DocumentVectorRepository vectors;
  late DocumentIndexer indexer;

  setUpAll(() async {
    await configureDependencies();
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    await pdfrxFlutterInitialize();
    isar = getIt<Isar>();
    embedding = getIt<EmbeddingService>();
    vectors = getIt<DocumentVectorRepository>();
    indexer = getIt<DocumentIndexer>();
  });

  /// The gate: the real model must actually be loaded. Deliberately NOT a
  /// skip — Gecko ships as a bundled asset, so its absence on a correctly
  /// built app is a bug, not a missing precondition like a chat model the user
  /// has to download. Checks non-empty rather than a length: the model emits
  /// 768 where the app declares 1024 (#234), which ToStore tolerates.
  Future<void> expectModelLoaded() async {
    expect(
      await embedding.embed('a probe sentence'),
      isNotEmpty,
      reason: '[] means the bundled embedding model did not load at all',
    );
  }

  /// Registers [path] in the media cache as a downloaded blob would be,
  /// indexes it, and returns its sha.
  Future<String> index(
    String path,
    DocumentKind kind, {
    DocumentIndexStatus expected = DocumentIndexStatus.indexed,
  }) async {
    final sha = 'e2e${kind.name}${DateTime.now().microsecondsSinceEpoch}';
    final size = await File(path).length();
    await isar.writeTxn(
      () => isar.mediaCacheModels.put(
        MediaCacheModel()
          ..sha256 = sha
          ..localPath = path
          ..mime = kind.mime
          ..sizeBytes = size
          ..downloadedAt = DateTime.now(),
      ),
    );
    // Shiv only cites documents on the user's own or saved notes.
    await isar.writeTxn(
      () => isar.savedNoteModels.put(
        SavedNoteModel()
          ..eventId = 'e2e-saved-$sha'
          ..authorPubkey = 'e2e'
          ..sig = ''
          ..content = 'e2e document note'
          ..type = NoteType.text
          ..eTagRefs = const []
          ..pTagRefs = const []
          ..tTags = const []
          ..created = DateTime.now()
          ..savedAt = DateTime.now()
          ..attachments = [
            MediaAttachment()
              ..sha256 = sha
              ..mime = kind.mime,
          ],
      ),
    );
    await indexer.reconcile();
    final row = await isar.documentIndexModels
        .filter()
        .sha256EqualTo(sha)
        .findFirst();
    expect(
      row?.status,
      expected,
      reason: 'the document should have been extracted and embedded',
    );
    return sha;
  }

  Future<List<DocumentChunkModel>> chunksOf(String sha) =>
      isar.documentChunkModels.where().sha256EqualToAnyOrdinal(sha).findAll();

  Future<void> purge(String sha) async {
    await isar.writeTxn(() async {
      await isar.mediaCacheModels.deleteBySha256(sha);
      await isar.savedNoteModels.deleteByEventId('e2e-saved-$sha');
    });
    await indexer.reconcile();
    expect(await chunksOf(sha), isEmpty);
  }

  Future<File> tempFile(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('document_rag_e2e');
    return File('${dir.path}/$name')..writeAsBytesSync(bytes);
  }

  test('a PDF is indexed with the real Gecko embedder and the right page is '
      'retrieved semantically', () async {
    await expectModelLoaded();

    const override = String.fromEnvironment('PDF_FIXTURE_PATH');
    final String path;
    if (override.isNotEmpty) {
      expect(
        File(override).existsSync(),
        isTrue,
        reason:
            'PDF_FIXTURE_PATH was set but no file is there — did the '
            'adb push run?',
      );
      path = override;
    } else {
      path = (await tempFile('two_subjects.pdf', _twoPagePdf())).path;
    }
    final sha = await index(path, DocumentKind.pdf);
    final chunks = await chunksOf(sha);
    expect(chunks, isNotEmpty);

    final query = override.isNotEmpty
        ? 'what is the definition of cloud computing?'
        : 'how should I water and support tomato plants?';
    final expectContains = override.isNotEmpty ? 'cloud computing' : 'tomato';

    final hits = await vectors.search(
      await embedding.embed(query),
      topK: 3,
      minScore: 0.0,
    );

    expect(hits, isNotEmpty, reason: 'the query retrieved no chunk at all');
    expect(
      hits.first.content.toLowerCase(),
      contains(expectContains),
      reason:
          'the closest chunk for "$query" should be the one about '
          '"$expectContains", not ${hits.first.content}',
    );
    expect(hits.first.kind, DocumentKind.pdf);
    expect(
      hits.first.label,
      isNotEmpty,
      reason: 'a citation needs the page it came from',
    );

    // ignore: avoid_print
    print(
      'E2E PDF OK — ${chunks.length} chunk(s), top hit '
      'p.${hits.first.label} score ${hits.first.score.toStringAsFixed(3)}',
    );
    await purge(sha);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a DOCX is indexed with the real Gecko embedder and the right section '
      'is retrieved semantically', () async {
    await expectModelLoaded();

    final file = await tempFile('two_subjects.docx', _twoSectionDocx());
    final sha = await index(file.path, DocumentKind.docx);
    final chunks = await chunksOf(sha);
    expect(chunks.map((c) => c.label).toSet(), {
      'Cloud Computing',
      'Growing Tomatoes',
    });

    final hits = await vectors.search(
      await embedding.embed('how should I water and support tomato plants?'),
      topK: 3,
      minScore: 0.0,
    );

    expect(hits, isNotEmpty, reason: 'the query retrieved no chunk at all');
    expect(hits.first.kind, DocumentKind.docx);
    expect(
      hits.first.label,
      'Growing Tomatoes',
      reason:
          'the citation must name the section the answer came from, '
          'not ${hits.first.label}: ${hits.first.content}',
    );

    // ignore: avoid_print
    print(
      'E2E DOCX OK — ${chunks.length} chunk(s), top hit '
      '"${hits.first.label}" score ${hits.first.score.toStringAsFixed(3)}',
    );
    await purge(sha);
  }, timeout: const Timeout(Duration(minutes: 5)));

  group('images (real ML Kit OCR)', () {
    test('OCR reads the words of an English notice', () async {
      final png = await _renderText(
        'OFFICE ORDER\nEarned leave may be carried forward\nup to 15 days.',
      );
      final file = await tempFile('en_notice.png', png);

      final text = (await getIt<OcrTextSource>().imageText(file.path))!;

      // ignore: avoid_print
      print('OCR EN → ${text.replaceAll('\n', ' ⏎ ')}');
      expect(
        text.toLowerCase(),
        allOf(contains('office order'), contains('15 days')),
      );
    });

    test(
      'OCR keeps both languages of a mixed Hindi and English notice',
      () async {
        final png = await _renderText(
          'कार्यालय आदेश\nसभी कर्मचारियों के लिए\nOFFICE ORDER\nLeave rules 2026',
        );
        final file = await tempFile('mixed_notice.png', png);

        final text = (await getIt<OcrTextSource>().imageText(file.path))!;

        // ignore: avoid_print
        print('OCR MIXED → ${text.replaceAll('\n', ' ⏎ ')}');
        expect(text, contains('आदेश'), reason: 'the Hindi line');
        expect(
          text.toUpperCase(),
          contains('OFFICE ORDER'),
          reason:
              'the English line — if this fails, the Devanagari '
              'recogniser drops Latin text and the two passes must be merged',
        );
      },
    );

    test(
      'an image of text is retrieved semantically with real Gecko',
      () async {
        await expectModelLoaded();
        final cloud = await tempFile(
          'cloud.png',
          await _renderText(_wrap(_cloudPage)),
        );
        final garden = await tempFile(
          'garden.png',
          await _renderText(_wrap(_gardeningPage)),
        );
        final cloudSha = await index(cloud.path, DocumentKind.image);
        final gardenSha = await index(garden.path, DocumentKind.image);

        final hits = await vectors.search(
          await embedding.embed(
            'how should I water and support tomato plants?',
          ),
          topK: 3,
          minScore: 0.0,
        );

        expect(hits, isNotEmpty);
        expect(hits.first.kind, DocumentKind.image);
        expect(
          hits.first.sha256,
          gardenSha,
          reason:
              'the tomato question should reach the tomato image, not '
              '${hits.first.content}',
        );
        // ignore: avoid_print
        print(
          'E2E IMAGE OK — top hit score ${hits.first.score.toStringAsFixed(3)}',
        );
        await purge(cloudSha);
        await purge(gardenSha);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test('a picture with no text is kept but not searchable', () async {
      final blank = await tempFile('sky.png', await _renderBlank());

      final sha = await index(
        blank.path,
        DocumentKind.image,
        expected: DocumentIndexStatus.notSearchable,
      );

      expect(await chunksOf(sha), isEmpty);
      await purge(sha);
    });
  });

  group('selective OCR (real PDFium + ML Kit)', () {
    // A4 at 150 dpi, and a photo of about the page's proportions to paste.
    late _GrayImage scan;
    late _GrayImage photo;
    setUpAll(() async {
      scan = _GrayImage.fromPng(
        await _renderText(_notice, width: 1240, height: 1754, fontSize: 44),
      );
      photo = _GrayImage.fromPng(
        await _renderText(_notice, width: 1240, height: 1000, fontSize: 44),
      );
    });

    String allText(List<DocumentChunkModel> chunks) =>
        chunks.map((c) => c.text).join('\n').toLowerCase();

    Future<String> timed(String name, Future<String> Function() body) async {
      final watch = Stopwatch()..start();
      final sha = await body();
      // ignore: avoid_print
      print('SELECTIVE OCR $name — indexed in ${watch.elapsedMilliseconds} ms');
      return sha;
    }

    test(
      'a scanned page is read by OCR and cited by its page',
      () async {
        await expectModelLoaded();
        final file = await tempFile(
          'scan.pdf',
          _pdf([(text: '', image: (pixels: scan, box: _a4Page))]),
        );

        final sha = await timed(
          'scanned page',
          () => index(file.path, DocumentKind.pdf),
        );

        final chunks = await chunksOf(sha);
        expect(chunks.map((c) => c.label).toSet(), {'1'});
        expect(
          allText(chunks),
          allOf(contains('record room'), contains('november')),
        );
        await purge(sha);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'only the scanned page of a mixed PDF is read by OCR',
      () async {
        await expectModelLoaded();
        final file = await tempFile(
          'mixed.pdf',
          _pdf([
            (text: _cloudPage, image: null),
            (text: '', image: (pixels: scan, box: _a4Page)),
          ]),
        );

        final sha = await timed(
          'mixed typed + scanned',
          () => index(file.path, DocumentKind.pdf),
        );

        final chunks = await chunksOf(sha);
        expect(
          allText(chunks.where((c) => c.label == '1').toList()),
          contains('cloud computing'),
        );
        expect(
          allText(chunks.where((c) => c.label == '2').toList()),
          contains('record room'),
        );
        await purge(sha);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'a photo pasted into a typed page is read beside the text',
      () async {
        await expectModelLoaded();
        final file = await tempFile(
          'pasted.pdf',
          _pdf([
            (
              text: _gardeningPage,
              // About a third of the page, below the typed paragraph.
              image: (
                pixels: photo,
                box: (left: 60, bottom: 60, right: 535, top: 443),
              ),
            ),
          ]),
        );

        final sha = await timed(
          'typed page + pasted photo',
          () => index(file.path, DocumentKind.pdf),
        );

        expect(
          allText(await chunksOf(sha)),
          allOf(contains('tomato'), contains('record room')),
        );
        await purge(sha);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'a large picture in a DOCX is read where it sits',
      () async {
        await expectModelLoaded();
        final file = await tempFile(
          'memo.docx',
          _docxWithPicture(
            before: 'Memo on the closure of the record room.',
            png: await _renderText(_notice),
            after: 'Please plan certified-copy work accordingly.',
          ),
        );

        final sha = await timed(
          'DOCX with a pasted notice',
          () => index(file.path, DocumentKind.docx),
        );

        final text = allText(await chunksOf(sha));
        expect(
          text.indexOf('record room notice'),
          allOf(
            greaterThan(text.indexOf('memo on')),
            lessThan(text.indexOf('please plan')),
          ),
        );
        await purge(sha);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    // PDFs plus their questions: the committed fixture and, optionally, the
    // caller's own private documents. A folder on the phone holds the .pdf
    // files and queries.json (see tool/rag_docs_e2e.sh).
    const realDir = String.fromEnvironment('RAG_DOCS_DIR');
    test(
      'documents answer messy user questions',
      () async {
        await expectModelLoaded();
        {
          // An interrupted run leaves its documents behind; a stale copy would
          // answer every question alongside the fresh one.
          await isar.writeTxn(() async {
            await isar.documentChunkModels
                .filter()
                .sha256StartsWith('e2e')
                .deleteAll();
            await isar.documentIndexModels
                .filter()
                .sha256StartsWith('e2e')
                .deleteAll();
            await isar.mediaCacheModels
                .filter()
                .sha256StartsWith('e2e')
                .deleteAll();
            await isar.savedNoteModels
                .filter()
                .eventIdStartsWith('e2e-saved-')
                .deleteAll();
          });
        }
        final dir = Directory(realDir);
        final shaByDoc = <String, String>{};
        final pdfs =
            dir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.pdf'))
                .toList()
              ..sort((x, y) => x.path.compareTo(y.path));
        expect(pdfs, isNotEmpty, reason: 'no .pdf in RAG_DOCS_DIR');
        for (final f in pdfs) {
          final name = f.uri.pathSegments.last.replaceAll(
            RegExp(r'\.pdf$'),
            '',
          );
          final watch = Stopwatch()..start();
          shaByDoc[name] = await index(f.path, DocumentKind.pdf);
          final n = (await chunksOf(shaByDoc[name]!)).length;
          // ignore: avoid_print
          print(
            'REAL indexed $name: $n chunks in ${watch.elapsed.inSeconds} s',
          );
        }
        if (!const bool.fromEnvironment('SKIP_SELF_CHECK')) {
          // Can the search reach each stored chunk at all? A chunk that does
          // not find itself cannot be found by any question.
          var stored = 0;
          var selfFound = 0;
          for (final sha in shaByDoc.values) {
            for (final c in await chunksOf(sha)) {
              stored++;
              final self = await vectors.search(
                await embedding.embed(c.text),
                topK: 1,
                minScore: 0.0,
              );
              if (self.isNotEmpty &&
                  self.first.chunkId == chunkIdOf(sha, c.ordinal)) {
                selfFound++;
              }
            }
          }
          // ignore: avoid_print
          print(
            'REAL self-retrieval: $selfFound/$stored chunks find themselves',
          );
        }
        final queries =
            (jsonDecode(File('$realDir/queries.json').readAsStringSync())
                    as List)
                .cast<Map<String, dynamic>>();

        // Each question is embedded once; the same vectors are ranked by
        // meaning alone and with keyword evidence, so the two are compared on
        // identical inputs.
        final vectors_ = <String, List<double>>{};
        for (final c in queries) {
          vectors_[c['q'] as String] = await embedding.embed(c['q'] as String);
        }

        // Everything a ranking experiment needs, so variants can be tried
        // offline in seconds instead of re-indexing on the phone.
        final dump = {
          'chunks': [
            for (final e in shaByDoc.entries)
              for (final c in await chunksOf(e.value))
                {
                  'doc': e.key,
                  'sha': e.value,
                  'ordinal': c.ordinal,
                  'label': c.label,
                  'text': c.text,
                  'vector': [
                    for (final v in c.vector ?? const <double>[])
                      double.parse(v.toStringAsFixed(5)),
                  ],
                },
          ],
          'queries': [
            for (final c in queries)
              {
                ...c,
                'vector': [
                  for (final v in vectors_[c['q']]!)
                    double.parse(v.toStringAsFixed(5)),
                ],
              },
          ],
        };
        File('$realDir/dump.json').writeAsStringSync(jsonEncode(dump));
        // ignore: avoid_print
        print('REAL dump written: $realDir/dump.json');

        final modes = {
          'meaning': IsarDocumentVectorRepositoryImpl.tuned(
            isar,
            HybridConfig.off,
          ),
          'hybrid': IsarDocumentVectorRepositoryImpl.tuned(
            isar,
            const HybridConfig(),
          ),
        };
        final recall = {
          for (final m in modes.keys) m: {1: 0, 3: 0, 5: 0},
        };
        final reciprocal = {for (final m in modes.keys) m: 0.0};
        String docName(String sha) =>
            shaByDoc.entries
                .where((e) => e.value == sha)
                .map((e) => e.key.length > 3 ? e.key.substring(0, 3) : e.key)
                .firstOrNull ??
            '?';
        var answerable = 0;
        for (final c in queries) {
          final q = c['q'] as String;
          final want = c['doc'] as String;
          if (want == 'none') continue;
          answerable++;
          final pages = (c['pages'] as List).cast<String>();
          final phrases = (c['phrases'] as List).cast<String>();
          // Relevant: right document, and either the right page or the answer
          // text itself (OCR can move a fact to a neighbouring page).
          bool relevant(ScoredChunk h) =>
              (want == 'any' || h.sha256 == shaByDoc[want]) &&
              (pages.contains(h.label) ||
                  phrases.any(
                    (p) => h.content.toLowerCase().contains(p.toLowerCase()),
                  ));
          final row = StringBuffer();
          for (final m in modes.entries) {
            final hits = await m.value.search(
              vectors_[q]!,
              queryText: q,
              topK: 5,
              minScore: 0.0,
            );
            final rank = hits.indexWhere(relevant) + 1; // 0 = not in top 5
            for (final k in [1, 3, 5]) {
              if (rank > 0 && rank <= k) {
                recall[m.key]![k] = recall[m.key]![k]! + 1;
              }
            }
            if (rank > 0) {
              reciprocal[m.key] = reciprocal[m.key]! + 1 / rank;
            }
            row.write(
              ' ${m.key}:${rank == 0 ? 'miss' : '#$rank'}'
              '(${hits.take(3).map((h) => '${docName(h.sha256)}p${h.label}').join(',')})',
            );
          }
          // ignore: avoid_print
          print('REAL "$q" →$row');
        }
        for (final m in modes.keys) {
          // ignore: avoid_print
          print(
            'REAL $m: Recall@1 ${recall[m]![1]}/$answerable '
            'Recall@3 ${recall[m]![3]}/$answerable '
            'Recall@5 ${recall[m]![5]}/$answerable '
            'MRR ${(reciprocal[m]! / answerable).toStringAsFixed(3)}',
          );
        }
        for (final sha in shaByDoc.values) {
          await purge(sha);
        }
        expect(dir.existsSync(), isTrue);
      },
      skip: realDir.isEmpty ? 'pass --dart-define=RAG_DOCS_DIR' : false,
      timeout: const Timeout(Duration(hours: 4)),
    );

    const timingPdf = String.fromEnvironment('OCR_TIMING_PDF');
    test(
      'timings on a real PDF, page by page',
      () async {
        expect(
          File(timingPdf).existsSync(),
          isTrue,
          reason: 'OCR_TIMING_PDF was set but no file is there',
        );
        final pdf = getIt<PdfTextSource>();
        final ocr = getIt<OcrTextSource>();

        final watch = Stopwatch()..start();
        final signals = (await pdf.pageSignals(timingPdf))!;
        // ignore: avoid_print
        print(
          'TIMING signals for ${signals.length} page(s): '
          '${watch.elapsedMilliseconds} ms',
        );

        for (var i = 0; i < signals.length; i++) {
          final s = signals[i];
          final plan = planPage(s);
          final region = plan is OcrRegion ? plan.region : null;
          var line =
              'TIMING p.${i + 1} ${plan.runtimeType} '
              'chars=${s.chars} images=${(s.imageCoverage * 100).round()}% '
              'largest=${(s.largestImageCoverage * 100).round()}%';
          if (plan is OcrWholePage || plan is OcrRegion) {
            watch.reset();
            final png = (await pdf.renderForOcr(timingPdf, i, region: region))!;
            final renderMs = watch.elapsedMilliseconds;
            watch.reset();
            final text = await ocr.imageText(png) ?? '';
            line +=
                ' render=${renderMs}ms ocr=${watch.elapsedMilliseconds}ms '
                'read=${text.length} chars '
                'letters=${RegExp(r'\p{L}', unicode: true).allMatches(text).length} '
                'devanagari=${RegExp(r'[ऀ-ॿ]').allMatches(text).length}';
            if (const bool.fromEnvironment('DUMP_OCR')) {
              // ignore: avoid_print
              print('OCRTEXT p.${i + 1}: ${text.replaceAll('\n', ' ⏎ ')}');
            }
            await File(png).delete();
          }
          // ignore: avoid_print
          print(line);
        }
      },
      skip: timingPdf.isEmpty
          ? 'pass --dart-define=OCR_TIMING_PDF (see the header comment)'
          : false,
      timeout: const Timeout(Duration(minutes: 10)),
    );
  });

  group('image labels (real ML Kit, real photographs)', () {
    const dir = String.fromEnvironment('LABEL_PHOTOS_DIR');
    const skip = dir == ''
        ? 'pass --dart-define=LABEL_PHOTOS_DIR (see the header comment)'
        : false;
    String photo(String name) => '$dir/$name';

    test('ML Kit names what is in each photo', () async {
      final labeler = getIt<ImageLabelSource>();
      final seen = {
        for (final f in [
          'labrador_dog_photo.jpg',
          'food_plate_photo.jpg',
          'snowy_street_car_photo.jpg',
          'computer_desk_photo.jpg',
        ])
          f: (await labeler.imageLabels(photo(f)))!,
      };
      // ignore: avoid_print
      seen.forEach((f, l) => print('LABELS $f → $l'));

      bool has(String f, List<String> any) =>
          seen[f]!.any((l) => any.contains(l.toLowerCase()));
      expect(has('labrador_dog_photo.jpg', ['dog']), isTrue);
      expect(
        has('food_plate_photo.jpg', ['food', 'cuisine', 'dish', 'meal']),
        isTrue,
      );
      expect(
        has('snowy_street_car_photo.jpg', ['car', 'vehicle', 'snow', 'winter']),
        isTrue,
      );
    }, skip: skip);

    test(
      '"the picture of my dog" finds the dog photo, not the meal',
      () async {
        await expectModelLoaded();
        final dogSha = await index(
          photo('labrador_dog_photo.jpg'),
          DocumentKind.image,
        );
        final foodSha = await index(
          photo('food_plate_photo.jpg'),
          DocumentKind.image,
        );

        final hits = await vectors.search(
          await embedding.embed('show me the picture of my dog'),
          topK: 3,
          minScore: 0.0,
        );

        // ignore: avoid_print
        print(
          'E2E LABELS top hit: ${hits.first.content} '
          '(${hits.first.score.toStringAsFixed(3)})',
        );
        expect(hits.first.kind, DocumentKind.image);
        expect(hits.first.sha256, dogSha);
        await purge(dogSha);
        await purge(foodSha);
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

/// Minimal Word package: one Heading 1 per subject, each followed by its
/// paragraph. Built here rather than committed so the test needs no push step.
List<int> _twoSectionDocx() {
  const w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
  String esc(String s) => const HtmlEscape(HtmlEscapeMode.element).convert(s);
  String p(String text, {String? style}) =>
      '<w:p>'
      '${style == null ? '' : '<w:pPr><w:pStyle w:val="$style"/></w:pPr>'}'
      '<w:r><w:t xml:space="preserve">${esc(text)}</w:t></w:r></w:p>';

  final parts = {
    '[Content_Types].xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>',
    '_rels/.rels':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>',
    'word/styles.xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<w:styles xmlns:w="$w"><w:style w:type="paragraph" w:styleId="Heading1">'
        '<w:name w:val="heading 1"/></w:style></w:styles>',
    'word/document.xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<w:document xmlns:w="$w"><w:body>'
        '${p('Cloud Computing', style: 'Heading1')}${p(_cloudPage)}'
        '${p('Growing Tomatoes', style: 'Heading1')}${p(_gardeningPage)}'
        '</w:body></w:document>',
  };
  final archive = Archive();
  parts.forEach(
    (name, xml) => archive.addFile(ArchiveFile.bytes(name, utf8.encode(xml))),
  );
  return ZipEncoder().encodeBytes(archive);
}

/// Minimal two-page PDF, one paragraph per page, wrapped so each line fits.
List<int> _twoPagePdf() {
  String esc(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  /// One `Tj` per ~90 characters, moved down the page, so PDFium sees real
  /// lines rather than one run off the edge.
  String contentFor(String text) {
    final words = text.split(' ');
    final lines = <String>[];
    var line = '';
    for (final w in words) {
      if ((line + w).length > 90) {
        lines.add(line.trim());
        line = '';
      }
      line = '$line$w ';
    }
    if (line.trim().isNotEmpty) lines.add(line.trim());
    final buf = StringBuffer('BT /F1 11 Tf 54 720 Td 14 TL\n');
    for (final l in lines) {
      buf.write('(${esc(l)}) Tj T*\n');
    }
    buf.write('ET');
    return buf.toString();
  }

  final pages = [contentFor(_cloudPage), contentFor(_gardeningPage)];
  final objs = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [4 0 R 6 0 R] /Count 2 >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  for (var i = 0; i < pages.length; i++) {
    objs.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents ${5 + i * 2} 0 R /Resources << /Font << /F1 3 0 R >> >> >>',
    );
    objs.add(
      '<< /Length ${pages[i].length} >>\nstream\n${pages[i]}\nendstream',
    );
  }

  final sb = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objs.length; i++) {
    offsets.add(sb.length);
    sb.write('${i + 1} 0 obj\n${objs[i]}\nendobj\n');
  }
  final xrefAt = sb.length;
  sb.write('xref\n0 ${objs.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    sb.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  sb.write(
    'trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xrefAt\n%%EOF\n',
  );
  return sb.toString().codeUnits;
}

/// Breaks [text] into short lines so a rendered notice stays readable.
String _wrap(String text, {int width = 42}) {
  final lines = <String>[];
  var line = '';
  for (final w in text.split(' ')) {
    if (line.isNotEmpty && line.length + 1 + w.length > width) {
      lines.add(line);
      line = '';
    }
    line = line.isEmpty ? w : '$line $w';
  }
  if (line.isNotEmpty) lines.add(line);
  return lines.join('\n');
}

/// [text] drawn black on white, large enough for OCR, as a PNG — rendered on
/// the device with its own fonts, so Devanagari needs no bundled font. A
/// [height] gives a fixed page-shaped canvas, so a scan is not stretched.
Future<List<int>> _renderText(
  String text, {
  int width = 1080,
  int? height,
  double fontSize = 36,
}) async {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: fontSize))
    ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)))
    ..addText(text);
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: width - 80.0));
  final h = height ?? paragraph.height.ceil() + 80;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    )
    ..drawParagraph(paragraph, const ui.Offset(40, 40));
  final image = await recorder.endRecording().toImage(width, h);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

/// A plain sky-blue square: a photo with nothing to read.
Future<List<int>> _renderBlank() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 800, 600),
    ui.Paint()..color = const ui.Color(0xFF87CEEB),
  );
  final image = await recorder.endRecording().toImage(800, 600);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

/// An A4 page, in points.
const _a4Page = (left: 0.0, bottom: 0.0, right: 595.0, top: 842.0);

/// 8-bit grayscale pixels, as a PDF image XObject takes them.
class _GrayImage {
  _GrayImage(this.width, this.height, this.bytes);

  factory _GrayImage.fromPng(List<int> png) {
    final gray = img
        .decodePng(Uint8List.fromList(png))!
        .convert(numChannels: 1);
    return _GrayImage(gray.width, gray.height, gray.getBytes());
  }

  final int width;
  final int height;
  final Uint8List bytes;
}

typedef _PdfBox = ({double left, double bottom, double right, double top});

/// An A4 PDF, one entry per page: typed [text] (a real text layer) and/or an
/// image drawn at a box — a scan when it fills the page with no text, a
/// pasted photo when it sits beside text.
List<int> _pdf(
  List<({String text, ({_GrayImage pixels, _PdfBox box})? image})> pages,
) {
  String esc(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
  String textOps(String text) {
    if (text.isEmpty) return '';
    final lines = _wrap(text, width: 90).split('\n');
    return 'BT /F1 11 Tf 54 790 Td 14 TL\n'
        '${lines.map((l) => '(${esc(l)}) Tj T*').join('\n')}\nET\n';
  }

  final objs = <List<int>>[];
  int add(List<int> body) {
    objs.add(body);
    return objs.length;
  }

  List<int> ascii(String s) => latin1.encode(s);
  List<int> stream(String dict, List<int> data) => [
    ...ascii('<< $dict /Length ${data.length} >>\nstream\n'),
    ...data,
    ...ascii('\nendstream'),
  ];

  add(ascii('<< /Type /Catalog /Pages 2 0 R >>'));
  add(const []); // pages tree, filled in once the page ids are known
  add(ascii('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'));
  final pageIds = <int>[];
  for (final page in pages) {
    final image = page.image;
    var ops = textOps(page.text);
    var xobject = '';
    if (image != null) {
      final b = image.box;
      final id = add(
        stream(
          '/Type /XObject /Subtype /Image /Width ${image.pixels.width} '
          '/Height ${image.pixels.height} /ColorSpace /DeviceGray '
          '/BitsPerComponent 8 /Filter /FlateDecode',
          zlib.encode(image.pixels.bytes),
        ),
      );
      ops +=
          'q ${b.right - b.left} 0 0 ${b.top - b.bottom} ${b.left} '
          '${b.bottom} cm /Im1 Do Q\n';
      xobject = '/XObject << /Im1 $id 0 R >>';
    }
    final content = add(stream('', ascii(ops)));
    pageIds.add(
      add(
        ascii(
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
          '/Contents $content 0 R /Resources << /Font << /F1 3 0 R >> $xobject >> >>',
        ),
      ),
    );
  }
  objs[1] = ascii(
    '<< /Type /Pages /Kids [${pageIds.map((i) => '$i 0 R').join(' ')}] '
    '/Count ${pageIds.length} >>',
  );

  final out = BytesBuilder()..add(ascii('%PDF-1.4\n'));
  final offsets = <int>[];
  for (var i = 0; i < objs.length; i++) {
    offsets.add(out.length);
    out
      ..add(ascii('${i + 1} 0 obj\n'))
      ..add(objs[i])
      ..add(ascii('\nendobj\n'));
  }
  final xrefAt = out.length;
  out.add(
    ascii(
      'xref\n0 ${objs.length + 1}\n0000000000 65535 f \n'
      '${offsets.map((o) => '${o.toString().padLeft(10, '0')} 00000 n \n').join()}'
      'trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefAt\n%%EOF\n',
    ),
  );
  return out.toBytes();
}

/// A Word package with [png] pasted at 6 × 4 in between two paragraphs.
List<int> _docxWithPicture({
  required String before,
  required List<int> png,
  required String after,
}) {
  const w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
  String p(String text) =>
      '<w:p><w:r><w:t xml:space="preserve">${const HtmlEscape(HtmlEscapeMode.element).convert(text)}</w:t></w:r></w:p>';
  const picture =
      '<w:p><w:r><w:drawing '
      'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
      'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<wp:inline><wp:extent cx="5486400" cy="3657600"/><a:graphic><a:graphicData>'
      '<pic:pic><pic:blipFill><a:blip r:embed="rId1"/></pic:blipFill></pic:pic>'
      '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>';
  final parts = <String, List<int>>{
    '[Content_Types].xml': utf8.encode(
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Default Extension="png" ContentType="image/png"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>',
    ),
    '_rels/.rels': utf8.encode(
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>',
    ),
    'word/_rels/document.xml.rels': utf8.encode(
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>'
      '</Relationships>',
    ),
    'word/document.xml': utf8.encode(
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<w:document xmlns:w="$w"><w:body>${p(before)}$picture${p(after)}'
      '</w:body></w:document>',
    ),
    'word/media/image1.png': png,
  };
  final archive = Archive();
  parts.forEach(
    (name, bytes) => archive.addFile(ArchiveFile.bytes(name, bytes)),
  );
  return ZipEncoder().encodeBytes(archive);
}
