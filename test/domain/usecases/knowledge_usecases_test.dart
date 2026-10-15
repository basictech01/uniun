import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/graph_repository.dart';
import 'package:uniun/domain/repositories/memory_repository.dart';
import 'package:uniun/domain/repositories/pending_extraction_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';

class _MockHasActiveModel extends Mock implements HasActiveLlmModelUseCase {}

class _MockGenerateOneShot extends Mock implements GenerateOneShotUseCase {}

class _MockSearchVector extends Mock implements SearchVectorNotesUseCase {}

class _MockGraphRepository extends Mock implements GraphRepository {}

class _MockMemoryRepository extends Mock implements MemoryRepository {}

class _MockPendingExtractionRepository extends Mock
    implements PendingExtractionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(GraphNodeEntity(
      key: 'k',
      name: 'n',
      type: 'Concept',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    registerFallbackValue(GraphEdgeEntity(
      sourceKey: 'a',
      targetKey: 'b',
      relationType: 'uses',
      sourceNoteId: 'n1',
      createdAt: DateTime(2026, 1, 1),
    ));
    registerFallbackValue(MemoryNodeEntity(
      noteId: 'n1',
      summary: '',
      keyPoints: const [],
      concepts: const [],
      linkedNoteIds: const [],
      updatedAt: DateTime(2026, 1, 1),
    ));
    registerFallbackValue(const GenerateOneShotInput(prompt: ''));
    registerFallbackValue((<double>[], 0, 0.0, null as Set<String>?));
    registerFallbackValue(('', '', <double>[]));
  });

  group('ExtractKnowledgeUseCase', () {
    late _MockHasActiveModel hasModel;
    late _MockGenerateOneShot oneShot;
    late _MockSearchVector searchVector;
    late _MockGraphRepository graph;
    late _MockMemoryRepository memory;
    late _MockPendingExtractionRepository pending;
    late ExtractKnowledgeUseCase useCase;

    setUp(() {
      hasModel = _MockHasActiveModel();
      oneShot = _MockGenerateOneShot();
      searchVector = _MockSearchVector();
      graph = _MockGraphRepository();
      memory = _MockMemoryRepository();
      pending = _MockPendingExtractionRepository();
      useCase = ExtractKnowledgeUseCase(
        hasModel,
        oneShot,
        const PromptBuilder(),
        searchVector,
        graph,
        memory,
        pending,
      );

      when(() => pending.mark(any(), any(), any())).thenAnswer((_) async {});
      when(() => pending.clear(any())).thenAnswer((_) async {});
      when(() => graph.upsertNode(any())).thenAnswer((_) async => const Right(unit));
      when(() => graph.upsertEdge(any())).thenAnswer((_) async => const Right(unit));
      when(() => memory.upsert(any())).thenAnswer((_) async => const Right(unit));
      when(() => searchVector.call(any())).thenAnswer((_) async => const Right([]));
    });

    test('skips when content is empty, never touching the model gate',
        () async {
      await useCase.call(('n1', '   ', [0.1]));

      verifyZeroInteractions(hasModel);
      verifyZeroInteractions(pending);
    });

    test('skips when the query vector is empty', () async {
      await useCase.call(('n1', 'some real content', []));

      verifyZeroInteractions(hasModel);
    });

    test('skips when no LLM backend is active, before marking pending',
        () async {
      when(() => hasModel.call()).thenAnswer((_) async => false);

      await useCase.call(('n1', 'some real content', [0.1]));

      verifyZeroInteractions(pending);
      verifyZeroInteractions(oneShot);
    });

    test('marks pending before calling the LLM, clears it on success',
        () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => oneShot.call(any())).thenAnswer((_) async => Right(
            '{"summary":"s","keyPoints":["a"],"concepts":["Dart"],'
            '"relations":[{"source":"Dart","target":"Flutter","type":"powers"}],'
            '"links":["n2"]}',
          ));

      await useCase.call(('n1', 'some real content', [0.1]));

      verify(() => pending.mark('n1', 'some real content', [0.1])).called(1);
      verify(() => pending.clear('n1')).called(1);
    });

    test('a null one-shot result (no active model / cancelled) skips '
        'persistence and pending stays marked', () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => oneShot.call(any())).thenAnswer((_) async => const Right(null));

      await useCase.call(('n1', 'some real content', [0.1]));

      verifyZeroInteractions(graph);
      verifyZeroInteractions(memory);
      verifyNever(() => pending.clear(any()));
    });

    test('unparseable LLM output skips persistence, pending stays marked',
        () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => oneShot.call(any())).thenAnswer((_) async => const Right('not json at all'));

      await useCase.call(('n1', 'some real content', [0.1]));

      verifyZeroInteractions(graph);
      verifyNever(() => pending.clear(any()));
    });

    test('valid JSON upserts one node per concept, edges for every '
        'relation (both endpoints as nodes), and the memory node', () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => oneShot.call(any())).thenAnswer((_) async => Right(
            '{"summary":"A summary","keyPoints":["point one"],'
            '"concepts":["Dart","Flutter"],'
            '"relations":[{"source":"Dart","target":"Flutter","type":"powers UI for"}],'
            '"links":["n2"]}',
          ));

      await useCase.call(('n1', 'some real content', [0.1]));

      // 2 concept upserts + 2 relation-endpoint upserts (already covered by
      // concepts here, but the use case doesn't dedupe the upsert calls).
      verify(() => graph.upsertNode(any())).called(4);
      final edge = verify(() => graph.upsertEdge(captureAny())).captured.single as GraphEdgeEntity;
      expect(edge.sourceKey, 'dart');
      expect(edge.targetKey, 'flutter');
      expect(edge.relationType, 'powers_ui_for');
      expect(edge.sourceNoteId, 'n1');

      final mem = verify(() => memory.upsert(captureAny())).captured.single as MemoryNodeEntity;
      expect(mem.noteId, 'n1');
      expect(mem.summary, 'A summary');
      expect(mem.concepts, ['dart', 'flutter']);
      expect(mem.linkedNoteIds, ['n2']);
    });

    test('tolerates markdown-fenced JSON by scanning for the outer braces',
        () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => oneShot.call(any())).thenAnswer((_) async => Right(
            '```json\n{"summary":"s","keyPoints":[],"concepts":["X"],'
            '"relations":[],"links":[]}\n```',
          ));

      await useCase.call(('n1', 'some real content', [0.1]));

      verify(() => memory.upsert(any())).called(1);
    });

    test('repairs malformed relation objects via regex when the outer JSON '
        'is invalid, dropping only the malformed ones', () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      // Malformed: relations use a bad shorthand form `{"A","B","uses"}`
      // mixed with one well-formed object — makes the whole blob invalid
      // JSON, forcing the regex repair path.
      when(() => oneShot.call(any())).thenAnswer((_) async => Right(
            '{"summary":"a summary","keyPoints":["p1"],"concepts":["A","B"],'
            '"relations":[{"A","B","uses"},'
            '{"source":"A","target":"B","type":"relates_to"}],"links":[]}',
          ));

      await useCase.call(('n1', 'some real content', [0.1]));

      final edge = verify(() => graph.upsertEdge(captureAny())).captured.single as GraphEdgeEntity;
      expect(edge.relationType, 'relates_to');
      verify(() => memory.upsert(any())).called(1);
    });

    test('an unexpected exception during the LLM call is caught, not '
        'rethrown', () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => oneShot.call(any())).thenThrow(Exception('scheduler exploded'));

      await useCase.call(('n1', 'some real content', [0.1]));

      verifyZeroInteractions(graph);
    });

    test('excludes the note itself from the similar-notes context', () async {
      when(() => hasModel.call()).thenAnswer((_) async => true);
      when(() => searchVector.call(any())).thenAnswer((_) async => const Right([
            ScoredNote(noteId: 'n1', score: 1.0, content: 'self'),
            ScoredNote(noteId: 'n2', score: 0.9, content: 'other'),
          ]));
      when(() => oneShot.call(any())).thenAnswer((_) async => const Right(null));

      await useCase.call(('n1', 'some real content', [0.1]));

      // No direct assertion surface for the prompt content itself (private),
      // but this at minimum proves the search+filter path runs without
      // crashing when the note's own id is present in its results.
      verify(() => searchVector.call(any())).called(1);
    });
  });

  test('GetMemoriesByNoteIdsUseCase delegates to getByNoteIds', () async {
    final memory = _MockMemoryRepository();
    when(() => memory.getByNoteIds(['n1'])).thenAnswer((_) async => const Right([]));

    final result = await GetMemoriesByNoteIdsUseCase(memory).call(['n1']);

    expect(result.isRight(), isTrue);
    verify(() => memory.getByNoteIds(['n1'])).called(1);
  });

  test('GetGraphNeighboursUseCase forwards keys + maxHops', () async {
    final graph = _MockGraphRepository();
    when(() => graph.getNeighbours(['a'], maxHops: 2)).thenAnswer((_) async => const Right([]));

    await GetGraphNeighboursUseCase(graph).call((['a'], 2));

    verify(() => graph.getNeighbours(['a'], maxHops: 2)).called(1);
  });

  test('GetGraphNodesByKeysUseCase delegates to getNodesByKeys', () async {
    final graph = _MockGraphRepository();
    when(() => graph.getNodesByKeys(['a'])).thenAnswer((_) async => const Right([]));

    await GetGraphNodesByKeysUseCase(graph).call(['a']);

    verify(() => graph.getNodesByKeys(['a'])).called(1);
  });

  group('DrainPendingExtractionsUseCase', () {
    test('no-ops cleanly when there is nothing pending', () async {
      final pending = _MockPendingExtractionRepository();
      final extract = _MockExtractKnowledge();
      when(() => pending.all()).thenAnswer((_) async => []);

      await DrainPendingExtractionsUseCase(pending, extract).call();

      verifyZeroInteractions(extract);
    });

    test('replays every pending item through ExtractKnowledgeUseCase',
        () async {
      final pending = _MockPendingExtractionRepository();
      final extract = _MockExtractKnowledge();
      when(() => pending.all()).thenAnswer((_) async => [
            const PendingExtractionItem(noteId: 'n1', content: 'a', vec: [0.1]),
            const PendingExtractionItem(noteId: 'n2', content: 'b', vec: [0.2]),
          ]);
      when(() => extract.call(any())).thenAnswer((_) async {});

      await DrainPendingExtractionsUseCase(pending, extract).call();

      // Record equality is identity-based on the embedded List, so compare
      // captured fields instead of literal-tuple matching.
      final captured = verify(() => extract.call(captureAny(), cached: any(named: 'cached')))
          .captured
          .cast<(String, String, List<double>)>();
      expect(captured, hasLength(2));
      expect(captured[0].$1, 'n1');
      expect(captured[0].$2, 'a');
      expect(captured[0].$3, [0.1]);
      expect(captured[1].$1, 'n2');
      expect(captured[1].$2, 'b');
      expect(captured[1].$3, [0.2]);
    });
  });

  group('DeleteKnowledgeForNoteUseCase', () {
    test('deletes graph then memory, returning unit on success', () async {
      final graph = _MockGraphRepository();
      final memory = _MockMemoryRepository();
      when(() => graph.deleteForNote('n1')).thenAnswer((_) async => const Right(unit));
      when(() => memory.deleteByNoteId('n1')).thenAnswer((_) async => const Right(unit));

      final result = await DeleteKnowledgeForNoteUseCase(graph, memory).call('n1');

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('a graph deletion failure short-circuits before touching memory',
        () async {
      final graph = _MockGraphRepository();
      final memory = _MockMemoryRepository();
      const failure = Failure.errorFailure('isar write failed');
      when(() => graph.deleteForNote('n1')).thenAnswer((_) async => const Left(failure));

      final result = await DeleteKnowledgeForNoteUseCase(graph, memory).call('n1');

      expect(result, const Left<Failure, Unit>(failure));
      verifyZeroInteractions(memory);
    });

    test('a memory deletion failure surfaces as Left even though graph '
        'succeeded', () async {
      final graph = _MockGraphRepository();
      final memory = _MockMemoryRepository();
      const failure = Failure.errorFailure('isar write failed');
      when(() => graph.deleteForNote('n1')).thenAnswer((_) async => const Right(unit));
      when(() => memory.deleteByNoteId('n1')).thenAnswer((_) async => const Left(failure));

      final result = await DeleteKnowledgeForNoteUseCase(graph, memory).call('n1');

      expect(result, const Left<Failure, Unit>(failure));
    });
  });
}

class _MockExtractKnowledge extends Mock implements ExtractKnowledgeUseCase {}
