import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

class _MockVectorRepository extends Mock implements VectorRepository {}

class _MockEmbeddingService extends Mock implements EmbeddingService {}

class _MockPendingEmbeddings extends Mock
    implements PendingEmbeddingRepository {}

class _MockNoteEmbeddingTrigger extends Mock implements NoteEmbeddingTrigger {}

class _MockDocumentVectors extends Mock implements DocumentVectorRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(('', '', <double>[]));
  });

  group('SearchVectorNotesUseCase', () {
    late _MockVectorRepository repo;

    setUp(() {
      repo = _MockVectorRepository();
    });

    test(
      'forwards vector/topK/minScore and wraps the result in Right',
      () async {
        when(() => repo.search([1.0, 2.0], topK: 5, minScore: 0.3)).thenAnswer(
          (_) async => const [
            ScoredNote(noteId: 'n1', score: 0.9, content: 'hit'),
          ],
        );

        final result = await SearchVectorNotesUseCase(
          repo,
        ).call(([1.0, 2.0], 5, 0.3));

        expect(result.getOrElse(() => []), hasLength(1));
        verify(() => repo.search([1.0, 2.0], topK: 5, minScore: 0.3)).called(1);
      },
    );

    test(
      'a repository throw degrades to Left, not an uncaught exception',
      () async {
        when(
          () => repo.search(
            any(),
            topK: any(named: 'topK'),
            minScore: any(named: 'minScore'),
          ),
        ).thenThrow(Exception('index unavailable'));

        final result = await SearchVectorNotesUseCase(
          repo,
        ).call(([1.0], 5, 0.3));

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('EmbedAndStoreNoteUseCase', () {
    late _MockPendingEmbeddings pending;
    late _MockNoteEmbeddingTrigger trigger;

    setUp(() {
      pending = _MockPendingEmbeddings();
      trigger = _MockNoteEmbeddingTrigger();
      when(
        () => pending.enqueue(any(), any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    test(
      'skips entirely when the content is too short after URL stripping',
      () async {
        await EmbedAndStoreNoteUseCase(
          pending,
          trigger,
        ).call(('n1', 'https://example.com/x'));

        verifyZeroInteractions(pending);
        verifyZeroInteractions(trigger);
      },
    );

    test('queues the URL-stripped text and wakes the trigger', () async {
      await EmbedAndStoreNoteUseCase(
        pending,
        trigger,
      ).call(('n1', 'a real caption https://example.com/img.png'));

      verifyInOrder([
        () => pending.enqueue('n1', 'a real caption'),
        () => trigger.nudge(),
      ]);
    });

    test('text of exactly 4 characters is queued, 3 is not', () async {
      final useCase = EmbedAndStoreNoteUseCase(pending, trigger);

      await useCase.call(('a', 'abc'));
      await useCase.call(('b', 'abcd'));

      verifyNever(() => pending.enqueue('a', any()));
      verify(() => pending.enqueue('b', 'abcd')).called(1);
    });

    test('keeps unicode text intact', () async {
      await EmbedAndStoreNoteUseCase(
        pending,
        trigger,
      ).call(('n1', 'नमस्ते दुनिया 🌟'));

      verify(() => pending.enqueue('n1', 'नमस्ते दुनिया 🌟')).called(1);
    });

    test(
      'a queueing failure is logged, not rethrown, and wakes nothing',
      () async {
        when(
          () => pending.enqueue(any(), any()),
        ).thenAnswer((_) async => Left(Failure.errorFailure('disk full')));

        await EmbedAndStoreNoteUseCase(
          pending,
          trigger,
        ).call(('n1', 'some text'));

        verifyNever(() => trigger.nudge());
      },
    );
  });

  group('SearchDocumentChunksUseCase', () {
    late _MockDocumentVectors repo;
    late SearchDocumentChunksUseCase useCase;

    const hit = ScoredChunk(
      chunkId: 's:0',
      sha256: 's',
      kind: DocumentKind.pdf,
      label: '4',
      score: 0.8,
      content: 'doc text',
    );

    setUp(() {
      repo = _MockDocumentVectors();
      useCase = SearchDocumentChunksUseCase(repo);
    });

    test(
      'forwards vector/text/topK/minScore and wraps the result in Right',
      () async {
        when(
          () => repo.search(
            [1.0, 2.0],
            queryText: 'leave rules',
            topK: 7,
            minScore: 0.6,
          ),
        ).thenAnswer((_) async => const [hit]);

        final result = await useCase(([1.0, 2.0], 7, 0.6, 'leave rules'));

        expect(result.getOrElse(() => []), [hit]);
        verify(
          () => repo.search(
            [1.0, 2.0],
            queryText: 'leave rules',
            topK: 7,
            minScore: 0.6,
          ),
        ).called(1);
      },
    );

    test(
      'a null query text is passed on as null (meaning-only ranking)',
      () async {
        when(
          () => repo.search(
            any(),
            queryText: any(named: 'queryText'),
            topK: any(named: 'topK'),
            minScore: any(named: 'minScore'),
          ),
        ).thenAnswer((_) async => const [hit]);

        await useCase(([1.0], 3, 0.3, null));

        verify(
          () => repo.search([1.0], queryText: null, topK: 3, minScore: 0.3),
        ).called(1);
      },
    );

    test('an empty result set is a Right, not a failure', () async {
      when(
        () => repo.search(
          any(),
          queryText: any(named: 'queryText'),
          topK: any(named: 'topK'),
          minScore: any(named: 'minScore'),
        ),
      ).thenAnswer((_) async => const []);

      expect(
        (await useCase(([1.0], 3, 0.3, null))).getOrElse(() => [hit]),
        isEmpty,
      );
    });

    test('a throwing repository becomes a Left, never an exception', () async {
      when(
        () => repo.search(
          any(),
          queryText: any(named: 'queryText'),
          topK: any(named: 'topK'),
          minScore: any(named: 'minScore'),
        ),
      ).thenThrow(Exception('store unavailable'));

      final result = await useCase(([1.0], 3, 0.3, null));

      expect(result.isLeft(), isTrue);
    });
  });

  group('EmbedAndStoreChunkUseCase', () {
    late _MockEmbeddingService embedding;
    late _MockDocumentVectors vectors;
    late EmbedAndStoreChunkUseCase useCase;

    setUp(() {
      embedding = _MockEmbeddingService();
      vectors = _MockDocumentVectors();
      useCase = EmbedAndStoreChunkUseCase(embedding, vectors);
      when(() => vectors.upsert(any(), any())).thenAnswer((_) async {});
    });

    test('embeds as a document and upserts under the chunk id', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) async => [1.0, 0.0]);

      final stored = await useCase(('sha:3', 'the passage'));

      expect(stored, isTrue);
      verify(() => embedding.embed('the passage', isDocument: true)).called(1);
      verify(() => vectors.upsert('sha:3', [1.0, 0.0])).called(1);
    });

    test('an empty vector means "retry later" — nothing is stored', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) async => <double>[]);

      final stored = await useCase(('sha:0', 'text'));

      expect(
        stored,
        isFalse,
        reason:
            'the embedder answers [] when not ready; that is not a '
            'document without text',
      );
      verifyNever(() => vectors.upsert(any(), any()));
    });

    test('a throwing embedder reports failure rather than escaping', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenThrow(Exception('model exploded'));

      expect(await useCase(('sha:0', 'text')), isFalse);
      verifyNever(() => vectors.upsert(any(), any()));
    });

    test('a throwing store reports failure rather than escaping', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) async => [1.0]);
      when(
        () => vectors.upsert(any(), any()),
      ).thenThrow(Exception('disk full'));

      expect(await useCase(('sha:0', 'text')), isFalse);
    });

    test('many chunks all get stored despite the concurrency bound', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) async => [1.0]);

      final results = await Future.wait([
        for (var i = 0; i < 12; i++) useCase(('sha:$i', 'chunk $i')),
      ]);

      expect(results.every((r) => r), isTrue);
      verify(() => vectors.upsert(any(), any())).called(12);
    });
  });

  group('queue and store use cases', () {
    late _MockPendingEmbeddings pending;
    late _MockVectorRepository repo;

    setUp(() {
      pending = _MockPendingEmbeddings();
      repo = _MockVectorRepository();
    });

    test('NextPendingEmbeddingUseCase returns the repository answer', () async {
      const item = PendingEmbeddingItem(eventId: 'n1', text: 'hello');
      when(() => pending.next()).thenAnswer((_) async => const Right(item));

      final r = await NextPendingEmbeddingUseCase(pending).call();

      expect(r, const Right<Failure, PendingEmbeddingItem?>(item));
    });

    test('NextPendingEmbeddingUseCase passes a failure through', () async {
      when(
        () => pending.next(),
      ).thenAnswer((_) async => Left(Failure.errorFailure('db')));

      final r = await NextPendingEmbeddingUseCase(pending).call();

      expect(r.isLeft(), isTrue);
    });

    test('RecordEmbeddingFailureUseCase returns the attempt count', () async {
      when(
        () => pending.recordFailure('n1'),
      ).thenAnswer((_) async => const Right(2));

      final r = await RecordEmbeddingFailureUseCase(pending).call('n1');

      expect(r, const Right<Failure, int>(2));
    });

    test('RemovePendingEmbeddingUseCase removes the row by id', () async {
      when(
        () => pending.remove('n1'),
      ).thenAnswer((_) async => const Right(unit));

      final r = await RemovePendingEmbeddingUseCase(pending).call('n1');

      expect(r.isRight(), isTrue);
      verify(() => pending.remove('n1')).called(1);
    });

    test('StoreNoteVectorUseCase upserts the id and vector', () async {
      when(() => repo.upsert(any(), any())).thenAnswer((_) async {});

      await StoreNoteVectorUseCase(repo).call(('n1', [0.1, 0.2]));

      verify(() => repo.upsert('n1', [0.1, 0.2])).called(1);
    });

    test('StoreNoteVectorUseCase lets a store failure throw', () async {
      when(() => repo.upsert(any(), any())).thenThrow(StateError('stopped'));

      expect(
        () => StoreNoteVectorUseCase(repo).call(('n1', [0.1])),
        throwsStateError,
      );
    });
  });
}
