import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/pending_embedding_model.dart';
import 'package:uniun/data/repositories/pending_embedding_repository_impl.dart';

import '../../_helpers/isar_test_harness.dart';

/// [PendingEmbeddingRepositoryImpl] against real Isar: the table of notes that
/// still need a vector.
void main() {
  late Isar isar;
  late PendingEmbeddingRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    repo = PendingEmbeddingRepositoryImpl(isar: isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('an empty table has no next row and a zero count', () async {
    expect(await repo.next(), isNull);
    expect(await repo.count(), 0);
  });

  test('enqueue then next returns the text to embed', () async {
    await repo.enqueue('n1', 'hello world');

    final item = await repo.next();

    expect((item!.eventId, item.text), ('n1', 'hello world'));
  });

  test('enqueueing a note twice keeps one row with the newest text', () async {
    await repo.enqueue('n1', 'first');
    await repo.enqueue('n1', 'second');

    expect(await repo.count(), 1);
    expect((await repo.next())!.text, 'second');
  });

  test('re-queueing a note resets its failed attempts', () async {
    await repo.enqueue('n1', 'text');
    await repo.recordFailure('n1');
    await repo.recordFailure('n1');

    await repo.enqueue('n1', 'text');

    expect(await repo.recordFailure('n1'), 1);
  });

  test('next returns the newest row first', () async {
    await repo.enqueue('old', 'old text');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.enqueue('new', 'new text');

    expect((await repo.next())!.eventId, 'new');
  });

  test('remove deletes only that note', () async {
    await repo.enqueue('a', 'aaaa');
    await repo.enqueue('b', 'bbbb');

    await repo.remove('a');

    expect(await repo.count(), 1);
    expect((await repo.next())!.eventId, 'b');
  });

  test('removing a note that is not queued does nothing', () async {
    await repo.remove('ghost');

    expect(await repo.count(), 0);
  });

  test('recordFailure counts up and reports the total', () async {
    await repo.enqueue('n1', 'text');

    expect(await repo.recordFailure('n1'), 1);
    expect(await repo.recordFailure('n1'), 2);
    final row = await isar.pendingEmbeddingModels.where().findFirst();
    expect(row!.attempts, 2);
  });

  test('recordFailure for a note that is gone returns 0', () async {
    expect(await repo.recordFailure('ghost'), 0);
  });

  test('keeps long and unicode text unchanged', () async {
    final text = 'नमस्ते 🌟 ${'x' * 5000}';
    await repo.enqueue('n1', text);

    expect((await repo.next())!.text, text);
  });
}
