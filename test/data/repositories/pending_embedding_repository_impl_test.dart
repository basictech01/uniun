import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/pending_embedding_model.dart';
import 'package:uniun/data/repositories/pending_embedding_repository_impl.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';

import '../../_helpers/isar_test_harness.dart';

/// Covers: PendingEmbeddingRepositoryImpl on real Isar — queueing, newest-first
/// reads, removal, failure counting, and Left on a closed database.
void main() {
  late Isar isar;
  late PendingEmbeddingRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    repo = PendingEmbeddingRepositoryImpl(isar: isar);
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close(deleteFromDisk: true);
  });

  Future<PendingEmbeddingItem?> next() async =>
      (await repo.next()).getOrElse(() => null);
  Future<int> count() async => (await repo.count()).getOrElse(() => -1);

  test('an empty table has no next row and a zero count', () async {
    expect(await next(), isNull);
    expect(await count(), 0);
  });

  test('enqueue then next returns the text to embed', () async {
    expect((await repo.enqueue('n1', 'hello world')).isRight(), isTrue);

    final item = await next();

    expect((item!.eventId, item.text), ('n1', 'hello world'));
  });

  test('enqueueing a note twice keeps one row with the newest text', () async {
    await repo.enqueue('n1', 'first');
    await repo.enqueue('n1', 'second');

    expect(await count(), 1);
    expect((await next())!.text, 'second');
  });

  test('re-queueing a note resets its failed attempts', () async {
    await repo.enqueue('n1', 'text');
    await repo.recordFailure('n1');
    await repo.recordFailure('n1');

    await repo.enqueue('n1', 'text');

    expect((await repo.recordFailure('n1')).getOrElse(() => -1), 1);
  });

  test('next returns the newest row first', () async {
    await repo.enqueue('old', 'old text');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.enqueue('new', 'new text');

    expect((await next())!.eventId, 'new');
  });

  test('remove deletes only that note', () async {
    await repo.enqueue('a', 'aaaa');
    await repo.enqueue('b', 'bbbb');

    expect((await repo.remove('a')).isRight(), isTrue);

    expect(await count(), 1);
    expect((await next())!.eventId, 'b');
  });

  test('removing a note that is not queued is not an error', () async {
    expect((await repo.remove('ghost')).isRight(), isTrue);
    expect(await count(), 0);
  });

  test('recordFailure counts up and reports the total', () async {
    await repo.enqueue('n1', 'text');

    expect((await repo.recordFailure('n1')).getOrElse(() => -1), 1);
    expect((await repo.recordFailure('n1')).getOrElse(() => -1), 2);
    final row = await isar.pendingEmbeddingModels.where().findFirst();
    expect(row!.attempts, 2);
  });

  test('recordFailure for a note that is gone returns 0', () async {
    expect((await repo.recordFailure('ghost')).getOrElse(() => -1), 0);
  });

  test('keeps long and unicode text unchanged', () async {
    final text = 'नमस्ते 🌟 ${'x' * 5000}';
    await repo.enqueue('n1', text);

    expect((await next())!.text, text);
  });

  test('every method answers Left, not an exception, on a closed database',
      () async {
    await isar.close();

    expect((await repo.enqueue('n1', 'text')).isLeft(), isTrue);
    expect((await repo.next()).isLeft(), isTrue);
    expect((await repo.remove('n1')).isLeft(), isTrue);
    expect((await repo.recordFailure('n1')).isLeft(), isTrue);
    expect((await repo.count()).isLeft(), isTrue);
    await Isar.getInstance(isar.name)?.close(deleteFromDisk: true);
  });
}
