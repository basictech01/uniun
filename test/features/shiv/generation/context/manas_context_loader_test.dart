import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/data/models/manas_note_link_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';

import '../../../../_helpers/isar_test_harness.dart';

class _MockEmbedder extends Mock implements EmbeddingService {}

class _MockSearcher extends Mock implements VectorSearchService {}

NoteModel _ownNote(String id, String content, DateTime created,
        {String author = 'self'}) =>
    NoteModel(
      eventId: id,
      sig: 'sig',
      authorPubkey: author,
      content: content,
      type: NoteType.text,
      eTagRefs: const [],
      pTagRefs: const [],
      tTags: const [],
      created: created,
    );

SavedNoteModel _savedNote(String id, String content, DateTime created,
        {DateTime? removedAt}) =>
    SavedNoteModel()
      ..eventId = id
      ..sig = 'sig'
      ..authorPubkey = 'someone'
      ..content = content
      ..type = NoteType.text
      ..eTagRefs = const []
      ..pTagRefs = const []
      ..tTags = const []
      ..created = created
      ..savedAt = created
      ..removedAt = removedAt;

DraftModel _draft(String id, String content, DateTime at) => DraftModel()
  ..draftId = id
  ..content = content
  ..eTagRefs = const []
  ..pTagRefs = const []
  ..tTags = const []
  ..createdAt = at
  ..updatedAt = at;

ManasNoteLinkModel _link(String manasId, String noteId, DateTime addedAt,
        {DateTime? removedAt}) =>
    ManasNoteLinkModel()
      ..manasId = manasId
      ..noteId = noteId
      ..addedAt = addedAt
      ..removedAt = removedAt;

void main() {
  late Isar isar;
  late _MockEmbedder embedder;
  late _MockSearcher searcher;
  late ManasContextLoader loader;

  setUpAll(() {
    registerFallbackValue(<double>[]);
  });

  setUp(() async {
    isar = await openTestIsar();
    embedder = _MockEmbedder();
    searcher = _MockSearcher();
    loader = ManasContextLoader(isar, embedder, searcher);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('merge — newest-first (no relevanceQuery)', () {
    test('empty manasIds or non-positive budget short-circuits to empty',
        () async {
      expect(await loader.merge(manasIds: const [], budget: 100),
          isEmpty);
      expect(await loader.merge(manasIds: const ['m1'], budget: 0),
          isEmpty);
      expect(await loader.merge(manasIds: const ['m1'], budget: -5),
          isEmpty);
    });

    test('no notes linked to the requested Manas — empty result', () async {
      final result = await loader.merge(manasIds: const ['m1'], budget: 100);
      expect(result, isEmpty);
    });

    test('resolves linked notes newest-first, deduped across Manas overlap',
        () async {
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 1, 2);
      await isar.writeTxn(() async {
        await isar.noteModels.putAll([
          _ownNote('n1', 'first', t1),
          _ownNote('n2', 'second', t2),
        ]);
        await isar.manasNoteLinkModels.putAll([
          _link('m1', 'n1', t1),
          _link('m1', 'n2', t1),
          _link('m2', 'n1', t1), // same note, second Manas — must dedupe
        ]);
      });

      final result =
          await loader.merge(manasIds: const ['m1', 'm2'], budget: 1000);

      expect(result.map((n) => n.id), ['n2', 'n1']); // newest first
    });

    test('skips a tombstoned (removedAt set) link', () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.put(_ownNote('n1', 'gone', t1));
        await isar.manasNoteLinkModels
            .put(_link('m1', 'n1', t1, removedAt: t1));
      });

      final result = await loader.merge(manasIds: const ['m1'], budget: 1000);

      expect(result, isEmpty);
    });

    test('a saved note takes precedence over an own note with the same id',
        () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.put(_ownNote('n1', 'own version', t1));
        await isar.savedNoteModels.put(_savedNote('n1', 'saved version', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
      });

      final result = await loader.merge(manasIds: const ['m1'], budget: 1000);

      expect(result.single.content, 'saved version');
      expect(result.single.source, PackedNoteSource.saved);
    });

    test('skips oversize notes rather than truncating them', () async {
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 1, 2);
      final big = 'x' * 5000; // exceeds a small budget on its own
      await isar.writeTxn(() async {
        await isar.noteModels.putAll([
          _ownNote('big', big, t2), // newest, picked first, consumes budget
          _ownNote('small', 'fits', t1),
        ]);
        await isar.manasNoteLinkModels.putAll([
          _link('m1', 'big', t1),
          _link('m1', 'small', t1),
        ]);
      });

      // budget in tokens; charBudget = budget*4*0.85. Small enough that the
      // big note alone blows it, but the small one alone fits.
      final result = await loader.merge(manasIds: const ['m1'], budget: 100);

      expect(result.map((n) => n.id), ['small']);
    });
  });

  group('merge — relevance-ranked', () {
    test('embeds the query, filters vector hits to the Manas set, and '
        'orders by search score', () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.putAll([
          _ownNote('n1', 'about cats', t1),
          _ownNote('n2', 'about dogs', t1),
          _ownNote('n3', 'not in any manas', t1),
        ]);
        await isar.manasNoteLinkModels.putAll([
          _link('m1', 'n1', t1),
          _link('m1', 'n2', t1),
          _link('m1', 'n3', t1),
        ]);
      });
      when(() => embedder.embed(any())).thenAnswer((_) async => [1.0, 0.0]);
      when(() => searcher.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
            minScore: any(named: 'minScore'),
          )).thenAnswer((_) async => const [
            ScoredNote(noteId: 'n2', score: 0.9, content: 'about dogs'),
            ScoredNote(noteId: 'n1', score: 0.5, content: 'about cats'),
            ScoredNote(noteId: 'n9', score: 0.99, content: 'outside manas'),
          ]);

      final result = await loader.merge(
        manasIds: const ['m1'],
        budget: 1000,
        relevanceQuery: 'pets',
      );

      // n9 excluded (not in the Manas set); n3 excluded (no vector hit at
      // all); n2 before n1 (higher score, search order preserved).
      expect(result.map((n) => n.id), ['n2', 'n1']);
    });

    test('a blank/whitespace-only relevanceQuery is treated as none — '
        'falls back to newest-first without touching the embedder',
        () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.put(_ownNote('n1', 'x', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
      });

      final result = await loader.merge(
        manasIds: const ['m1'],
        budget: 1000,
        relevanceQuery: '   ',
      );

      expect(result.single.id, 'n1');
      verifyNever(() => embedder.embed(any()));
    });

    test('embedder returns an empty vector — falls back to newest-first',
        () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.put(_ownNote('n1', 'x', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
      });
      when(() => embedder.embed(any())).thenAnswer((_) async => <double>[]);

      final result = await loader.merge(
        manasIds: const ['m1'],
        budget: 1000,
        relevanceQuery: 'q',
      );

      expect(result.single.id, 'n1');
      verifyNever(() => searcher.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
            minScore: any(named: 'minScore'),
          ));
    });

    test('no vector hits fall inside the Manas set — falls back to '
        'newest-first', () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.put(_ownNote('n1', 'x', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
      });
      when(() => embedder.embed(any())).thenAnswer((_) async => [1.0]);
      when(() => searcher.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
            minScore: any(named: 'minScore'),
          )).thenAnswer((_) async => const [
            ScoredNote(noteId: 'outside', score: 0.9, content: 'nope'),
          ]);

      final result = await loader.merge(
        manasIds: const ['m1'],
        budget: 1000,
        relevanceQuery: 'q',
      );

      expect(result.single.id, 'n1');
    });

    test('embedder throws — degrades to newest-first, not an uncaught error',
        () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.put(_ownNote('n1', 'x', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
      });
      when(() => embedder.embed(any()))
          .thenThrow(Exception('embedder not ready'));

      final result = await loader.merge(
        manasIds: const ['m1'],
        budget: 1000,
        relevanceQuery: 'q',
      );

      expect(result.single.id, 'n1');
    });
  });

  group('searchAll', () {
    test('an empty/whitespace query returns empty without touching the '
        'embedder', () async {
      expect(await loader.searchAll(query: '  '), isEmpty);
      verifyNever(() => embedder.embed(any()));
    });

    test('embeds the query and maps every hit to a PackedNote (own source)',
        () async {
      when(() => embedder.embed(any())).thenAnswer((_) async => [1.0]);
      when(() => searcher.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
          )).thenAnswer((_) async => const [
            ScoredNote(noteId: 'n1', score: 0.9, content: 'hit one'),
            ScoredNote(noteId: 'n2', score: 0.5, content: 'hit two'),
          ]);

      final result = await loader.searchAll(query: 'q', topK: 3);

      expect(result.map((n) => n.id), ['n1', 'n2']);
      expect(result.every((n) => n.source == PackedNoteSource.own), isTrue);
      verify(() => searcher.search(
            queryVector: [1.0],
            topK: 3,
          )).called(1);
    });

    test('embedder returns empty vector — empty result, searcher never '
        'called', () async {
      when(() => embedder.embed(any())).thenAnswer((_) async => <double>[]);

      final result = await loader.searchAll(query: 'q');

      expect(result, isEmpty);
      verifyNever(() => searcher.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
          ));
    });

    test('a searcher failure degrades to an empty list, not a throw',
        () async {
      when(() => embedder.embed(any())).thenAnswer((_) async => [1.0]);
      when(() => searcher.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
          )).thenThrow(Exception('index unavailable'));

      final result = await loader.searchAll(query: 'q');

      expect(result, isEmpty);
    });
  });

  test('mergeAll ranks Brahma notes against input and excludes unrelated peers',
      () async {
    final at = DateTime(2026);
    await isar.writeTxn(() async {
      await isar.savedNoteModels.put(_savedNote('saved', 'saved insight', at));
      await isar.noteModels.put(_ownNote('own', 'own insight', at));
      await isar.noteModels.put(
          _ownNote('peer', 'unrelated peer', at, author: 'other'));
    });
    when(() => embedder.embed('input')).thenAnswer((_) async => [1.0, 0.0]);
    when(() => searcher.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
          minScore: any(named: 'minScore'),
        )).thenAnswer((_) async => const [
          ScoredNote(noteId: 'peer', score: 0.99, content: 'unrelated peer'),
          ScoredNote(noteId: 'saved', score: 0.8, content: 'saved insight'),
          ScoredNote(noteId: 'own', score: 0.6, content: 'own insight'),
        ]);

    final result = await loader.mergeAll(
        selfPubkey: 'self', budget: 100, relevanceQuery: 'input');

    expect(result.map((n) => n.id), ['saved', 'own']);
  });

  group('static packNewest / loadPool / loadAll (background-isolate-safe)',
      () {
    test(
      'Brahma scope packs saved, own, draft and linked notes once, newest first',
      () async {
        final old = DateTime(2026, 1, 1);
        final recent = DateTime(2026, 1, 2);
        await isar.writeTxn(() async {
          await isar.savedNoteModels.put(_savedNote('saved', 'saved', old));
          await isar.noteModels.put(_ownNote('own', 'own', recent));
          await isar.noteModels.put(
            _ownNote('linked', 'linked', old, author: 'other'),
          );
          await isar.draftModels.put(_draft('draft', 'draft', old));
          await isar.manasNoteLinkModels.put(_link('m1', 'linked', old));
          await isar.manasNoteLinkModels.put(_link('m2', 'own', old));
        });

        final foreground = await loader.mergeAll(
          selfPubkey: 'self',
          budget: 100,
        );
        final background = await ManasContextLoader.packAllNewest(
          isar: isar,
          selfPubkey: 'self',
          budget: 100,
        );
        expect(foreground.map((n) => n.id), background.map((n) => n.id));
        expect(foreground.first.id, 'own');
        expect(foreground.map((n) => n.id).toSet(), {
          'saved',
          'own',
          'linked',
          'draft',
        });
        expect(foreground, hasLength(4));
      },
    );

    test(
      'Brahma scope skips oversize notes and rejects nonpositive budgets',
      () async {
        final at = DateTime(2026);
        await isar.writeTxn(() async {
          await isar.noteModels.put(_ownNote('large', 'x' * 500, at));
          await isar.noteModels.put(_ownNote('small', 'small', at));
        });
        expect(
          (await loader.mergeAll(
            selfPubkey: 'self',
            budget: 10,
          )).map((n) => n.id),
          ['small'],
        );
        expect(await loader.mergeAll(selfPubkey: 'self', budget: 0), isEmpty);
        expect(
          await ManasContextLoader.packAllNewest(
            isar: isar,
            selfPubkey: 'self',
            budget: -1,
          ),
          isEmpty,
        );
      },
    );
    test('packNewest mirrors merge\'s newest-first behavior with a plain '
        'Isar handle', () async {
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 1, 2);
      await isar.writeTxn(() async {
        await isar.noteModels.putAll([
          _ownNote('n1', 'old', t1),
          _ownNote('n2', 'new', t2),
        ]);
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n2', t1));
      });

      final result = await ManasContextLoader.packNewest(
        isar: isar,
        manasIds: const ['m1'],
        budget: 1000,
      );

      expect(result.map((n) => n.id), ['n2', 'n1']);
    });

    test('packNewest short-circuits on empty manasIds or non-positive budget',
        () async {
      expect(
          await ManasContextLoader.packNewest(
              isar: isar, manasIds: const [], budget: 100),
          isEmpty);
      expect(
          await ManasContextLoader.packNewest(
              isar: isar, manasIds: const ['m1'], budget: 0),
          isEmpty);
    });

    test('loadPool returns the full unranked union with no budget cap',
        () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels.putAll([
          _ownNote('n1', 'x' * 10000, t1),
          _ownNote('n2', 'y', t1),
        ]);
        await isar.manasNoteLinkModels.put(_link('m1', 'n1', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'n2', t1));
      });

      final result =
          await ManasContextLoader.loadPool(isar: isar, manasIds: const ['m1']);

      expect(result.map((n) => n.id).toSet(), {'n1', 'n2'});
    });

    test('loadPool resolves a Manas-linked DRAFT via the draft fallback '
        'in _resolveMany (not saved, not a real note)', () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.draftModels.put(_draft('draft1', 'linked draft', t1));
        await isar.manasNoteLinkModels.put(_link('m1', 'draft1', t1));
      });

      final result = await ManasContextLoader.loadPool(
          isar: isar, manasIds: const ['m1']);

      expect(result.single.id, 'draft1');
      expect(result.single.source, PackedNoteSource.draft);
    });

    test('loadPool on Manas with no notes is empty', () async {
      final result = await ManasContextLoader.loadPool(
          isar: isar, manasIds: const ['m1']);
      expect(result, isEmpty);
    });

    test('loadAll unions saved (not tombstoned) + own + drafts + every '
        'Manas-linked note, deduped by id', () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.savedNoteModels.putAll([
          _savedNote('saved1', 'a saved note', t1),
          _savedNote('saved2', 'tombstoned', t1, removedAt: t1),
        ]);
        await isar.noteModels.put(_ownNote('own1', 'my note', t1));
        await isar.noteModels.put(
            _ownNote('other1', 'someone else\'s note', t1, author: 'bob'));
        await isar.draftModels.put(_draft('draft1', 'a draft', t1));
        // manas-linked note that isn't otherwise saved/own — must still
        // surface so per-Manas scopes stay a true subset of "All notes".
        await isar.manasNoteLinkModels.put(_link('m1', 'other1', t1));
      });

      final result =
          await ManasContextLoader.loadAll(isar: isar, selfPubkey: 'self');

      final ids = result.map((n) => n.id).toSet();
      expect(ids, {'saved1', 'own1', 'draft1', 'other1'});
      expect(ids.contains('saved2'), isFalse, reason: 'tombstoned saved note');
    });

    test('loadAll excludes a tombstoned (removedAt set) Manas link',
        () async {
      final t1 = DateTime(2026, 1, 1);
      await isar.writeTxn(() async {
        await isar.noteModels
            .put(_ownNote('other1', 'not mine', t1, author: 'bob'));
        await isar.manasNoteLinkModels
            .put(_link('m1', 'other1', t1, removedAt: t1));
      });

      final result =
          await ManasContextLoader.loadAll(isar: isar, selfPubkey: 'self');

      expect(result, isEmpty);
    });

    test('loadAll on an empty database returns an empty list', () async {
      final result =
          await ManasContextLoader.loadAll(isar: isar, selfPubkey: 'self');
      expect(result, isEmpty);
    });
  });
}
