import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/extraction/document_extraction_service.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';

import '../../../../_helpers/fake_docx_text_source.dart';
import '../../../../_helpers/fake_image_label_source.dart';
import '../../../../_helpers/fake_ocr_text_source.dart';
import '../../../../_helpers/fake_pdf_text_source.dart';
import '../../../../_helpers/fixtures.dart';
import '../../../../_helpers/isar_seeds.dart';
import '../../../../_helpers/isar_test_harness.dart';

class _MockEmbedAndStore extends Mock implements EmbedAndStoreChunkUseCase {}

class _MockActiveUser extends Mock implements GetActiveUserUseCase {}

/// Covers: which documents Shiv may cite (own feed notes and saved notes only),
/// reconcile indexing of PDFs and DOCX, progress logging,
/// non-document skipping, not-searchable recording,
/// embedder-failure retry, orphan purge, idempotency, coalescing, start().
void main() {
  const prose = 'The quarterly leave policy has been revised. ';
  const pdf = 'application/pdf';

  late Isar isar;
  late FakePdfTextSource source;
  late FakeDocxTextSource docx;
  late FakeOcrTextSource ocr;
  late _MockEmbedAndStore embedAndStore;
  late _MockActiveUser activeUser;
  late DocumentIndexer indexer;

  /// chunkId -> text, as handed to the use case.
  final stored = <String, String>{};

  setUpAll(() => registerFallbackValue(('', '')));

  setUp(() async {
    isar = await openTestIsar();
    source = FakePdfTextSource();
    docx = FakeDocxTextSource();
    ocr = FakeOcrTextSource();
    stored.clear();
    embedAndStore = _MockEmbedAndStore();
    when(() => embedAndStore.call(any())).thenAnswer((i) async {
      final (id, text) = i.positionalArguments.first as (String, String);
      stored[id] = text;
      return true;
    });
    activeUser = _MockActiveUser();
    when(
      () => activeUser.call(),
    ).thenAnswer((_) async => Right(aUserKey(pubkeyHex: kSelfPub)));
    indexer = DocumentIndexer(
      isar,
      DocumentExtractionService(source, docx, ocr, FakeImageLabelSource()),
      embedAndStore,
      activeUser,
    );
  });

  tearDown(() async {
    await indexer.dispose();
    await isar.close(deleteFromDisk: true);
  });

  /// Attaches [sha] to a saved note — the usual way a document becomes one
  /// Shiv may cite.
  Future<void> save(String sha, {String mime = pdf, String id = ''}) =>
      isar.writeTxn(
        () => isar.savedNoteModels.put(
          savedNoteRow(
            id.isEmpty ? 'saved-$sha' : id,
            attachments: [mediaAttachmentRow(sha256: sha, mime: mime)],
          ),
        ),
      );

  /// A note authored by [author] (the user, by default) carrying [sha].
  Future<void> ownNote(
    String sha, {
    String mime = pdf,
    int kind = kNoteKind,
    String author = kSelfPub,
  }) => isar.writeTxn(
    () => isar.noteModels.put(
      noteRow(
        'note-$sha-$kind-$author',
        authorPubkey: author,
        kind: kind,
        attachments: [mediaAttachmentRow(sha256: sha, mime: mime)],
      ),
    ),
  );

  /// A cached document, attached to a saved note unless [saved] is false.
  Future<void> cacheDoc(
    String sha, {
    required String localPath,
    required String mime,
    bool saved = true,
  }) async {
    await isar.writeTxn(
      () => isar.mediaCacheModels.put(
        mediaCacheRow(sha, localPath: localPath, mime: mime),
      ),
    );
    if (saved) await save(sha, mime: mime);
  }

  Future<void> seedPdf(
    String sha, {
    String mime = pdf,
    List<String>? pages,
    bool saved = true,
  }) async {
    source.pages['/p/$sha.pdf'] = pages ?? [prose * 6];
    await cacheDoc(sha, localPath: '/p/$sha.pdf', mime: mime, saved: saved);
  }

  Future<DocumentIndexModel?> indexRow(String sha) =>
      isar.documentIndexModels.filter().sha256EqualTo(sha).findFirst();

  Future<List<DocumentChunkModel>> chunkRows(String sha) =>
      isar.documentChunkModels.where().sha256EqualToAnyOrdinal(sha).findAll();

  group('which documents Shiv may cite', () {
    test(
      'a document on one of the user\'s own feed notes is indexed',
      () async {
        await seedPdf('own', saved: false);
        await ownNote('own');

        await indexer.reconcile();

        expect((await indexRow('own'))?.status, DocumentIndexStatus.indexed);
      },
    );

    test('a document on a saved note is indexed', () async {
      await seedPdf('sv');

      await indexer.reconcile();

      expect((await indexRow('sv'))?.status, DocumentIndexStatus.indexed);
    });

    test(
      'a document opened from someone else\'s feed note is not indexed',
      () async {
        await seedPdf('feed', saved: false);
        await ownNote('feed', author: kAlicePub);

        await indexer.reconcile();

        expect(await indexRow('feed'), isNull);
        expect(source.calls, 0, reason: 'not even extracted');
      },
    );

    test(
      'documents in the user\'s own DMs and group messages are not indexed',
      () async {
        await seedPdf('dm', saved: false);
        await ownNote('dm', kind: kDmFileKind);
        await seedPdf('grp', saved: false);
        await ownNote('grp', kind: kGroupMessageKind);

        await indexer.reconcile();

        expect(await indexRow('dm'), isNull);
        expect(await indexRow('grp'), isNull);
      },
    );

    test(
      'a saved DM or group message is indexed — saving is the opt-in',
      () async {
        await seedPdf('sdm', saved: false);
        await ownNote('sdm', kind: kDmFileKind);
        await save('sdm');

        await indexer.reconcile();

        expect((await indexRow('sdm'))?.status, DocumentIndexStatus.indexed);
      },
    );

    test('unsaving the note removes its document from Shiv', () async {
      await seedPdf('sv');
      await indexer.reconcile();
      expect(await chunkRows('sv'), isNotEmpty);

      await isar.writeTxn(
        () => isar.savedNoteModels.deleteByEventId('saved-sv'),
      );
      await indexer.reconcile();

      expect(await indexRow('sv'), isNull);
      expect(await chunkRows('sv'), isEmpty);
    });

    test('a document on two saved notes survives unsaving one', () async {
      await seedPdf('two');
      await save('two', id: 'saved-two-b');
      await indexer.reconcile();

      await isar.writeTxn(
        () => isar.savedNoteModels.deleteByEventId('saved-two'),
      );
      await indexer.reconcile();

      expect((await indexRow('two'))?.status, DocumentIndexStatus.indexed);
    });

    test('with no signed-in user only saved notes count', () async {
      when(
        () => activeUser.call(),
      ).thenAnswer((_) async => const Left(Failure.notFoundFailure('none')));
      await seedPdf('own', saved: false);
      await ownNote('own');
      await seedPdf('sv');

      await indexer.reconcile();

      expect(await indexRow('own'), isNull);
      expect((await indexRow('sv'))?.status, DocumentIndexStatus.indexed);
    });
  });

  group('images', () {
    Future<void> cacheImage(
      String sha,
      String text, {
      bool saved = true,
    }) async {
      ocr.texts['/p/$sha.jpg'] = text;
      await cacheDoc(
        sha,
        localPath: '/p/$sha.jpg',
        mime: 'image/jpeg',
        saved: saved,
      );
    }

    test(
      'text read in an image on a saved note is indexed, unlabelled',
      () async {
        await cacheImage('img', 'OFFICE ORDER\n\n${prose * 6}');

        await indexer.reconcile();

        final row = await indexRow('img');
        expect(row?.status, DocumentIndexStatus.indexed);
        expect(row?.kind, DocumentKind.image);
        expect((await chunkRows('img')).map((c) => c.label).toSet(), {''});
      },
    );

    test('an image on the user\'s own feed note is indexed', () async {
      await cacheImage('mine', prose * 6, saved: false);
      await ownNote('mine', mime: 'image/png');

      await indexer.reconcile();

      expect((await indexRow('mine'))?.status, DocumentIndexStatus.indexed);
    });

    test('an image in a DM is never read', () async {
      await cacheImage('dm', prose * 6, saved: false);
      await ownNote('dm', mime: 'image/jpeg', kind: kDmFileKind);

      await indexer.reconcile();

      expect(await indexRow('dm'), isNull);
      expect(ocr.calls, 0, reason: 'not even sent to OCR');
    });

    test('a photo with no text is recorded once and never re-read', () async {
      await cacheImage('beach', '');

      await indexer.reconcile();
      await indexer.reconcile();

      expect(
        (await indexRow('beach'))?.status,
        DocumentIndexStatus.notSearchable,
      );
      expect(ocr.calls, 1);
    });

    test('images, PDFs and DOCX index side by side', () async {
      await cacheImage('img', prose * 6);
      await seedPdf('p');
      docx.sections['/p/w.docx'] = [(label: 'A', text: prose * 6)];
      await cacheDoc('w', localPath: '/p/w.docx', mime: DocumentKind.docx.mime);

      await indexer.reconcile();

      for (final sha in ['img', 'p', 'w']) {
        expect(
          (await indexRow(sha))?.status,
          DocumentIndexStatus.indexed,
          reason: sha,
        );
      }
    });
  });

  group('indexing', () {
    test('a new PDF is chunked, embedded and marked indexed', () async {
      await seedPdf('a', pages: [prose * 6, prose * 6]);

      await indexer.reconcile();

      final chunks = await chunkRows('a');
      final row = await indexRow('a');
      expect(row?.status, DocumentIndexStatus.indexed);
      expect(row?.kind, DocumentKind.pdf);
      expect(row?.pageCount, 2);
      expect(row?.chunkCount, chunks.length);
      expect(chunks.map((c) => c.label).toSet(), {'1', '2'});
      expect(stored.keys.toSet(), {for (final c in chunks) 'a:${c.ordinal}'});
      verify(() => embedAndStore.call(any())).called(chunks.length);
    });

    test('a cache row that is not a document is ignored', () async {
      await seedPdf('vid', mime: 'video/mp4');

      await indexer.reconcile();

      expect(await indexRow('vid'), isNull);
      verifyNever(() => embedAndStore.call(any()));
    });

    test('the PDF mime match ignores case and parameters', () async {
      await seedPdf('a', mime: 'Application/PDF; charset=binary');

      await indexer.reconcile();

      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
    });

    test('a DOCX is indexed with its heading labels', () async {
      docx.sections['/p/w.docx'] = [
        (label: '', text: prose * 3),
        (label: 'Annual Leave', text: 'Annual Leave\n\n${prose * 3}'),
      ];
      await cacheDoc('w', localPath: '/p/w.docx', mime: DocumentKind.docx.mime);

      await indexer.reconcile();

      final row = await indexRow('w');
      expect(row?.status, DocumentIndexStatus.indexed);
      expect(row?.kind, DocumentKind.docx);
      expect(row?.pageCount, 0);
      expect((await chunkRows('w')).map((c) => c.label).toList(), [
        '',
        'Annual Leave',
      ]);
    });

    test('a legacy .doc is ignored', () async {
      await seedPdf('old', mime: 'application/msword');

      await indexer.reconcile();

      expect(await indexRow('old'), isNull);
      expect(docx.calls + source.calls, 0);
    });

    test('a PDF and a DOCX in one pass are both indexed', () async {
      await seedPdf('a');
      docx.sections['/p/w.docx'] = [(label: 'A', text: prose * 6)];
      await cacheDoc('w', localPath: '/p/w.docx', mime: DocumentKind.docx.mime);

      await indexer.reconcile();

      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
      expect((await indexRow('w'))?.status, DocumentIndexStatus.indexed);
      expect((await chunkRows('w')).single.label, 'A');
    });

    test('an unreadable DOCX is recorded as not searchable', () async {
      await cacheDoc(
        'bad',
        localPath: '/p/bad.docx',
        mime: DocumentKind.docx.mime,
      );

      await indexer.reconcile();

      final bad = await indexRow('bad');
      expect(bad?.status, DocumentIndexStatus.notSearchable);
      expect(
        bad?.kind,
        DocumentKind.docx,
        reason: 'recorded even when the file cannot be read',
      );
    });

    test('several PDFs are all indexed', () async {
      await seedPdf('a');
      await seedPdf('b');

      await indexer.reconcile();

      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
      expect((await indexRow('b'))?.status, DocumentIndexStatus.indexed);
    });
  });

  group('logging', () {
    late List<String> logs;
    late DebugPrintCallback original;

    setUp(() {
      logs = [];
      original = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
    });
    tearDown(() => debugPrint = original);

    test(
      'logs when a document starts and finishes, with its kind and count',
      () async {
        const sha =
            '62e59f9e6ef0fbbe093099dbf2535cdbcd65668f68398ffb2ade803c58783321';
        docx.sections['/p/$sha.docx'] = [
          (label: 'A', text: prose * 3),
          (label: 'B', text: prose * 3),
        ];
        await cacheDoc(
          sha,
          localPath: '/p/$sha.docx',
          mime: DocumentKind.docx.mime,
        );

        await indexer.reconcile();

        expect(logs, contains('📄 DocumentIndexer: indexing 62e59f9e (docx)…'));
        expect(
          logs.any(
            (l) => RegExp(
              r'^📄 DocumentIndexer: indexed 62e59f9e \(docx\) '
              r'— 2 chunks in \d+s$',
            ).hasMatch(l),
          ),
          isTrue,
          reason: 'got $logs',
        );
      },
    );

    test('logs why a document could not be indexed', () async {
      await seedPdf('scan', pages: ['', '']);

      await indexer.reconcile();

      expect(
        logs.any(
          (l) => RegExp(
            r'^📄 DocumentIndexer: scan \(pdf\) not '
            r'searchable \(noTextLayer\) in \d+s$',
          ).hasMatch(l),
        ),
        isTrue,
        reason: 'got $logs',
      );
    });

    test('a document already indexed logs nothing on the next pass', () async {
      await seedPdf('a');
      await indexer.reconcile();
      logs.clear();

      await indexer.reconcile();

      expect(logs, isEmpty);
    });
  });

  group('not searchable', () {
    test('a scan is recorded once and never re-extracted', () async {
      await seedPdf('scan', pages: ['', '']);

      await indexer.reconcile();
      await indexer.reconcile();

      final row = await indexRow('scan');
      expect(row?.status, DocumentIndexStatus.notSearchable);
      expect(row?.chunkCount, 0);
      expect(await chunkRows('scan'), isEmpty);
      expect(source.calls, 1);
      verifyNever(() => embedAndStore.call(any()));
    });

    test('an unreadable file is recorded as not searchable', () async {
      source.pages['/p/bad.pdf'] = null;
      await cacheDoc('bad', localPath: '/p/bad.pdf', mime: pdf);

      await indexer.reconcile();

      expect(
        (await indexRow('bad'))?.status,
        DocumentIndexStatus.notSearchable,
      );
    });
  });

  group('embedder not ready', () {
    test(
      'a failed embed leaves the document unindexed and retries cleanly',
      () async {
        await seedPdf('a', pages: [prose * 6, prose * 6]);
        var calls = 0;
        when(() => embedAndStore.call(any())).thenAnswer((i) async {
          calls++;
          if (calls > 1) return false; // embedder not ready
          final (id, text) = i.positionalArguments.first as (String, String);
          stored[id] = text;
          return true;
        });

        await indexer.reconcile();

        expect(
          await indexRow('a'),
          isNull,
          reason: 'not marked done — distinct from notSearchable',
        );

        when(() => embedAndStore.call(any())).thenAnswer((i) async {
          final (id, text) = i.positionalArguments.first as (String, String);
          stored[id] = text;
          return true;
        });
        await indexer.reconcile();

        final chunks = await chunkRows('a');
        expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
        expect(
          chunks.length,
          (await indexRow('a'))!.chunkCount,
          reason: 'the partial run left no duplicate rows',
        );
        expect(stored.length, chunks.length);
      },
    );
  });

  group('purge', () {
    test('removing the cache row removes chunks and the index row', () async {
      await seedPdf('a');
      await indexer.reconcile();
      expect(await chunkRows('a'), isNotEmpty);

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256('a'));
      await indexer.reconcile();

      expect(await chunkRows('a'), isEmpty);
      expect(await indexRow('a'), isNull);
    });

    test('purging one document leaves another alone', () async {
      await seedPdf('a');
      await seedPdf('b');
      await indexer.reconcile();

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256('a'));
      await indexer.reconcile();

      expect(await chunkRows('a'), isEmpty);
      expect(await chunkRows('b'), isNotEmpty);
      expect((await indexRow('b'))?.status, DocumentIndexStatus.indexed);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('idempotency and coalescing', () {
    test('a second reconcile does no more work', () async {
      var embeds = 0;
      when(() => embedAndStore.call(any())).thenAnswer((_) async {
        embeds++;
        return true;
      });
      await seedPdf('a');

      await indexer.reconcile();
      final afterFirst = embeds;
      await indexer.reconcile();

      expect(source.calls, 1);
      expect(embeds, afterFirst);
    });

    test('overlapping reconciles extract a document once', () async {
      await seedPdf('a');
      final gate = Completer<void>();
      source.gate = gate.future;

      final first = indexer.reconcile();
      final second = indexer.reconcile();
      gate.complete();
      await Future.wait([first, second]);

      expect(source.calls, 1);
      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
    });

    test('a reconcile with nothing cached is a no-op', () async {
      await indexer.reconcile();

      expect(await isar.documentIndexModels.count(), 0);
      expect(source.calls, 0);
    });
  });

  group('start', () {
    test('indexes a PDF already cached, then one that arrives later', () async {
      Future<void> until(Future<bool> Function() cond) async {
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!await cond()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('timed out waiting for the indexer');
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      await seedPdf('early');
      indexer.start();
      await until(() async => await indexRow('early') != null);

      await seedPdf('late');
      await until(() async => await indexRow('late') != null);

      expect((await indexRow('late'))?.status, DocumentIndexStatus.indexed);
    });

    test('saving a note later indexes a document already cached', () async {
      Future<void> until(Future<bool> Function() cond) async {
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!await cond()) {
          if (DateTime.now().isAfter(deadline)) fail('timed out');
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      await seedPdf('later', saved: false);
      indexer.start();
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(await indexRow('later'), isNull);

      await save('later');

      await until(() async => await indexRow('later') != null);
    });

    test(
      'an own note written after its file was cached gets indexed',
      () async {
        Future<void> until(Future<bool> Function() cond) async {
          final deadline = DateTime.now().add(const Duration(seconds: 10));
          while (!await cond()) {
            if (DateTime.now().isAfter(deadline)) fail('timed out');
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
        }

        // Upload caches the file when it is attached; the note row lands later,
        // when the user publishes.
        await seedPdf('draft', saved: false);
        indexer.start();
        await Future<void>.delayed(const Duration(seconds: 1));

        await ownNote('draft');

        await until(() async => await indexRow('draft') != null);
      },
    );

    test('start twice keeps a single watcher', () async {
      indexer.start();
      indexer.start();
      await indexer.dispose();
    });
  });
}
