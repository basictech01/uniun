@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/pending_embedding_model.dart';
import 'package:uniun/data/models/pending_vector_delete_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/features/shiv/rag/indexing/note_vector_cleanup_worker.dart';

import '../../../../_helpers/isar_seeds.dart';
import '../../../../_helpers/isar_test_harness.dart';

/// Covers: [NoteVectorCleanupWorker] on real Isar and a real vector store —
/// queued deletes, a failing store losing nothing, the launch sweep for
/// vectors with no note, its safety guard, and the one-off index rebuild.
void main() {
  late Isar isar;
  late Directory dir;
  late NoteVectorStore store;
  late AppSettingsStore settings;
  late NoteVectorCleanupWorker worker;

  List<double> vec(int seed) {
    final r = Random(seed);
    final v = [for (var i = 0; i < embeddingsDimensions; i++) r.nextDouble() - .5];
    final n = sqrt(v.fold<double>(0, (a, b) => a + b * b));
    return [for (final x in v) x / n];
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettingsStore(await SharedPreferences.getInstance());
    isar = await openTestIsar();
    dir = await Directory.systemTemp.createTemp('vec_cleanup_');
    store = await NoteVectorStore.open(dir.path);
    worker = NoteVectorCleanupWorker(isar, store, settings);
  });

  tearDown(() async {
    await worker.stop();
    try {
      await store.close();
    } on StateError {
      // closed by the test
    }
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  Future<void> queue(List<String> ids) => isar.writeTxn(
    () => isar.pendingVectorDeleteModels.putAll([
      for (final id in ids)
        PendingVectorDeleteModel()
          ..eventId = id
          ..createdAt = DateTime(2026),
    ]),
  );

  Future<int> queued() => isar.pendingVectorDeleteModels.where().count();

  group('queue', () {
    test('deletes the vector and then the row', () async {
      await store.upsert('a', vec(1));
      await store.upsert('b', vec(2));
      await queue(['a']);

      await worker.drain();

      expect(await store.ids(), {'b'});
      expect(await queued(), 0);
    });

    test('a queued note loses every piece of its vector', () async {
      await store.upsertNote('long', [vec(1), vec(2), vec(3)]);
      await store.upsert('keep', vec(9));
      await queue(['long']);

      await worker.drain();

      expect(await store.ids(), {'keep'});
      expect(await queued(), 0);
    });

    test('an id that has no vector is still cleared from the queue', () async {
      await queue(['never-stored']);

      await worker.drain();

      expect(await queued(), 0);
    });

    test('a store that has stopped keeps every row for the next pass',
        () async {
      await store.upsert('a', vec(1));
      await queue(['a', 'b']);
      await store.close();

      await expectLater(worker.drain(), completes);

      expect(await queued(), 2);
    });

    test('more rows than one batch are all processed', () async {
      final ids = [for (var i = 0; i < 230; i++) 'n$i'];
      await queue(ids);

      await worker.drain();

      expect(await queued(), 0);
    });

    test('start reacts to a row added later', () async {
      await store.upsert('late', vec(3));
      worker.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      await queue(['late']);
      await worker.idle();

      expect(await store.contains('late'), isFalse);
      expect(await queued(), 0);
    });
  });

  group('launch sweep', () {
    test('removes vectors that have no note, keeps live ones', () async {
      await seedNoteRow(isar, 'note');
      await isar.writeTxn(
        () => isar.savedNoteModels.put(savedNoteRow('saved')),
      );
      await isar.writeTxn(
        () => isar.pendingEmbeddingModels.put(
          PendingEmbeddingModel()
            ..eventId = 'waiting'
            ..text = 't'
            ..createdAt = DateTime(2026),
        ),
      );
      for (final (i, id) in ['note', 'saved', 'waiting', 'orphan-1', 'orphan-2']
          .indexed) {
        await store.upsert(id, vec(10 + i));
      }

      final removed = await worker.sweepOrphans();

      expect(removed, 2);
      expect(await store.ids(), {'note', 'saved', 'waiting'});
    });

    test('keeps every piece of a live note and removes all pieces of a gone '
        'one (#296)', () async {
      await seedNoteRow(isar, 'live');
      await store.upsertNote('live', [vec(1), vec(2), vec(3)]);
      await store.upsertNote('gone', [vec(4), vec(5)]);

      final removed = await worker.sweepOrphans();

      expect(removed, 1, reason: 'one note, however many pieces');
      expect(await store.ids(), {'live', 'live#1', 'live#2'});
    });

    test('a removed saved row does not keep its vector alive', () async {
      await seedNoteRow(isar, 'other');
      await isar.writeTxn(
        () => isar.savedNoteModels.put(
          savedNoteRow('unsaved')..removedAt = DateTime(2026),
        ),
      );
      await store.upsert('other', vec(1));
      await store.upsert('unsaved', vec(2));

      await worker.sweepOrphans();

      expect(await store.ids(), {'other'});
    });

    test('with no notes at all it deletes nothing', () async {
      await store.upsert('a', vec(1));
      await store.upsert('b', vec(2));

      final removed = await worker.sweepOrphans();

      expect(removed, 0);
      expect(await store.ids(), {'a', 'b'});
    });

    test('an empty store is a no-op', () async {
      await seedNoteRow(isar, 'note');

      expect(await worker.sweepOrphans(), 0);
    });
  });

  group('index rebuild', () {
    test('runs once per store format and is remembered', () async {
      await seedNoteRow(isar, 'a');
      await store.upsert('a', vec(1));
      expect(settings.noteVectorIndexRebuiltFormat, isNull);

      await worker.rebuildIndexOnce();
      expect(settings.noteVectorIndexRebuiltFormat, kNoteVectorStoreFormat);

      // Closed store: a second call must not even try, so it must not throw.
      await store.close();
      await expectLater(worker.rebuildIndexOnce(), completes);
    });

    test('a failing rebuild is not remembered, so it is tried again',
        () async {
      await store.close();

      await worker.rebuildIndexOnce();

      expect(settings.noteVectorIndexRebuiltFormat, isNull);
    });
  });

  test('a store that fails during the launch pass is retried, not fatal',
      () async {
    await store.close();

    worker.start();
    await worker.idle();

    expect(await queued(), 0);
  });

  test('run does the queue, the sweep and the rebuild in that order',
      () async {
    await seedNoteRow(isar, 'live');
    await store.upsert('live', vec(1));
    await store.upsert('queued', vec(2));
    await store.upsert('orphan', vec(3));
    await queue(['queued']);

    await worker.run();

    expect(await store.ids(), {'live'});
    expect(await queued(), 0);
    expect(settings.noteVectorIndexRebuiltFormat, kNoteVectorStoreFormat);
  });
}
