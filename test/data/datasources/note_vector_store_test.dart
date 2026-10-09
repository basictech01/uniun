import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';

/// Covers: NoteVectorStore on real tostore in its own isolate — save, search,
/// delete, ordering, reopening, recall at 120 notes, and failing fast once the
/// isolate has stopped. Logout clears all vectors before another account uses it.
void main() {
  late Directory dir;
  late NoteVectorStore store;

  List<double> vec(int seed, {int dim = embeddingsDimensions}) {
    final r = Random(seed);
    final v = [for (var i = 0; i < dim; i++) r.nextDouble() - .5];
    final norm = sqrt(v.fold<double>(0, (a, b) => a + b * b));
    return [for (final x in v) x / norm];
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('note_vector_store_');
    store = await NoteVectorStore.open(dir.path);
  });

  tearDown(() async {
    try {
      await store.close();
    } on StateError {
      // already stopped by the test
    }
    await dir.delete(recursive: true);
  });

  test('a saved vector is found by itself, best first', () async {
    await store.upsert('a', vec(1));
    await store.upsert('b', vec(2));

    final hits = await store.search(vec(1), topK: 5);

    expect(hits.first.id, 'a');
    expect(hits.first.score, greaterThan(0.99));
    expect(hits.map((h) => h.id), containsAll(['a', 'b']));
  });

  test('an empty store answers no hits', () async {
    expect(await store.search(vec(1), topK: 5), isEmpty);
  });

  test('topK limits the number of hits', () async {
    for (var i = 0; i < 10; i++) {
      await store.upsert('n$i', vec(i));
    }

    expect(await store.search(vec(0), topK: 3), hasLength(3));
  });

  test('contains tells saved ids from unknown ones', () async {
    await store.upsert('a', vec(1));

    expect(await store.contains('a'), isTrue);
    expect(await store.contains('nope'), isFalse);
  });

  test('delete removes it from contains and from search', () async {
    await store.upsert('a', vec(1));
    await store.upsert('b', vec(2));

    await store.delete('a');

    expect(await store.contains('a'), isFalse);
    expect((await store.search(vec(1), topK: 5)).map((h) => h.id), ['b']);
  });

  test('clear removes every old-account vector and accepts new ones', () async {
    await store.upsert('account-a-one', vec(1));
    await store.upsert('account-a-two', vec(2));

    await store.clear();

    expect(await store.contains('account-a-one'), isFalse);
    expect(await store.search(vec(1), topK: 5), isEmpty);
    await store.upsert('account-b', vec(3));
    expect((await store.search(vec(3), topK: 5)).single.id, 'account-b');
  });

  test('deleting an id that is not there is not an error', () async {
    await store.delete('ghost');

    expect(await store.contains('ghost'), isFalse);
  });

  test('saving an id again replaces its vector', () async {
    await store.upsert('a', vec(1));
    await store.upsert('b', vec(2));
    await store.upsert('a', vec(3));

    expect((await store.search(vec(3), topK: 1)).single.id, 'a');
    expect(await store.contains('a'), isTrue);
  });

  test('commands run in the order sent: a search right after unawaited saves '
      'sees them', () async {
    final saves = [for (var i = 0; i < 20; i++) store.upsert('n$i', vec(i))];
    final search = store.search(vec(19), topK: 1);

    await Future.wait(saves);

    expect((await search).single.id, 'n19');
  });

  test(
    'ids with unicode, spaces and a 500-character length are kept',
    () async {
      final ids = ['नमस्ते 🌟', 'with space', 'x' * 500, 'ñandú/ß'];
      for (var i = 0; i < ids.length; i++) {
        await store.upsert(ids[i], vec(i));
      }

      for (final id in ids) {
        expect(await store.contains(id), isTrue, reason: id);
      }
    },
  );

  test(
    'vectors saved before close are still searchable after reopening',
    () async {
      await store.upsert('a', vec(1));
      await store.upsert('b', vec(2));
      await store.close();

      store = await NoteVectorStore.open(dir.path);

      expect((await store.search(vec(2), topK: 1)).single.id, 'b');
      expect(await store.contains('a'), isTrue);
    },
  );

  test(
    'a failing command reports a StateError and the store keeps working',
    () async {
      await expectLater(store.upsert('bad', const []), throwsStateError);

      await store.upsert('ok', vec(1));
      expect(await store.contains('ok'), isTrue);
    },
  );

  test('120 notes: each is found by its own vector (the 3.1.2 index found '
      'about 20% of them)', () async {
    for (var i = 0; i < 120; i++) {
      await store.upsert('n$i', vec(i));
    }

    var found = 0;
    for (var i = 0; i < 120; i++) {
      final hits = await store.search(vec(i), topK: 5);
      if (hits.isNotEmpty && hits.first.id == 'n$i') found++;
    }

    expect(found, greaterThanOrEqualTo(118));
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('after the isolate stops', () {
    test('calls after close fail fast instead of hanging', () async {
      await store.close();

      await expectLater(store.contains('a'), throwsStateError);
      await expectLater(store.upsert('a', vec(1)), throwsStateError);
    });

    test('closing twice is rejected, not a hang', () async {
      await store.close();

      await expectLater(store.close(), throwsStateError);
    });

    test('a killed isolate fails waiting and later calls', () async {
      final waiting = store.search(vec(1), topK: 5);
      store.kill();

      await expectLater(waiting, throwsStateError);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await expectLater(store.contains('a'), throwsStateError);
    });
  });

  test('a path that cannot be opened is reported, not a hang', () async {
    await expectLater(
      NoteVectorStore.open('/proc/not/a/writable/place'),
      throwsStateError,
    );
  });
}
