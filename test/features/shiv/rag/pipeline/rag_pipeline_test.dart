import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_budget.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/features/shiv/rag/retrieval/enriched_context.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';

import '../../../../_helpers/fixtures.dart';

class _MockEmbedding extends Mock implements EmbeddingService {}

class _MockVectorSearch extends Mock implements VectorSearchService {}

class _MockPromptBuilder extends Mock implements PromptBuilder {}

class _MockGetActiveUser extends Mock implements GetActiveUserUseCase {}

class _MockGetOwnProfile extends Mock implements GetOwnProfileUseCase {}

class _MockGetMemories extends Mock implements GetMemoriesByNoteIdsUseCase {}

class _MockGetNeighbours extends Mock implements GetGraphNeighboursUseCase {}

class _MockGetNodesByKeys extends Mock implements GetGraphNodesByKeysUseCase {}

class _MockGetActiveModel extends Mock implements GetActiveLlmModelUseCase {}

class _MockManasLoader extends Mock implements ManasContextLoader {}

class _FakeEnrichedContext extends Fake implements EnrichedContext {}

class _FakePromptBudget extends Fake implements PromptBudget {}

void main() {
  late _MockEmbedding embedding;
  late _MockVectorSearch vectorSearch;
  late _MockPromptBuilder promptBuilder;
  late _MockGetActiveUser getActiveUser;
  late _MockGetOwnProfile getOwnProfile;
  late _MockGetMemories getMemories;
  late _MockGetNeighbours getNeighbours;
  late _MockGetNodesByKeys getNodesByKeys;
  late _MockGetActiveModel getActiveModel;
  late _MockManasLoader manasLoader;
  late RagPipeline pipeline;

  setUpAll(() {
    registerFallbackValue(_FakeEnrichedContext());
    registerFallbackValue(_FakePromptBudget());
    registerFallbackValue(<String>[]);
    registerFallbackValue((<String>[], 1));
    registerFallbackValue(const PersonalizationContext());
  });

  setUp(() {
    embedding = _MockEmbedding();
    vectorSearch = _MockVectorSearch();
    promptBuilder = _MockPromptBuilder();
    getActiveUser = _MockGetActiveUser();
    getOwnProfile = _MockGetOwnProfile();
    getMemories = _MockGetMemories();
    getNeighbours = _MockGetNeighbours();
    getNodesByKeys = _MockGetNodesByKeys();
    getActiveModel = _MockGetActiveModel();
    manasLoader = _MockManasLoader();
    pipeline = RagPipeline(
      embedding,
      vectorSearch,
      promptBuilder,
      getActiveUser,
      getOwnProfile,
      getMemories,
      getNeighbours,
      getNodesByKeys,
      getActiveModel,
      manasLoader,
    );

    when(
      () => getActiveModel.call(),
    ).thenAnswer((_) async => const Right(null));
  });

  group('init', () {
    test('delegates to the embedding service', () async {
      when(() => embedding.init()).thenAnswer((_) async {});

      await pipeline.init();

      verify(() => embedding.init()).called(1);
    });
  });

  group('buildSystemInstruction', () {
    test('loads personalization once and caches it across calls', () async {
      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk1')));
      when(
        () => getOwnProfile.call('pk1'),
      ).thenAnswer((_) async => Right(aProfile(name: 'Alice')));
      when(
        () => promptBuilder.buildSystemInstruction(any()),
      ).thenReturn('SYSTEM');

      final first = await pipeline.buildSystemInstruction();
      final second = await pipeline.buildSystemInstruction();

      expect(first, 'SYSTEM');
      expect(second, 'SYSTEM');
      verify(() => getActiveUser.call()).called(1); // cached on 2nd call
    });

    test('no active user — builds with null personalization fields', () async {
      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('no user')));
      when(() => promptBuilder.buildSystemInstruction(any())).thenAnswer((
        invocation,
      ) {
        final ctx =
            invocation.positionalArguments.single as PersonalizationContext;
        expect(ctx.userName, isNull);
        expect(ctx.userBio, isNull);
        return 'SYSTEM';
      });

      final result = await pipeline.buildSystemInstruction();

      expect(result, 'SYSTEM');
      verifyNever(() => getOwnProfile.call(any()));
    });

    test('a profile load failure still yields a valid (null-name) '
        'personalization context', () async {
      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk1')));
      when(
        () => getOwnProfile.call('pk1'),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      when(() => promptBuilder.buildSystemInstruction(any())).thenAnswer((
        invocation,
      ) {
        final ctx =
            invocation.positionalArguments.single as PersonalizationContext;
        expect(ctx.userName, isNull);
        return 'SYSTEM';
      });

      await pipeline.buildSystemInstruction();
    });

    test(
      'clearCache forces personalization to reload on the next call',
      () async {
        when(
          () => getActiveUser.call(),
        ).thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk1')));
        when(
          () => getOwnProfile.call(any()),
        ).thenAnswer((_) async => Right(aProfile(name: 'Alice')));
        when(
          () => promptBuilder.buildSystemInstruction(any()),
        ).thenReturn('SYSTEM');

        await pipeline.buildSystemInstruction();
        pipeline.clearCache();
        await pipeline.buildSystemInstruction();

        verify(() => getActiveUser.call()).called(2);
      },
    );
  });

  group('buildBranchContextSummary', () {
    test('delegates straight to the prompt builder', () {
      final branch = [
        ShivMessageEntity(
          messageId: 'm1',
          conversationId: 'c1',
          role: MessageRole.user,
          content: 'hi',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      when(
        () => promptBuilder.buildBranchContextSummary(any()),
      ).thenReturn('SUMMARY');

      final result = pipeline.buildBranchContextSummary(branch);

      expect(result, 'SUMMARY');
      verify(() => promptBuilder.buildBranchContextSummary(branch)).called(1);
    });
  });

  group('buildMessage — vector-seeded retrieval (no manasIds)', () {
    setUp(() {
      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      when(
        () => promptBuilder.buildUserMessage(
          userQuestion: any(named: 'userQuestion'),
          context: any(named: 'context'),
          budget: any(named: 'budget'),
          userName: any(named: 'userName'),
        ),
      ).thenReturn('USER_MESSAGE');
    });

    test('embedder returns empty — empty context, contextCount 0', () async {
      when(() => embedding.embed(any())).thenAnswer((_) async => <double>[]);

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.contextCount, 0);
      expect(result.sourceNoteIds, isEmpty);
      verifyNever(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      );
    });

    test('no vector hits — empty context, no graph/memory calls', () async {
      when(() => embedding.embed(any())).thenAnswer((_) async => [1.0]);
      when(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      ).thenAnswer((_) async => const []);

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.contextCount, 0);
      verifyNever(() => getMemories.call(any()));
    });

    test('full pipeline: seed notes -> memories -> graph expand -> nodes '
        '-> expanded memories, all merged into contextCount', () async {
      when(() => embedding.embed(any())).thenAnswer((_) async => [1.0]);
      when(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      ).thenAnswer(
        (_) async => const [
          ScoredNote(noteId: 'seed1', score: 0.9, content: 'seed one'),
        ],
      );
      // List/tuple args are compared by identity, not value, so every stub
      // below matches on `any()` and inspects the real argument via
      // `invocation` instead of relying on literal-list `==`.
      when(() => getMemories.call(any())).thenAnswer((invocation) async {
        final ids = invocation.positionalArguments.single as List<String>;
        if (ids.contains('seed1')) {
          return Right([
            MemoryNodeEntity(
              noteId: 'seed1',
              summary: 's',
              keyPoints: const [],
              concepts: const ['cats'],
              linkedNoteIds: const [],
              updatedAt: DateTime(2026, 1, 1),
            ),
          ]);
        }
        return Right([
          MemoryNodeEntity(
            noteId: 'expanded1',
            summary: 's2',
            keyPoints: const [],
            concepts: const [],
            linkedNoteIds: const [],
            updatedAt: DateTime(2026, 1, 1),
          ),
        ]);
      });
      when(() => getNeighbours.call(any())).thenAnswer(
        (_) async => Right([
          GraphEdgeEntity(
            sourceKey: 'cats',
            targetKey: 'dogs',
            relationType: 'related',
            sourceNoteId: 'expanded1',
            createdAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      when(() => getNodesByKeys.call(any())).thenAnswer(
        (_) async => Right([
          GraphNodeEntity(
            key: 'cats',
            name: 'Cats',
            type: 'concept',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ]),
      );

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.userMessage, 'USER_MESSAGE');
      expect(result.sourceNoteIds, ['seed1']);
      // 1 seed note + 1 graph edge + 2 memories (seed + expanded) = 4.
      expect(result.contextCount, 4);
    });

    test(
      'expanded note ids already among the seeds are not re-fetched',
      () async {
        when(() => embedding.embed(any())).thenAnswer((_) async => [1.0]);
        when(
          () => vectorSearch.search(
            queryVector: any(named: 'queryVector'),
            topK: any(named: 'topK'),
          ),
        ).thenAnswer(
          (_) async => const [
            ScoredNote(noteId: 'seed1', score: 0.9, content: 'seed one'),
          ],
        );
        when(
          () => getMemories.call(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => getNeighbours.call(any())).thenAnswer(
          (_) async => Right([
            GraphEdgeEntity(
              sourceKey: 'k1',
              targetKey: 'k2',
              relationType: 'related',
              sourceNoteId: 'seed1', // same as the seed — must not re-fetch
              createdAt: DateTime(2026, 1, 1),
            ),
          ]),
        );
        when(
          () => getNodesByKeys.call(any()),
        ).thenAnswer((_) async => const Right([]));

        await pipeline.buildMessage(userQuestion: 'q');

        // Only the seed-ids call — the expanded set is empty (its only note
        // id, 'seed1', is already among the seeds), so the second
        // (expandedNoteIds-driven) getMemories call never happens.
        verify(() => getMemories.call(any())).called(1);
      },
    );

    test('a getNeighbours failure degrades to no graph expansion, not a '
        'crash', () async {
      when(() => embedding.embed(any())).thenAnswer((_) async => [1.0]);
      when(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      ).thenAnswer(
        (_) async => const [
          ScoredNote(noteId: 'seed1', score: 0.9, content: 'x'),
        ],
      );
      when(
        () => getMemories.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNeighbours.call(any()),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('graph down')));
      when(
        () => getNodesByKeys.call(any()),
      ).thenAnswer((_) async => const Right([]));

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.contextCount, 1); // just the seed note
    });

    test('an uncaught exception anywhere in retrieval degrades to empty '
        'context rather than propagating', () async {
      when(
        () => embedding.embed(any()),
      ).thenThrow(Exception('embedder crashed'));

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.contextCount, 0);
      expect(result.sourceNoteIds, isEmpty);
    });
  });

  group('buildMessage — document chunks', () {
    const chunk = ScoredChunk(
      chunkId: 's:0',
      sha256: 's',
      kind: DocumentKind.pdf,
      label: '2',
      score: 0.8,
      content: 'doc text',
    );

    setUp(() {
      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      when(() => embedding.embed(any())).thenAnswer((_) async => [1.0]);
      when(
        () => promptBuilder.buildUserMessage(
          userQuestion: any(named: 'userQuestion'),
          context: any(named: 'context'),
          budget: any(named: 'budget'),
          userName: any(named: 'userName'),
        ),
      ).thenReturn('USER_MESSAGE');
      when(
        () => getMemories.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNeighbours.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNodesByKeys.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      ).thenAnswer((_) async => const []);
    });

    void stubChunks(List<ScoredChunk> chunks) => when(
      () => vectorSearch.searchChunks(
        queryVector: any(named: 'queryVector'),
        queryText: any(named: 'queryText'),
        topK: any(named: 'topK'),
      ),
    ).thenAnswer((_) async => chunks);

    test(
      'a chunk-only match still produces context and a source chunk id',
      () async {
        stubChunks(const [chunk]);

        final result = await pipeline.buildMessage(userQuestion: 'q');

        expect(result.sourceChunkIds, ['s:0']);
        expect(result.sourceNoteIds, isEmpty);
        expect(result.contextCount, 1);
        verifyNever(() => getMemories.call(any()));
        verifyNever(() => getNeighbours.call(any()));
        final ctx =
            verify(
                  () => promptBuilder.buildUserMessage(
                    userQuestion: any(named: 'userQuestion'),
                    context: captureAny(named: 'context'),
                    budget: any(named: 'budget'),
                    userName: any(named: 'userName'),
                  ),
                ).captured.single
                as EnrichedContext;
        expect(ctx.seedChunks.single.chunkId, 's:0');
      },
    );

    test('notes and chunks together both reach the result', () async {
      when(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      ).thenAnswer(
        (_) async => const [
          ScoredNote(noteId: 'n1', score: 0.9, content: 'a note'),
        ],
      );
      stubChunks(const [chunk]);

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.sourceNoteIds, ['n1']);
      expect(result.sourceChunkIds, ['s:0']);
      expect(result.contextCount, 2);
    });

    test(
      'chunk top-K is half the note top-K (min 1), notes unchanged',
      () async {
        stubChunks(const []);

        await pipeline.buildMessage(userQuestion: 'q');

        // No active model → the local default budget's topK is 3.
        verify(
          () => vectorSearch.search(
            queryVector: any(named: 'queryVector'),
            topK: 3,
          ),
        ).called(1);
        verify(
          () => vectorSearch.searchChunks(
            queryVector: any(named: 'queryVector'),
            queryText: 'q',
            topK: 1,
          ),
        ).called(1);
      },
    );

    test('a chunk search that throws degrades to notes only', () async {
      when(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      ).thenAnswer(
        (_) async => const [
          ScoredNote(noteId: 'n1', score: 0.9, content: 'a note'),
        ],
      );
      when(
        () => vectorSearch.searchChunks(
          queryVector: any(named: 'queryVector'),
          queryText: any(named: 'queryText'),
          topK: any(named: 'topK'),
        ),
      ).thenThrow(Exception('store unavailable'));

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.sourceNoteIds, ['n1']);
      expect(result.sourceChunkIds, isEmpty);
    });

    test('no notes and no chunks is an empty context', () async {
      stubChunks(const []);

      final result = await pipeline.buildMessage(userQuestion: 'q');

      expect(result.contextCount, 0);
      expect(result.sourceChunkIds, isEmpty);
    });
  });

  group('buildMessage — Manas-scoped retrieval', () {
    setUp(() {
      when(
        () => getActiveUser.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      when(
        () => promptBuilder.buildUserMessage(
          userQuestion: any(named: 'userQuestion'),
          context: any(named: 'context'),
          budget: any(named: 'budget'),
          userName: any(named: 'userName'),
        ),
      ).thenReturn('USER_MESSAGE');
      when(
        () => getMemories.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNeighbours.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => getNodesByKeys.call(any()),
      ).thenAnswer((_) async => const Right([]));
    });

    test('a non-empty manasIds list uses ManasContextLoader.merge, not the '
        'vector index directly', () async {
      when(
        () => manasLoader.merge(
          manasIds: any(named: 'manasIds'),
          budget: any(named: 'budget'),
          relevanceQuery: any(named: 'relevanceQuery'),
        ),
      ).thenAnswer(
        (_) async => [
          PackedNote(
            id: 'n1',
            content: 'packed note',
            created: DateTime(2026, 1, 1),
            source: PackedNoteSource.own,
          ),
        ],
      );

      final result = await pipeline.buildMessage(
        userQuestion: 'q',
        manasIds: const ['m1'],
      );

      expect(result.sourceNoteIds, ['n1']);
      expect(result.sourceChunkIds, isEmpty);
      verifyNever(() => embedding.embed(any()));
      verifyNever(
        () => vectorSearch.search(
          queryVector: any(named: 'queryVector'),
          topK: any(named: 'topK'),
        ),
      );
      verifyNever(
        () => vectorSearch.searchChunks(
          queryVector: any(named: 'queryVector'),
          queryText: any(named: 'queryText'),
          topK: any(named: 'topK'),
        ),
      );
    });

    test('caps Manas-scoped seed notes to the budget\'s topK', () async {
      when(
        () => manasLoader.merge(
          manasIds: any(named: 'manasIds'),
          budget: any(named: 'budget'),
          relevanceQuery: any(named: 'relevanceQuery'),
        ),
      ).thenAnswer(
        (_) async => List.generate(
          20,
          (i) => PackedNote(
            id: 'n$i',
            content: 'note $i',
            created: DateTime(2026, 1, 1),
            source: PackedNoteSource.own,
          ),
        ),
      );

      final result = await pipeline.buildMessage(
        userQuestion: 'q',
        manasIds: const ['m1'],
      );

      // PromptBudget.forActiveModel(null) picks the smallest local tier —
      // whatever its topK is, the seed list must never exceed it.
      final budget = PromptBudget.forActiveModel(null);
      expect(result.sourceNoteIds.length, budget.topK);
    });

    test(
      'an empty Manas note pool yields empty context, not a crash',
      () async {
        when(
          () => manasLoader.merge(
            manasIds: any(named: 'manasIds'),
            budget: any(named: 'budget'),
            relevanceQuery: any(named: 'relevanceQuery'),
          ),
        ).thenAnswer((_) async => const []);

        final result = await pipeline.buildMessage(
          userQuestion: 'q',
          manasIds: const ['m1'],
        );

        expect(result.contextCount, 0);
      },
    );
  });
}
