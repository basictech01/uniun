import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';

class _MockSearchUseCase extends Mock implements SearchVectorNotesUseCase {}

class _MockChunkUseCase extends Mock implements SearchDocumentChunksUseCase {}

/// Note: [List]'s `==` is identity-based, so a tuple literal captured in
/// `when()` never structurally matches the one `VectorSearchService.search`
/// builds internally — every stub/verify below uses `any()` + `captureAny()`
/// instead of literal-tuple matching for that reason.
void main() {
  setUpAll(() {
    registerFallbackValue((<double>[], 0, 0.0));
    registerFallbackValue((<double>[], 0, 0.0, null as String?));
  });

  late _MockSearchUseCase useCase;
  late _MockChunkUseCase chunkUseCase;
  late VectorSearchService service;

  setUp(() {
    useCase = _MockSearchUseCase();
    chunkUseCase = _MockChunkUseCase();
    service = VectorSearchService(useCase, chunkUseCase);
  });

  test('forwards the query vector and returns the use case\'s notes on '
      'success', () async {
    when(() => useCase.call(any())).thenAnswer(
      (_) async =>
          const Right([ScoredNote(noteId: 'n1', score: 0.9, content: 'hit')]),
    );

    final result = await service.search(queryVector: [1.0, 2.0]);

    expect(result, [
      const ScoredNote(noteId: 'n1', score: 0.9, content: 'hit'),
    ]);
    final captured =
        verify(() => useCase.call(captureAny())).captured.single
            as (List<double>, int, double);
    expect(captured.$1, [1.0, 2.0]);
  });

  test('defaults topK to 5 and minScore to 0.3 when omitted', () async {
    when(
      () => useCase.call(any()),
    ).thenAnswer((_) async => const Right(<ScoredNote>[]));

    await service.search(queryVector: [1.0]);

    final captured =
        verify(() => useCase.call(captureAny())).captured.single
            as (List<double>, int, double);
    expect(captured.$2, 5);
    expect(captured.$3, 0.3);
  });

  test('forwards custom topK/minScore unchanged', () async {
    when(
      () => useCase.call(any()),
    ).thenAnswer((_) async => const Right(<ScoredNote>[]));

    await service.search(queryVector: [1.0], topK: 10, minScore: 0.7);

    final captured =
        verify(() => useCase.call(captureAny())).captured.single
            as (List<double>, int, double);
    expect(captured.$2, 10);
    expect(captured.$3, 0.7);
  });

  test('a use case failure degrades to an empty list, not a throw', () async {
    when(() => useCase.call(any())).thenAnswer(
      (_) async => const Left(Failure.errorFailure('index unavailable')),
    );

    final result = await service.search(queryVector: [1.0]);

    expect(result, isEmpty);
  });

  group('searchChunks', () {
    const hit = ScoredChunk(
      chunkId: 's:0',
      sha256: 's',
      kind: DocumentKind.pdf,
      label: '2',
      score: 0.8,
      content: 'doc text',
    );

    test('forwards the query and returns the use case\'s chunks', () async {
      when(
        () => chunkUseCase.call(any()),
      ).thenAnswer((_) async => const Right([hit]));

      final result = await service.searchChunks(queryVector: [1.0, 2.0]);

      expect(result, [hit]);
      final captured =
          verify(() => chunkUseCase.call(captureAny())).captured.single
              as (List<double>, int, double, String?);
      expect(captured.$1, [1.0, 2.0]);
    });

    test('forwards the query text for keyword ranking', () async {
      when(
        () => chunkUseCase.call(any()),
      ).thenAnswer((_) async => const Right(<ScoredChunk>[]));

      await service.searchChunks(queryVector: [1.0], queryText: 'helpline');

      final captured =
          verify(() => chunkUseCase.call(captureAny())).captured.single
              as (List<double>, int, double, String?);
      expect(captured.$4, 'helpline');
    });

    test('defaults topK to 3 and minScore to 0.3', () async {
      when(
        () => chunkUseCase.call(any()),
      ).thenAnswer((_) async => const Right(<ScoredChunk>[]));

      await service.searchChunks(queryVector: [1.0]);

      final captured =
          verify(() => chunkUseCase.call(captureAny())).captured.single
              as (List<double>, int, double, String?);
      expect(captured.$2, 3);
      expect(captured.$3, 0.3);
    });

    test('forwards custom topK/minScore unchanged', () async {
      when(
        () => chunkUseCase.call(any()),
      ).thenAnswer((_) async => const Right(<ScoredChunk>[]));

      await service.searchChunks(queryVector: [1.0], topK: 7, minScore: 0.6);

      final captured =
          verify(() => chunkUseCase.call(captureAny())).captured.single
              as (List<double>, int, double, String?);
      expect(captured.$2, 7);
      expect(captured.$3, 0.6);
    });

    test('a use case failure degrades to an empty list, not a throw', () async {
      when(() => chunkUseCase.call(any())).thenAnswer(
        (_) async => const Left(Failure.errorFailure('store unavailable')),
      );

      expect(await service.searchChunks(queryVector: [1.0]), isEmpty);
    });

    test('does not touch the note use case', () async {
      when(
        () => chunkUseCase.call(any()),
      ).thenAnswer((_) async => const Right(<ScoredChunk>[]));

      await service.searchChunks(queryVector: [1.0]);

      verifyNever(() => useCase.call(any()));
    });
  });
}
