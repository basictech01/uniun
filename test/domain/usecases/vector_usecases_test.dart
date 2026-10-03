import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

class _MockVectorRepository extends Mock implements VectorRepository {}

class _MockEmbeddingService extends Mock implements EmbeddingService {}

class _MockExtractKnowledge extends Mock implements ExtractKnowledgeUseCase {}

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
    late _MockEmbeddingService embedding;
    late _MockVectorRepository vector;
    late _MockExtractKnowledge extract;

    setUp(() {
      embedding = _MockEmbeddingService();
      vector = _MockVectorRepository();
      extract = _MockExtractKnowledge();
    });

    test(
      'skips entirely when the content is too short after URL stripping',
      () async {
        await EmbedAndStoreNoteUseCase(
          embedding,
          vector,
          extract,
        ).call(('n1', 'https://example.com/x'));

        verifyZeroInteractions(embedding);
        verifyZeroInteractions(vector);
      },
    );

    test('embeds the URL-stripped text and upserts, then fires knowledge '
        'extraction', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) async => [0.1, 0.2]);
      when(() => vector.upsert('n1', [0.1, 0.2])).thenAnswer((_) async {});
      when(() => extract.call(any())).thenAnswer((_) async {});

      await EmbedAndStoreNoteUseCase(
        embedding,
        vector,
        extract,
      ).call(('n1', 'a real caption https://example.com/img.png'));

      verify(
        () => embedding.embed('a real caption', isDocument: true),
      ).called(1);
      verify(() => vector.upsert('n1', [0.1, 0.2])).called(1);
      await Future<void>.delayed(Duration.zero);
      // A record field's `==` is identity-based for the embedded List, so a
      // literal-tuple match would never equal the tuple built by production
      // code — capture and compare fields instead.
      final captured =
          verify(
                () => extract.call(captureAny(), cached: any(named: 'cached')),
              ).captured.single
              as (String, String, List<double>);
      expect(captured.$1, 'n1');
      expect(captured.$2, 'a real caption');
      expect(captured.$3, [0.1, 0.2]);
    });

    test('an empty embedding vector skips the upsert and extraction', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenAnswer((_) async => <double>[]);

      await EmbedAndStoreNoteUseCase(
        embedding,
        vector,
        extract,
      ).call(('n1', 'some text'));

      verifyZeroInteractions(vector);
      verifyZeroInteractions(extract);
    });

    test('an embedding failure is caught, not rethrown', () async {
      when(
        () => embedding.embed(any(), isDocument: any(named: 'isDocument')),
      ).thenThrow(Exception('model not loaded'));

      await EmbedAndStoreNoteUseCase(
        embedding,
        vector,
        extract,
      ).call(('n1', 'some text'));

      verifyZeroInteractions(vector);
    });
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
      useCase = EmbedAndStoreChunkUseCase(embedding, vectors, EmbeddingQueue());
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
}
