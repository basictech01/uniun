// Every test indexes real files — the 20-chunk NIST PDF, writing Isar per
// chunk — so under full-suite contention one can pass the 30 s default (it
// did, once). Minutes, not seconds, is the honest budget for this file.
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:isar_community/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/repositories/document_source_repository_impl.dart';
import 'package:uniun/data/repositories/isar_document_vector_repository_impl.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/repositories/pending_embedding_repository_impl.dart';
import 'package:uniun/features/shiv/rag/indexing/note_embedding_worker.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/extraction/document_extraction_service.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';
import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:mocktail/mocktail.dart';

import '../_helpers/note_embedding_worker_factory.dart';
import '../_helpers/docx_fixtures.dart';
import '../_helpers/fake_image_label_source.dart';
import '../_helpers/fake_ocr_text_source.dart';
import '../_helpers/fake_path_provider.dart';
import '../_helpers/isar_seeds.dart';
import '../_helpers/isar_test_harness.dart';
import '../_helpers/pdf_fixtures.dart';
import '../_helpers/pdfium_test_lib.dart';

/// End-to-end document RAG flow against real PDF and DOCX files, real PDFium
/// (including which pages it renders for OCR), the real DOCX reader, real
/// Isar (vectors stored on the chunk rows) — and images through a faked OCR step: cache row → extract → chunk → embed → store → retrieve →
/// citation. Only the embedder is faked
/// (deterministic vectors) — it needs flutter_gemma, which is device-only;
/// `integration_test/` covers the real one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late DocumentIndexer indexer;
  late IsarDocumentVectorRepositoryImpl vectors;
  late DocumentSourceRepositoryImpl sources;
  late _StubEmbedding embedding;
  late ResolveDocumentCitationsUseCase resolveCitations;
  late VectorSearchService searchService;
  late _FakeNoteVectors noteVectors;
  late FakeOcrTextSource ocr;
  late FakeImageLabelSource labels;

  const sha = 'nistsha';
  const docxSha = 'leavesha';

  /// Leaves only DOCX in the cache, so retrieval runs against the DOCX's own
  /// handful of vectors.
  ///
  /// Keeps these tests about DOCX wiring rather than about which of many
  /// chunks ranks first.
  Future<void> dropPdf() =>
      isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(sha));

  /// Puts [sha] on a saved note — what makes a cached document one Shiv may
  /// cite.
  Future<void> saveNoteWith(String sha, String mime) => isar.writeTxn(
    () => isar.savedNoteModels.put(
      savedNoteRow(
        'saved-$sha',
        attachments: [mediaAttachmentRow(sha256: sha, mime: mime)],
      ),
    ),
  );

  /// The LibreOffice leave policy, cached as a downloaded .docx would be and
  /// attached to a saved note.
  Future<void> cacheDocx({
    String sha = docxSha,
    String name = 'leave-policy-libreoffice.docx',
  }) async {
    await isar.writeTxn(
      () => isar.mediaCacheModels.put(
        mediaCacheRow(
          sha,
          localPath: docxFixture(name),
          mime: DocumentKind.docx.mime,
        ),
      ),
    );
    await saveNoteWith(sha, DocumentKind.docx.mime);
  }

  Future<List<DocumentChunkModel>> chunksOf(String sha) =>
      isar.documentChunkModels.where().sha256EqualToAnyOrdinal(sha).findAll();

  Future<DocumentChunkModel> docxChunkContaining(String phrase) async =>
      (await chunksOf(docxSha)).firstWhere((c) => c.text.contains(phrase));

  setUpAll(() async {
    registerFallbackValue(<String>[]);
    registerFallbackValue(('', '', <double>[]));
    registerFallbackValue((<String>[], 1));
    final boot = await Directory.systemTemp.createTemp('pdf_rag_flow_boot');
    PathProviderPlatform.instance = FakePathProviderPlatform(
      docs: boot.path,
      support: boot.path,
    );
    await ensurePdfium();
    await pdfrxFlutterInitialize();
  });

  setUp(() async {
    isar = await openTestIsar();
    vectors = IsarDocumentVectorRepositoryImpl(isar);
    sources = DocumentSourceRepositoryImpl(isar);
    embedding = _StubEmbedding();
    // Real use cases and service on top of the real repositories — only the
    // note vector store is doubled, since notes are not what this flow is about.
    noteVectors = _FakeNoteVectors();
    resolveCitations = ResolveDocumentCitationsUseCase(sources);
    searchService = VectorSearchService(
      SearchVectorNotesUseCase(noteVectors),
      SearchDocumentChunksUseCase(vectors),
    );
    indexer = DocumentIndexer(
      isar,
      // Real PDF and DOCX readers; OCR and labeling are faked — ML Kit runs
      // only on a phone, and integration_test/ covers the real ones.
      DocumentExtractionService(
        PdfrxTextSource(),
        ArchiveDocxTextSource(),
        ocr = FakeOcrTextSource(),
        labels = FakeImageLabelSource(),
      ),
      // Real use case over the real vector repository — only the embedder
      // itself is stubbed.
      EmbedAndStoreChunkUseCase(embedding, vectors),
      // No signed-in user: documents count through saved notes only.
      _MockGetActiveUser()..stubSignedOut(),
    );

    // The real fixture, registered in the cache exactly as a downloaded or
    // uploaded blob would be.
    await isar.writeTxn(
      () => isar.mediaCacheModels.put(
        mediaCacheRow(
          sha,
          localPath: pdfFixture('nist_sp800-145.pdf'),
          mime: 'application/pdf',
        ),
      ),
    );
    await saveNoteWith(sha, 'application/pdf');
  });

  tearDown(() async {
    await indexer.dispose();
    await isar.close(deleteFromDisk: true);
  });

  test('a cached PDF becomes retrievable and citable', () async {
    await indexer.reconcile();

    // Indexed, with the fixture's real page count.
    final row = await isar.documentIndexModels
        .filter()
        .sha256EqualTo(sha)
        .findFirst();
    expect(row?.status, DocumentIndexStatus.indexed);
    expect(row?.pageCount, 7);
    expect(row!.chunkCount, greaterThan(1));

    // A query shaped like the page-6 chunk retrieves that chunk...
    final target = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll()
        .then(
          (all) => all.firstWhere(
            (c) => c.text.toLowerCase().contains('cloud computing is a model'),
          ),
        );

    final hits = await vectors.search(
      embedding.vectorFor(target.text),
      topK: 3,
    );

    expect(hits, isNotEmpty);
    expect(hits.first.chunkId, chunkIdOf(sha, target.ordinal));
    expect(
      hits.first.label,
      target.label,
      reason: 'the citation must carry the page the text came from',
    );

    // ...and that hit resolves into a citation the Sources sheet can render.
    final citations = (await sources.resolve([
      hits.first.chunkId,
    ])).getOrElse(() => []);
    expect(citations, hasLength(1));
    expect(citations.single.localPath, endsWith('nist_sp800-145.pdf'));
    expect(citations.single.label, target.label);
  });

  test('every indexed chunk is retrievable by its own text', () async {
    await indexer.reconcile();
    final chunks = await chunksOf(sha);
    expect(chunks.length, greaterThan(15));

    final missed = <int>[];
    for (final c in chunks) {
      final top = (await vectors.search(
        embedding.vectorFor(c.text),
        topK: 1,
      )).single;
      if (top.chunkId != chunkIdOf(sha, c.ordinal)) missed.add(c.ordinal);
    }

    // An approximate index reached only 24 % of chunks on a phone; an exact
    // scan must reach all of them.
    expect(missed, isEmpty);
  });

  test('the attaching note names the document in its citation', () async {
    await isar.writeTxn(
      () => isar.noteModels.put(
        noteRow(
          'n1',
          attachments: [
            mediaAttachmentRow(
              sha256: sha,
              mime: 'application/pdf',
              filename: 'NIST Cloud Definition.pdf',
            ),
          ],
        ),
      ),
    );

    await indexer.reconcile();
    final chunk =
        (await isar.documentChunkModels
                .where()
                .sha256EqualToAnyOrdinal(sha)
                .findAll())
            .first;

    final citations = (await sources.resolve([
      chunkIdOf(sha, chunk.ordinal),
    ])).getOrElse(() => []);

    expect(citations.single.title, 'NIST Cloud Definition.pdf');
  });

  test('removing the cached blob stops the document being cited', () async {
    await indexer.reconcile();
    final chunk =
        (await isar.documentChunkModels
                .where()
                .sha256EqualToAnyOrdinal(sha)
                .findAll())
            .first;
    final id = chunkIdOf(sha, chunk.ordinal);
    final query = embedding.vectorFor(chunk.text);
    expect(await vectors.search(query, topK: 3), isNotEmpty);

    await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(sha));
    await indexer.reconcile();

    expect(
      await vectors.search(query, topK: 3),
      isEmpty,
      reason: 'purging a document removes its vectors with its chunk rows',
    );
    expect((await sources.resolve([id])).getOrElse(() => []), isEmpty);
    expect(await isar.documentIndexModels.count(), 0);
  });

  group('through the real retrieval stack', () {
    late RagPipeline pipeline;

    /// Real embedding stub, real search service, real PromptBuilder — the whole
    /// retrieval path above the repositories is production code. Only the
    /// peripheral use cases (identity, memory, graph, active model) are doubled,
    /// since none of them is what this flow is about.
    RagPipeline buildPipeline({ManasContextLoader? loader}) {
      final getActiveUser = _MockGetActiveUser();
      final getOwnProfile = _MockGetOwnProfile();
      final getMemories = _MockGetMemories();
      final getNeighbours = _MockGetNeighbours();
      final getNodesByKeys = _MockGetNodesByKeys();
      final getActiveModel = _MockGetActiveModel();

      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('none')));
      when(
        () => getOwnProfile.call(any()),
      ).thenAnswer((_) async => const Right<Failure, ProfileEntity?>(null));
      when(
        () => getMemories.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNeighbours.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNodesByKeys.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getActiveModel.call(),
      ).thenAnswer((_) async => const Right<Failure, LlmModelInfo?>(null));

      return RagPipeline(
        embedding,
        searchService,
        const PromptBuilder(),
        getActiveUser,
        getOwnProfile,
        getMemories,
        getNeighbours,
        getNodesByKeys,
        getActiveModel,
        loader ?? _MockManasLoader(),
      );
    }

    setUp(() => pipeline = buildPipeline());

    test('a question reaches the prompt as a cited document passage', () async {
      await indexer.reconcile();
      final target =
          (await isar.documentChunkModels
                  .where()
                  .sha256EqualToAnyOrdinal(sha)
                  .findAll())
              .firstWhere(
                (c) =>
                    c.text.toLowerCase().contains('cloud computing is a model'),
              );

      // The stub embeds by text, so asking with the passage's own words is the
      // deterministic stand-in for a semantically close question.
      final msg = await pipeline.buildMessage(userQuestion: target.text);

      expect(msg.sourceChunkIds, contains(chunkIdOf(sha, target.ordinal)));
      expect(msg.sourceNoteIds, isEmpty);
      expect(msg.contextCount, greaterThan(0));
      expect(msg.userMessage, contains('## Relevant Documents'));
      expect(msg.userMessage, contains('(p.${target.label})'));
    });

    test(
      'the ids it emits resolve into citations the sheet can render',
      () async {
        await indexer.reconcile();
        final target =
            (await isar.documentChunkModels
                    .where()
                    .sha256EqualToAnyOrdinal(sha)
                    .findAll())
                .first;

        final msg = await pipeline.buildMessage(userQuestion: target.text);
        final citations = (await resolveCitations.call(
          msg.sourceChunkIds,
        )).getOrElse(() => []);

        expect(citations, isNotEmpty);
        expect(citations.first.localPath, endsWith('nist_sp800-145.pdf'));
        expect(citations.first.label, isNotEmpty);
      },
    );

    test('notes and documents both reach one answer', () async {
      await indexer.reconcile();
      final target =
          (await isar.documentChunkModels
                  .where()
                  .sha256EqualToAnyOrdinal(sha)
                  .findAll())
              .first;
      noteVectors.results = const [
        ScoredNote(noteId: 'n1', score: 0.9, content: 'a note about clouds'),
      ];

      final msg = await pipeline.buildMessage(userQuestion: target.text);

      expect(msg.sourceNoteIds, ['n1']);
      expect(msg.sourceChunkIds, isNotEmpty);
      expect(msg.userMessage, contains('## Relevant Documents'));
      expect(msg.userMessage, contains('a note about clouds'));
    });

    test('a Manas-scoped question never reaches the document store', () async {
      await indexer.reconcile();
      final loader = _MockManasLoader();
      when(
        () => loader.merge(
          manasIds: any(named: 'manasIds'),
          budget: any(named: 'budget'),
          relevanceQuery: any(named: 'relevanceQuery'),
        ),
      ).thenAnswer((_) async => []);
      final scoped = buildPipeline(loader: loader);

      final msg = await scoped.buildMessage(
        userQuestion: 'anything',
        manasIds: ['m1'],
      );

      expect(
        msg.sourceChunkIds,
        isEmpty,
        reason: 'documents have no Manas membership to scope by',
      );
    });

    test(
      'a DOCX passage reaches the prompt under its heading, not a page',
      () async {
        await dropPdf();
        await cacheDocx();
        await indexer.reconcile();
        final target = await docxChunkContaining(
          'within 30 days of the expense',
        );

        final msg = await pipeline.buildMessage(userQuestion: target.text);

        expect(
          msg.sourceChunkIds,
          contains(chunkIdOf(docxSha, target.ordinal)),
        );
        expect(msg.userMessage, contains('• (Travel and Expenses) '));
        expect(msg.userMessage, isNot(contains('(p.Travel')));
      },
    );

    test(
      'a DOCX preamble reaches the prompt with no location marker',
      () async {
        await dropPdf();
        await cacheDocx();
        await indexer.reconcile();
        final preamble = await docxChunkContaining('applies to every UNIUN');
        expect(preamble.label, '');

        final msg = await pipeline.buildMessage(userQuestion: preamble.text);

        expect(msg.userMessage, contains('• This policy applies'));
      },
    );

    test('a DOCX answer resolves to a citation naming its section', () async {
      await dropPdf();
      await cacheDocx();
      await indexer.reconcile();
      final target = await docxChunkContaining('24 days of paid annual leave');

      final msg = await pipeline.buildMessage(userQuestion: target.text);
      final citation = (await resolveCitations.call(
        msg.sourceChunkIds,
      )).getOrElse(() => []).firstWhere((c) => c.sha256 == docxSha);

      expect(citation.kind, DocumentKind.docx);
      expect(citation.label, 'Annual Leave');
      expect(citation.localPath, endsWith('leave-policy-libreoffice.docx'));
    });

    test('an image passage reaches the prompt marked as from an image', () async {
      await dropPdf();
      ocr.texts['/photos/n.jpg'] =
          'OFFICE ORDER. Earned leave may be carried forward up to 15 days '
          'into the next calendar year, and encashment requests must reach the '
          'Establishment Section before 31 January of that year. This order '
          'is issued with the approval of the competent authority.';
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow('nsha', localPath: '/photos/n.jpg', mime: 'image/jpeg'),
        ),
      );
      await saveNoteWith('nsha', 'image/jpeg');
      await indexer.reconcile();
      final chunk = (await chunksOf('nsha')).single;

      final msg = await pipeline.buildMessage(userQuestion: chunk.text);

      expect(msg.sourceChunkIds, contains(chunkIdOf('nsha', chunk.ordinal)));
      expect(msg.userMessage, contains('• (image) OFFICE ORDER'));
    });

    test('a document purged after indexing is no longer cited', () async {
      await indexer.reconcile();
      final target =
          (await isar.documentChunkModels
                  .where()
                  .sha256EqualToAnyOrdinal(sha)
                  .findAll())
              .first;
      expect(
        (await pipeline.buildMessage(userQuestion: target.text)).sourceChunkIds,
        isNotEmpty,
      );

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(sha));
      await indexer.reconcile();

      final after = await pipeline.buildMessage(userQuestion: target.text);
      expect(after.sourceChunkIds, isEmpty);
      expect(after.userMessage, isNot(contains('Relevant Documents')));
    });
  });

  group('image', () {
    const imageSha = 'noticesha';
    const notice =
        'OFFICE ORDER. With effect from 1 October 2026 every '
        'employee may carry forward up to 15 days of earned leave into the '
        'next calendar year. Requests for encashment of leave must reach the '
        'Establishment Section before 31 January. This order is issued with '
        'the approval of the competent authority.';

    Future<void> cacheNotice() async {
      await dropPdf();
      ocr.texts['/photos/notice.jpg'] = notice;
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow(
            imageSha,
            localPath: '/photos/notice.jpg',
            mime: 'image/jpeg',
          ),
        ),
      );
      await saveNoteWith(imageSha, 'image/jpeg');
    }

    test(
      'a photographed notice becomes searchable and cites the image',
      () async {
        await cacheNotice();

        await indexer.reconcile();

        final row = await isar.documentIndexModels
            .filter()
            .sha256EqualTo(imageSha)
            .findFirst();
        expect(row?.status, DocumentIndexStatus.indexed);
        expect(row?.kind, DocumentKind.image);

        final chunk = (await chunksOf(imageSha)).single;
        final hit = (await vectors.search(
          embedding.vectorFor(chunk.text),
          topK: 3,
        )).first;
        expect(hit.kind, DocumentKind.image);

        final citation = (await sources.resolve([
          hit.chunkId,
        ])).getOrElse(() => []).single;
        expect(citation.kind, DocumentKind.image);
        expect(citation.localPath, '/photos/notice.jpg');
      },
    );

    test('a photo without text is found by what is in it', () async {
      await dropPdf();
      ocr.texts['/photos/dog.jpg'] = '';
      labels.labels['/photos/dog.jpg'] = ['Dog', 'Beach', 'Sky'];
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow(
            'dogsha',
            localPath: '/photos/dog.jpg',
            mime: 'image/jpeg',
          ),
        ),
      );
      await saveNoteWith('dogsha', 'image/jpeg');

      await indexer.reconcile();

      final chunk = (await chunksOf('dogsha')).single;
      expect(chunk.text, 'Photo showing: dog, beach, sky');
      final hit = (await vectors.search(
        embedding.vectorFor(chunk.text),
        topK: 3,
      )).first;
      final citation = (await sources.resolve([
        hit.chunkId,
      ])).getOrElse(() => []).single;
      expect(citation.kind, DocumentKind.image);
      expect(citation.localPath, '/photos/dog.jpg');
    });

    test('a photo with no text is kept but never cited', () async {
      await dropPdf();
      ocr.texts['/photos/beach.jpg'] = '';
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow(
            'beachsha',
            localPath: '/photos/beach.jpg',
            mime: 'image/jpeg',
          ),
        ),
      );
      await saveNoteWith('beachsha', 'image/jpeg');

      await indexer.reconcile();

      final row = await isar.documentIndexModels
          .filter()
          .sha256EqualTo('beachsha')
          .findFirst();
      expect(row?.status, DocumentIndexStatus.notSearchable);
      expect(await chunksOf('beachsha'), isEmpty);
    });
  });

  group('selective OCR', () {
    const annexure =
        'ANNEXURE. Approval of the competent authority for the revised '
        'office timings, conveyed by the Secretary on 20 October 2026.';
    const photoNotice =
        'NOTICE. The record room will remain closed for digitisation from '
        '3 to 7 November. Urgent certified-copy requests go to the Tehsil office.';

    /// Every file OCR was asked to read, with its pixel size.
    late List<({String path, int width, int height})> read;

    setUp(() {
      read = [];
      ocr.reader = (path) {
        final png = img.decodePng(File(path).readAsBytesSync())!;
        read.add((path: path, width: png.width, height: png.height));
        return path.endsWith('_1.png') ? annexure : photoNotice;
      };
    });

    Future<void> cachePdf(String sha, String fixture) async {
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow(
            sha,
            localPath: pdfFixture(fixture),
            mime: 'application/pdf',
          ),
        ),
      );
      await saveNoteWith(sha, 'application/pdf');
    }

    Future<DocumentIndexModel?> rowOf(String sha) =>
        isar.documentIndexModels.filter().sha256EqualTo(sha).findFirst();

    test('a typed publication is never rendered for OCR', () async {
      await indexer.reconcile();

      expect((await rowOf(sha))?.status, DocumentIndexStatus.indexed);
      expect(ocr.calls, 0);
    });

    test(
      'a scanned PDF, once unsearchable, is read and cited by page',
      () async {
        await dropPdf();
        await cachePdf('scansha', 'scanned_notice.pdf');

        await indexer.reconcile();

        expect((await rowOf('scansha'))?.status, DocumentIndexStatus.indexed);
        final chunk = (await chunksOf('scansha')).single;
        expect(chunk.text, photoNotice);
        expect(chunk.label, '1');
        final page = (await PdfrxTextSource().pageSignals(
          pdfFixture('scanned_notice.pdf'),
        ))!.single;
        expect(
          read.single.width,
          closeTo(page.width * 200 / 72, 2),
          reason: 'the whole page, at 200 dpi',
        );
        expect(
          File(read.single.path).existsSync(),
          isFalse,
          reason: 'the render is deleted once read',
        );
      },
    );

    test('only the scanned annexure of a mixed circular is OCRed', () async {
      await dropPdf();
      await cachePdf('mixedsha', 'mixed_circular_with_scanned_annexure.pdf');

      await indexer.reconcile();

      final chunks = await chunksOf('mixedsha');
      expect(read, hasLength(1));
      expect(read.single.path, endsWith('_1.png'));
      expect(
        chunks.where((c) => c.label == '1').map((c) => c.text).join(' '),
        contains('Revised Office Timings'),
      );
      expect(chunks.where((c) => c.label == '2').single.text, annexure);
    });

    test('a pasted photo is read on its own, beside the typed text', () async {
      await dropPdf();
      await cachePdf('reportsha', 'typed_report_with_pasted_notice.pdf');

      await indexer.reconcile();

      final text = (await chunksOf('reportsha')).map((c) => c.text).join('\n');
      expect(text, contains('District Record Room'));
      expect(text, contains(photoNotice));
      expect(
        read.single.width,
        lessThan(595 * 200 / 72 * 0.8),
        reason: 'just the photo is rendered, not the page',
      );
    });

    test('a large picture in a DOCX is read where it sits', () async {
      await dropPdf();
      final dir = await Directory.systemTemp.createTemp('flow_docx');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/memo.docx';
      await File(path).writeAsBytes(
        minimalDocx(
          document: wDocument(
            wP('Memo on the record room closure.') +
                wDrawing('rId1') +
                wP('Please plan certified-copy work accordingly.'),
          ),
          extra: {
            'word/_rels/document.xml.rels': wRels({'rId1': 'media/image1.png'}),
          },
          media: {
            'word/media/image1.png': img.encodePng(
              img.Image(width: 1200, height: 800),
            ),
          },
        ),
      );
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow(
            'memosha',
            localPath: path,
            mime: DocumentKind.docx.mime,
          ),
        ),
      );
      await saveNoteWith('memosha', DocumentKind.docx.mime);

      await indexer.reconcile();

      final text = (await chunksOf('memosha')).map((c) => c.text).join('\n');
      expect(text, contains('Memo on the record room closure.'));
      expect(
        text.indexOf(photoNotice),
        allOf(
          greaterThan(text.indexOf('Memo')),
          lessThan(text.indexOf('Please plan')),
        ),
      );
      expect(File(read.single.path).existsSync(), isFalse);
    });
  });

  group('docx', () {
    test('a cached DOCX becomes retrievable and citable by heading', () async {
      await dropPdf();
      await cacheDocx();

      await indexer.reconcile();

      final row = await isar.documentIndexModels
          .filter()
          .sha256EqualTo(docxSha)
          .findFirst();
      expect(row?.status, DocumentIndexStatus.indexed);
      expect(row?.pageCount, 0, reason: 'a DOCX has no fixed pages');
      expect((await chunksOf(docxSha)).map((c) => c.label).toSet(), {
        '',
        'Annual Leave',
        'Sick Leave',
        'Remote Work',
        'Travel and Expenses',
      });

      final target = await docxChunkContaining('12 days of paid sick leave');
      final hit = (await vectors.search(
        embedding.vectorFor(target.text),
        topK: 3,
      )).first;
      expect(hit.chunkId, chunkIdOf(docxSha, target.ordinal));
      expect(hit.kind, DocumentKind.docx);
      expect(hit.label, 'Sick Leave');
    });

    test('the table stays in the section it sits in', () async {
      await cacheDocx();
      await indexer.reconcile();

      final meals = await docxChunkContaining('Meals | 800 rupees');

      expect(meals.label, 'Travel and Expenses');
    });

    test('a PDF and a DOCX index side by side in one pass', () async {
      await cacheDocx();

      await indexer.reconcile();

      final statuses = {
        for (final r in await isar.documentIndexModels.where().findAll())
          r.sha256: r.status,
      };
      expect(statuses, {
        sha: DocumentIndexStatus.indexed,
        docxSha: DocumentIndexStatus.indexed,
      });
    });

    test('removing the DOCX purges it and leaves the PDF alone', () async {
      await cacheDocx();
      await indexer.reconcile();
      final target = await docxChunkContaining('up to 8 days per month');
      final query = embedding.vectorFor(target.text);

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(docxSha));
      await indexer.reconcile();

      expect(await vectors.search(query, topK: 3), isEmpty);
      expect(await chunksOf(docxSha), isEmpty);
      expect(await chunksOf(sha), isNotEmpty);
    });

    test('re-running the flow does not duplicate DOCX chunks', () async {
      await cacheDocx();
      await indexer.reconcile();
      final first = (await chunksOf(docxSha)).length;

      await indexer.reconcile();

      expect((await chunksOf(docxSha)).length, first);
    });

    test('real Word-authored documents index end to end', () async {
      await cacheDocx(sha: 'nistdocx', name: 'nist-cui-ssp-template.docx');
      await cacheDocx(
        sha: 'usptodocx',
        name: 'uspto-initial-filing-template.docx',
      );

      await indexer.reconcile();

      for (final s in ['nistdocx', 'usptodocx']) {
        final row = await isar.documentIndexModels
            .filter()
            .sha256EqualTo(s)
            .findFirst();
        expect(row?.status, DocumentIndexStatus.indexed, reason: s);
      }
      final nist = await chunksOf('nistdocx');
      expect(nist.every((c) => c.text.length <= 700), isTrue);
      expect(nist.any((c) => c.text.contains('FORMCHECKBOX')), isFalse);
      expect(nist.map((c) => c.label).toSet(), {
        '',
        'Roles of Users and Number of Each Type:',
      });
      expect((await chunksOf('usptodocx')).map((c) => c.label).toSet(), {''});
    });

    test('a DOCX opened from someone else\'s note is never indexed', () async {
      await isar.writeTxn(
        () => isar.mediaCacheModels.put(
          mediaCacheRow(
            'opened',
            localPath: docxFixture('leave-policy-libreoffice.docx'),
            mime: DocumentKind.docx.mime,
          ),
        ),
      );
      await isar.writeTxn(
        () => isar.noteModels.put(
          noteRow(
            'theirs',
            attachments: [
              mediaAttachmentRow(
                sha256: 'opened',
                mime: DocumentKind.docx.mime,
              ),
            ],
          ),
        ),
      );

      await indexer.reconcile();

      expect(
        await isar.documentIndexModels
            .filter()
            .sha256EqualTo('opened')
            .findFirst(),
        isNull,
      );
      expect(await chunksOf('opened'), isEmpty);
    });

    test(
      'a file with a .docx mime that is not a Word file is not searchable',
      () async {
        final bogus = await writeTempDocx('not really a docx'.codeUnits);
        await isar.writeTxn(
          () => isar.mediaCacheModels.put(
            mediaCacheRow(
              'bogus',
              localPath: bogus,
              mime: DocumentKind.docx.mime,
            ),
          ),
        );
        await saveNoteWith('bogus', DocumentKind.docx.mime);

        await indexer.reconcile();

        final row = await isar.documentIndexModels
            .filter()
            .sha256EqualTo('bogus')
            .findFirst();
        expect(row?.status, DocumentIndexStatus.notSearchable);
        expect(await chunksOf('bogus'), isEmpty);
      },
    );
  });

  test('re-running the whole flow changes nothing', () async {
    await indexer.reconcile();
    final firstChunks = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll();
    final probe = embedding.vectorFor(firstChunks.first.text);
    final firstHits = await vectors.search(probe, topK: 5);

    await indexer.reconcile();

    final again = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll();
    expect(
      again.length,
      firstChunks.length,
      reason: 're-indexing must replace, not duplicate',
    );
    expect(
      (await vectors.search(probe, topK: 5)).map((h) => h.chunkId),
      firstHits.map((h) => h.chunkId),
    );
  });

  group('a plain note and a PDF note published together', () {
    late _GatedEmbedding gated;
    late _RecordingNoteVectors notes;
    late PendingEmbeddingRepositoryImpl pendingRepo;
    late NoteEmbeddingWorker worker;
    late EmbedAndStoreNoteUseCase save;
    late DocumentIndexer gatedIndexer;

    setUp(() {
      gated = _GatedEmbedding();
      notes = _RecordingNoteVectors();
      pendingRepo = PendingEmbeddingRepositoryImpl(isar: isar);
      worker = aNoteEmbeddingWorker(
        pending: pendingRepo,
        embedding: gated,
        vector: notes,
        extract: _MockExtractKnowledge()..stub(),
        scheduler: InferenceScheduler(),
      );
      save = EmbedAndStoreNoteUseCase(pendingRepo, worker);
      gatedIndexer = DocumentIndexer(
        isar,
        DocumentExtractionService(
          PdfrxTextSource(),
          ArchiveDocxTextSource(),
          FakeOcrTextSource(),
          FakeImageLabelSource(),
        ),
        EmbedAndStoreChunkUseCase(gated, vectors),
        _MockGetActiveUser()..stubSignedOut(),
      );
    });

    tearDown(() => gatedIndexer.dispose());

    Future<void> noteQueueEmpty() async {
      for (var i = 0; i < 600; i++) {
        if ((await pendingRepo.count()).getOrElse(() => -1) == 0) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test(
      'both are searchable and the embedder runs one embed at a time',
      () async {
        gated.embedTime = const Duration(milliseconds: 15);
        final indexing = gatedIndexer.reconcile();
        // Publish the notes only once the PDF's chunks are really being embedded,
        // so the two pipelines have to share the gate.
        while (gated.texts.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await Future.wait([
          save.call((
            'plain',
            'A plain note about espresso machines and grinders',
          )),
          save.call((
            'pdfnote',
            'See the attached circular on cloud computing',
          )),
        ]);
        await indexing;
        await noteQueueEmpty();

        expect(notes.stored.keys.toSet(), {'plain', 'pdfnote'});
        final row = await isar.documentIndexModels
            .filter()
            .sha256EqualTo(sha)
            .findFirst();
        expect(row?.status, DocumentIndexStatus.indexed);
        final target = await isar.documentChunkModels
            .where()
            .sha256EqualToAnyOrdinal(sha)
            .findAll()
            .then(
              (all) => all.firstWhere(
                (c) =>
                    c.text.toLowerCase().contains('cloud computing is a model'),
              ),
            );
        final hits = await vectors.search(
          gated.vectorFor(target.text),
          topK: 3,
        );
        expect(hits.first.chunkId, chunkIdOf(sha, target.ordinal));
        expect(gated.maxInFlight, 1);
        // Both pipelines really embedded on the one gate.
        expect(
          gated.texts,
          contains('A plain note about espresso machines and grinders'),
        );
        expect(gated.texts.length, greaterThan(row!.chunkCount));
      },
    );

    test(
      'a question asked mid-index is embedded right after the one in flight, '
      'ahead of the remaining chunks',
      () async {
        gated.embedTime = const Duration(milliseconds: 15);
        final indexing = gatedIndexer.reconcile();
        while (gated.texts.length < 3) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        // Other pipelines (notes, more chunks) have embeds queued too.
        for (var i = 0; i < 4; i++) {
          unawaited(gated.embed('queued background $i', isDocument: true));
        }
        final startedBefore = gated.texts.length;

        final answer = await gated.embed('what is cloud computing');
        final position = gated.texts.indexOf('what is cloud computing');
        await indexing;

        expect(answer, isNotEmpty);
        expect(
          position,
          lessThanOrEqualTo(startedBefore + 1),
          reason: 'only the embed already running may go first',
        );
        expect(
          gated.texts.length - position,
          greaterThan(3),
          reason: 'most of the PDF was still queued behind the question',
        );
      },
    );

    test(
      'a note queued while the PDF is indexing is not starved by it',
      () async {
        gated.embedTime = const Duration(milliseconds: 10);
        final indexing = gatedIndexer.reconcile();
        await Future<void>.delayed(const Duration(milliseconds: 30));

        await save.call(('late', 'a note published while the PDF indexes'));
        await noteQueueEmpty();
        await indexing;

        expect(notes.stored.keys, contains('late'));
      },
    );
  });
}

/// Note vector store double — notes are not what this flow exercises, so it
/// returns whatever the test seeds and nothing more.
/// A note vector store that remembers what it was given.
class _RecordingNoteVectors extends _FakeNoteVectors {
  final Map<String, List<double>> stored = {};

  @override
  Future<void> upsert(String id, List<double> vector) async =>
      stored[id] = vector;
}

class _MockExtractKnowledge extends Mock implements ExtractKnowledgeUseCase {
  void stub() => when(() => call(any())).thenAnswer((_) async {});
}

/// The deterministic embedder behind the REAL gate: what the service does, with
/// the model replaced by [vectorFor]. Records how many embeds ran at once and
/// what was embedded.
class _GatedEmbedding extends _StubEmbedding {
  final EmbeddingQueue queue = EmbeddingQueue();
  Duration embedTime = const Duration(milliseconds: 2);
  int _inFlight = 0;
  int maxInFlight = 0;
  final List<String> texts = [];

  @override
  Future<List<double>> embed(String text, {bool isDocument = false}) {
    return queue.run(
      () async {
        _inFlight++;
        if (_inFlight > maxInFlight) maxInFlight = _inFlight;
        texts.add(text);
        await Future<void>.delayed(embedTime);
        _inFlight--;
        return vectorFor(text);
      },
      priority: isDocument
          ? EmbedPriority.background
          : EmbedPriority.interactive,
    );
  }
}

class _FakeNoteVectors implements VectorRepository {
  List<ScoredNote> results = const [];

  @override
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
  }) async => results;

  @override
  Future<void> upsert(String id, List<double> vector) async {}

  @override
  Future<void> delete(String id) async {}
}

class _MockGetActiveUser extends Mock implements GetActiveUserUseCase {}

class _MockGetOwnProfile extends Mock implements GetOwnProfileUseCase {}

class _MockGetMemories extends Mock implements GetMemoriesByNoteIdsUseCase {}

class _MockGetNeighbours extends Mock implements GetGraphNeighboursUseCase {}

class _MockGetNodesByKeys extends Mock implements GetGraphNodesByKeysUseCase {}

class _MockGetActiveModel extends Mock implements GetActiveLlmModelUseCase {}

class _MockManasLoader extends Mock implements ManasContextLoader {}

/// Deterministic stand-in for the on-device embedder: a hashed bag of words.
///
/// Identical text embeds identically (cosine 1), and texts sharing words sit
/// closer than texts that do not — a crude but real similarity structure, like
/// a real embedder's. Real semantic behaviour is the device test's job.

class _StubEmbedding implements EmbeddingService {
  List<double> vectorFor(String text) {
    final v = List<double>.filled(embeddingsDimensions, 0);
    for (final w in RegExp(
      r'\w+',
      unicode: true,
    ).allMatches(text.toLowerCase())) {
      v[w.group(0).hashCode.abs() % embeddingsDimensions] += 1;
    }
    return v;
  }

  @override
  Future<List<double>> embed(String text, {bool isDocument = false}) async =>
      vectorFor(text);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

extension on _MockGetActiveUser {
  void stubSignedOut() => when(
    () => call(),
  ).thenAnswer((_) async => const Left(Failure.notFoundFailure('signed out')));
}
