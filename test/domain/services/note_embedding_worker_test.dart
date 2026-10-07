import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/repositories/pending_embedding_repository_impl.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/services/note_embedding_worker.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

import '../../_helpers/isar_test_harness.dart';

class _MockEmbedding extends Mock implements EmbeddingService {}

class _MockVector extends Mock implements VectorRepository {}

class _MockExtract extends Mock implements ExtractKnowledgeUseCase {}

/// [NoteEmbeddingWorker]: drains the pending-embeddings table one note at a
/// time, keeps a row until its vector is stored, and retries what failed.
void main() {
  late Isar isar;
  late PendingEmbeddingRepositoryImpl pending;
  late _MockEmbedding embedding;
  late _MockVector vector;
  late _MockExtract extract;
  late NoteEmbeddingWorker worker;
  late InferenceScheduler scheduler;

  setUpAll(() => registerFallbackValue(('', '', <double>[])));

  setUp(() async {
    isar = await openTestIsar();
    pending = PendingEmbeddingRepositoryImpl(isar: isar);
    embedding = _MockEmbedding();
    vector = _MockVector();
    extract = _MockExtract();
    when(() => vector.upsert(any(), any())).thenAnswer((_) async {});
    when(() => extract.call(any())).thenAnswer((_) async {});
    scheduler = InferenceScheduler();
    worker = NoteEmbeddingWorker(pending, embedding, vector, extract, scheduler);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  /// Lets the unawaited pass run to completion.
  Future<void> settle() async {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void embeds([List<double> vec = const [0.1, 0.2]]) => when(
    () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
  ).thenAnswer((_) async => vec);

  test('an empty table does nothing and never touches the embedder', () async {
    worker.nudge();
    await settle();

    verifyZeroInteractions(embedding);
    verifyZeroInteractions(vector);
  });

  test(
    'embeds a queued note, stores the vector, clears the row and extracts',
    () async {
      embeds();
      await pending.enqueue('n1', 'hello world');

      worker.nudge();
      await settle();

      verify(() => embedding.embed('hello world', isDocument: true)).called(1);
      verify(() => vector.upsert('n1', [0.1, 0.2])).called(1);
      expect(await pending.count(), 0);
      final captured =
          verify(() => extract.call(captureAny())).captured.single
              as (String, String, List<double>);
      // A record's `==` is identity-based for the embedded List: compare fields.
      expect(captured.$1, 'n1');
      expect(captured.$2, 'hello world');
      expect(captured.$3, [0.1, 0.2]);
    },
  );

  test('the vector is stored before the row is removed', () async {
    embeds();
    await pending.enqueue('n1', 'hello world');
    var rowsWhenStoring = -1;
    when(() => vector.upsert(any(), any())).thenAnswer((_) async {
      rowsWhenStoring = await pending.count();
    });

    worker.nudge();
    await settle();

    expect(rowsWhenStoring, 1, reason: 'row must still exist during upsert');
    expect(await pending.count(), 0);
  });

  test('handles the newest note first, then the backlog', () async {
    embeds();
    final order = <String>[];
    when(() => vector.upsert(any(), any())).thenAnswer((i) async {
      order.add(i.positionalArguments.first as String);
    });
    await pending.enqueue('old', 'old note text');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await pending.enqueue('new', 'new note text');

    worker.nudge();
    await settle();

    expect(order, ['new', 'old']);
  });

  test(
    'an embedder that is not ready keeps the row and stops the pass',
    () async {
      when(() => embedding.isReady).thenReturn(false);
      embeds(const []);
      await pending.enqueue('n1', 'one');
      await pending.enqueue('n2', 'two');

      worker.nudge();
      await settle();

      expect(await pending.count(), 2);
      verifyNever(() => vector.upsert(any(), any()));
      verify(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).called(1);
    },
  );

  test(
    'a note queued while a pass is running is picked up by that pass',
    () async {
      final gate = Completer<List<double>>();
      var calls = 0;
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) {
        calls++;
        return calls == 1 ? gate.future : Future.value([0.5]);
      });
      await pending.enqueue('first', 'first note');

      worker.nudge();
      await settle();
      await pending.enqueue('second', 'second note');
      worker.nudge();
      gate.complete([0.1]);
      await settle();

      verify(() => vector.upsert('first', any())).called(1);
      verify(() => vector.upsert('second', any())).called(1);
      expect(await pending.count(), 0);
    },
  );

  test('many nudges never run two embeds at once', () async {
    var inFlight = 0, maxInFlight = 0;
    when(
      () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
    ).thenAnswer((_) async {
      inFlight++;
      if (inFlight > maxInFlight) maxInFlight = inFlight;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      inFlight--;
      return [0.1];
    });
    for (var i = 0; i < 4; i++) {
      await pending.enqueue('n$i', 'note number $i');
    }

    for (var i = 0; i < 10; i++) {
      worker.nudge();
    }
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(maxInFlight, 1);
    expect(await pending.count(), 0);
  });

  test('a failed vector store keeps the row for the next pass', () async {
    embeds();
    when(() => vector.upsert(any(), any())).thenThrow(Exception('disk full'));
    await pending.enqueue('n1', 'hello world');

    worker.nudge();
    await settle();

    expect(await pending.count(), 1);
    verifyNever(() => extract.call(any()));
  });

  test('a note that keeps throwing is dropped after the attempt limit and the '
      'rest go through', () async {
    when(
      () => embedding.embed('bad note', isDocument: true),
    ).thenThrow(Exception('tokenizer exploded'));
    when(
      () => embedding.embed('good note', isDocument: true),
    ).thenAnswer((_) async => [0.3]);
    await pending.enqueue('good', 'good note');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await pending.enqueue('bad', 'bad note'); // newest, so it goes first

    for (var i = 0; i < NoteEmbeddingWorker.maxAttempts; i++) {
      worker.nudge();
      await settle();
    }

    verify(
      () => embedding.embed('bad note', isDocument: true),
    ).called(NoteEmbeddingWorker.maxAttempts);
    verify(() => vector.upsert('good', [0.3])).called(1);
    expect(await pending.count(), 0);
  });

  test('a note queued just as the pass finds the table empty is not '
      'stranded', () async {
    embeds();
    final racing = _InMemoryPending()..rows['a'] = 'first note';
    final w = NoteEmbeddingWorker(racing, embedding, vector, extract, scheduler);
    // The moment the pass sees an empty table, a new note arrives and nudges.
    racing.onEmpty = () {
      racing.onEmpty = null;
      racing.rows['b'] = 'second note';
      w.nudge();
    };

    w.nudge();
    await settle();

    verify(() => vector.upsert('a', any())).called(1);
    verify(() => vector.upsert('b', any())).called(1);
    expect(racing.rows, isEmpty);
  });

  test(
    'a loaded embedder that returns no vector for a note counts as that '
    "note's failure, not as 'not ready'",
    () async {
      when(() => embedding.isReady).thenReturn(true);
      embeds(const []);
      await pending.enqueue('n1', 'one');

      worker.nudge();
      await settle();

      expect(await pending.recordFailure('n1'), 2, reason: 'attempt counted');
      verifyNever(() => vector.upsert(any(), any()));
    },
  );

  test(
    'a note the loaded embedder keeps failing on is dropped and the notes '
    'behind it are embedded',
    () async {
      when(() => embedding.isReady).thenReturn(true);
      when(
        () => embedding.embed('bad', isDocument: true),
      ).thenAnswer((_) async => <double>[]);
      when(
        () => embedding.embed('fine', isDocument: true),
      ).thenAnswer((_) async => [0.5]);
      await pending.enqueue('fine', 'fine');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await pending.enqueue('bad', 'bad'); // newest, so it goes first

      for (var i = 0; i < NoteEmbeddingWorker.maxAttempts; i++) {
        worker.nudge();
        await settle();
      }

      verify(() => vector.upsert('fine', [0.5])).called(1);
      expect(await pending.count(), 0);
    },
  );

  test('the same empty answer from a not-loaded embedder never drops a note',
      () async {
    when(() => embedding.isReady).thenReturn(false);
    embeds(const []);
    await pending.enqueue('n1', 'one');

    for (var i = 0; i < NoteEmbeddingWorker.maxAttempts + 2; i++) {
      worker.nudge();
      await settle();
    }

    expect(await pending.count(), 1);
  });

  test('retries on its own after the retry delay', () {
    // In memory: real Isar I/O never completes under fakeAsync.
    final fake = _InMemoryPending()..rows['n1'] = 'hello world';
    final timed = NoteEmbeddingWorker(fake, embedding, vector, extract, scheduler);
    fakeAsync((async) {
      embeds(const []);
      timed.nudge();
      async.flushMicrotasks();
      verify(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).called(1);
      expect(fake.rows, isNotEmpty);

      embeds();
      async.elapse(NoteEmbeddingWorker.retryDelay);
      async.flushMicrotasks();

      verify(() => vector.upsert('n1', any())).called(1);
      expect(fake.rows, isEmpty);
    });
  });

  test('a queue that cannot be read ends the pass quietly and retries later',
      () {
    final broken = _InMemoryPending()
      ..rows['n1'] = 'hello world'
      ..failNext = true;
    final w = NoteEmbeddingWorker(broken, embedding, vector, extract, scheduler);
    fakeAsync((async) {
      embeds();
      w.nudge();
      async.flushMicrotasks();
      verifyNever(() => vector.upsert(any(), any()));

      broken.failNext = false;
      async.elapse(NoteEmbeddingWorker.retryDelay);
      async.flushMicrotasks();

      verify(() => vector.upsert('n1', any())).called(1);
    });
  });

  group('standing down for a chat reply', () {
    setUp(() => NoteEmbeddingWorker.chatPollInterval =
        const Duration(milliseconds: 10));
    tearDown(() => NoteEmbeddingWorker.chatPollInterval =
        const Duration(seconds: 2));

    /// Starts a scheduled job of [kind] that runs until [gate] completes.
    Future<void> runJob(LlmTaskKind kind, Completer<void> gate) {
      scheduler.notifyLoadedModel('m');
      return scheduler.run<void>(
        kind: kind,
        modelId: 'm',
        work: (_) => gate.future,
      );
    }

    test('does not embed while a chat reply is generating, then does', () async {
      embeds();
      await pending.enqueue('n1', 'hello world');
      final gate = Completer<void>();
      final chat = runJob(LlmTaskKind.chat, gate);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(scheduler.runningKind, LlmTaskKind.chat);

      worker.nudge();
      await settle();
      verifyNever(() => embedding.embed(any(), isDocument: any(named: 'isDocument')));
      expect(await pending.count(), 1);

      gate.complete();
      await chat;
      await settle();

      verify(() => vector.upsert('n1', any())).called(1);
      expect(await pending.count(), 0);
    });

    for (final kind in [
      LlmTaskKind.gana,
      LlmTaskKind.extract,
      LlmTaskKind.nataraj,
    ]) {
      test('keeps embedding while a ${kind.name} job runs', () async {
        embeds();
        await pending.enqueue('n1', 'hello world');
        final gate = Completer<void>();
        final job = runJob(kind, gate);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        worker.nudge();
        await settle();

        verify(() => vector.upsert('n1', any())).called(1);
        gate.complete();
        await job;
      });
    }

    test('picks the queue up again after a chat that ends mid-backlog', () async {
      embeds();
      for (var i = 0; i < 3; i++) {
        await pending.enqueue('n$i', 'note body $i');
      }
      final gate = Completer<void>();
      final chat = runJob(LlmTaskKind.chat, gate);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      worker.nudge();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      gate.complete();
      await chat;
      await settle();

      expect(await pending.count(), 0);
    });
  });
}

class _InMemoryPending implements PendingEmbeddingRepository {
  final Map<String, String> rows = {};

  /// Runs when `next` is asked for a row and there is none.
  void Function()? onEmpty;

  /// Makes the next `next` call throw, like a database that cannot be read.
  bool failNext = false;

  @override
  Future<void> enqueue(String eventId, String text) async =>
      rows[eventId] = text;

  @override
  Future<PendingEmbeddingItem?> next() async {
    if (failNext) throw StateError('database closed');
    if (rows.isEmpty) {
      onEmpty?.call();
      return null;
    }
    return PendingEmbeddingItem(
      eventId: rows.keys.last,
      text: rows[rows.keys.last]!,
    );
  }

  @override
  Future<void> remove(String eventId) async => rows.remove(eventId);

  @override
  Future<int> recordFailure(String eventId) async => 1;

  @override
  Future<int> count() async => rows.length;
}
