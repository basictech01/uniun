import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/repositories/tostore_vector_repository_impl.dart';

import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: TostoreVectorRepositoryImpl on the real isolate-owned store and real
/// Isar — saving, deleting, and searching with each hit's text resolved from
/// the saved and own note tables.
void main() {
  late Isar isar;
  late Directory dir;
  late NoteVectorStore store;
  late TostoreVectorRepositoryImpl repo;

  List<double> vec(int seed) {
    final r = Random(seed);
    final v = [
      for (var i = 0; i < embeddingsDimensions; i++) r.nextDouble() - .5,
    ];
    final norm = sqrt(v.fold<double>(0, (a, b) => a + b * b));
    return [for (final x in v) x / norm];
  }

  setUp(() async {
    isar = await openTestIsar();
    dir = await Directory.systemTemp.createTemp('tostore_repo_');
    store = await NoteVectorStore.open(dir.path);
    repo = TostoreVectorRepositoryImpl(store, isar);
  });

  tearDown(() async {
    await store.close();
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  Future<void> saveNote(String id, String content) => isar.writeTxn(
    () => isar.savedNoteModels.put(savedNoteRow(id, content: content)),
  );
  Future<void> ownNote(String id, String content) =>
      isar.writeTxn(() => isar.noteModels.put(noteRow(id, content: content)));

  test('a saved note comes back with its text and a high score', () async {
    await saveNote('a', 'small habits compound');
    await repo.upsertNote('a', [vec(1)]);

    final hits = await repo.search(vec(1), topK: 5);

    expect(hits.single.noteId, 'a');
    expect(hits.single.content, 'small habits compound');
    expect(hits.single.score, greaterThan(0.99));
  });

  test('an own (not saved) note is found too', () async {
    await ownNote('mine', 'my own note text');
    await repo.upsertNote('mine', [vec(1)]);

    expect(
      (await repo.search(vec(1), topK: 5)).single.content,
      'my own note text',
    );
  });

  test('a note that is both saved and own uses the saved copy', () async {
    await saveNote('both', 'saved text');
    await ownNote('both', 'own text');
    await repo.upsertNote('both', [vec(1)]);

    expect((await repo.search(vec(1), topK: 5)).single.content, 'saved text');
  });

  test(
    'a vector whose note is gone from Isar is left out of the results',
    () async {
      await saveNote('kept', 'still here');
      await repo.upsertNote('kept', [vec(1)]);
      await repo.upsertNote('orphan', [vec(2)]);

      final hits = await repo.search(vec(1), topK: 5);

      expect(hits.map((h) => h.noteId), ['kept']);
    },
  );

  test('hits below minScore are dropped', () async {
    await saveNote('a', 'one');
    await saveNote('b', 'two');
    await repo.upsertNote('a', [vec(1)]);
    await repo.upsertNote('b', [vec(2)]);

    final strict = await repo.search(vec(1), topK: 5, minScore: 0.999);

    expect(strict.map((h) => h.noteId), ['a']);
  });

  test('an empty query or an empty vector does nothing', () async {
    await saveNote('a', 'one');

    await repo.upsertNote('a', [const []]);

    expect(await store.contains('a'), isFalse);
    expect(await repo.search(const [], topK: 5), isEmpty);
  });

  test('delete removes the vector from search', () async {
    await saveNote('a', 'one');
    await saveNote('b', 'two');
    await repo.upsertNote('a', [vec(1)]);
    await repo.upsertNote('b', [vec(2)]);

    await repo.delete('a');

    final hits = await repo.search(vec(1), topK: 5, minScore: 0);

    expect(hits.map((h) => h.noteId), ['b']);
  });

  test('a removed saved note (removedAt set) is not returned from the saved '
      'table', () async {
    await isar.writeTxn(
      () => isar.savedNoteModels.put(
        savedNoteRow('gone', content: 'unsaved')..removedAt = DateTime(2026),
      ),
    );
    await repo.upsertNote('gone', [vec(1)]);

    expect(await repo.search(vec(1), topK: 5), isEmpty);
  });

  test('unicode text is returned unchanged', () async {
    await saveNote('hi', 'नमस्ते दुनिया 🌟');
    await repo.upsertNote('hi', [vec(1)]);

    expect(
      (await repo.search(vec(1), topK: 5)).single.content,
      'नमस्ते दुनिया 🌟',
    );
  });

  group('notes in pieces (#296)', () {
    test('a note with several close pieces is returned once, with its best '
        'score', () async {
      await ownNote('long', 'a long note');
      await ownNote('short', 'a short note');
      await repo.upsertNote('long', [vec(1), vec(2), vec(3)]);
      await repo.upsertNote('short', [vec(4)]);

      final hits = await repo.search(vec(2), topK: 5, minScore: 0);

      expect(hits.where((h) => h.noteId == 'long'), hasLength(1));
      expect(hits.first.noteId, 'long');
      expect(hits.first.score, greaterThan(0.99));
    });

    test('one note cannot crowd the others out of topK', () async {
      await ownNote('long', 'long');
      await ownNote('b', 'b');
      await ownNote('c', 'c');
      // The long note's pieces are the three nearest, the others come after.
      await repo.upsertNote('long', [vec(1), vec(1), vec(1)]);
      await repo.upsertNote('b', [vec(2)]);
      await repo.upsertNote('c', [vec(3)]);

      final hits = await repo.search(vec(1), topK: 3, minScore: -1);

      expect(hits.map((h) => h.noteId).toSet(), {'long', 'b', 'c'});
    });

    test('deleting a note deletes all of its pieces', () async {
      await ownNote('long', 'long');
      await repo.upsertNote('long', [vec(1), vec(2)]);

      await repo.delete('long');

      expect(await repo.search(vec(2), topK: 5, minScore: -1), isEmpty);
      expect(await store.ids(), isEmpty);
    });

    test('a scoped search finds a long note through any of its pieces',
        () async {
      await ownNote('long', 'long');
      await ownNote('other', 'other');
      await repo.upsertNote('long', [vec(1), vec(2)]);
      await repo.upsertNote('other', [vec(2)]);

      final hits = await repo.search(
        vec(2),
        topK: 5,
        minScore: 0,
        allowedNoteIds: {'long'},
      );

      expect(hits.single.noteId, 'long');
      expect(hits.single.score, greaterThan(0.99));
    });

    test('empty vectors among the pieces are ignored; all empty stores nothing',
        () async {
      await repo.upsertNote('a', [const [], vec(1)]);
      await repo.upsertNote('b', [const []]);

      expect(await store.ids(), {'a'});
    });
  });

  test('a store that has stopped makes search throw, not hang', () async {
    await store.close();

    await expectLater(repo.search(vec(1), topK: 5), throwsStateError);
    store = await NoteVectorStore.open(dir.path);
  });
}
