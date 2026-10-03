import 'dart:async';
import 'dart:math' as math;

import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
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
import 'package:uniun/features/shiv/rag/prompt/prompt_budget.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/features/shiv/rag/retrieval/enriched_context.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';

/// Result returned by [RagPipeline.buildMessage].
class RagMessage {
  const RagMessage({
    required this.userMessage,
    required this.contextCount,
    this.sourceNoteIds = const [],
    this.sourceChunkIds = const [],
  });

  /// The per-turn message for [AIModelRunner.sendAndStream]:
  /// RAG context (if any) + current user question. No history, no system.
  final String userMessage;

  /// Number of notes + graph edges + memories injected as context.
  /// 0 = model not loaded or no match.
  final int contextCount;

  /// Event ids of the seed notes (vector hits) that informed this turn,
  /// in score-desc order. Used by the UI to show the "Sources" sheet under
  /// the last reply. Empty when no notes matched / model not loaded. Excludes
  /// graph edges and memory summaries — these are the actual source notes.
  final List<String> sourceNoteIds;

  /// Chunk ids (`"<sha256>:<ordinal>"`) of the PDF passages that informed this
  /// turn, score-desc. Resolved on demand by the Sources sheet. Always empty in
  /// Manas-scoped chat, which never searches documents.
  final List<String> sourceChunkIds;
}

/// Orchestrates the full RAG + GraphRAG pipeline.
///
/// ## Two-phase usage (matches InferenceChat's split):
///
/// **Phase 1 — session open** (once per conversation):
///   ```dart
///   await rag.init();
///   await runner.initChat();                 // validate a model is active
///   final sysInstruction = await rag.buildSystemInstruction();
///   ```
///
/// **Phase 2 — each user message** (the system instruction rides each turn, so
/// each consumer/surface supplies its OWN — nothing is stored on the runner):
///   ```dart
///   final msg = await rag.buildMessage(userQuestion: text);
///   runner.sendAndStream(msg.userMessage, systemInstruction: sysInstruction);
///   ```
@lazySingleton
class RagPipeline {
  final EmbeddingService _embedding;
  final VectorSearchService _vectorSearch;
  final PromptBuilder _promptBuilder;
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnProfileUseCase _getOwnProfile;
  final GetMemoriesByNoteIdsUseCase _getMemories;
  final GetGraphNeighboursUseCase _getNeighbours;
  final GetGraphNodesByKeysUseCase _getNodesByKeys;
  final GetActiveLlmModelUseCase _getActiveModel;
  final ManasContextLoader _manasLoader;

  PersonalizationContext? _personalization;

  RagPipeline(
    this._embedding,
    this._vectorSearch,
    this._promptBuilder,
    this._getActiveUser,
    this._getOwnProfile,
    this._getMemories,
    this._getNeighbours,
    this._getNodesByKeys,
    this._getActiveModel,
    this._manasLoader,
  );

  // ── Phase 1 ────────────────────────────────────────────────────────────────

  /// Loads the embedding model from disk. Call once when the Shiv tab opens.
  Future<void> init() async {
    await _embedding.init();
  }

  /// Returns the **Shiv-chat** system instruction for this session (persona +
  /// user name/bio). This is one of several distinct, per-use-case system
  /// instructions — Gana, Nataraj, extraction, and composer-chat each build
  /// their own. Pass the result into [AIModelRunner.sendAndStream] per turn.
  Future<String> buildSystemInstruction() async {
    _personalization ??= await _loadPersonalization();
    return _promptBuilder.buildSystemInstruction(_personalization!);
  }

  // ── Phase 2 ────────────────────────────────────────────────────────────────

  /// Builds the per-turn user message: GraphRAG context (if any) + question.
  /// Steps: vector seed → 1-hop graph expansion → memory retrieval →
  /// budget-aware assembly. Do NOT pass conversation history —
  /// [InferenceChat] manages it internally.
  Future<RagMessage> buildMessage({
    required String userQuestion,
    List<String> manasIds = const [],
  }) async {
    // Budget scales with the active backend: small local models get a tight
    // 2k window with topK=3; bigger local models get 4-8k with topK=5-10;
    // cloud models get 16k with topK=15 + 2-hop graph expansion.
    final budget = PromptBudget.forActiveModel(await _activeModel());
    // [manasIds] (from the composer's scope picker) confines retrieval to the
    // selected Manas; empty = the whole library.
    final context = await _retrieveContext(
      userQuestion,
      topK: budget.topK,
      maxHops: budget.maxHops,
      manasIds: manasIds,
    );
    _personalization ??= await _loadPersonalization();
    final userMessage = _promptBuilder.buildUserMessage(
      userQuestion: userQuestion,
      context: context,
      budget: budget,
      userName: _personalization?.userName,
    );
    final count = context.seedNotes.length +
        context.seedChunks.length +
        context.graphEdges.length +
        context.memories.length;
    return RagMessage(
      userMessage: userMessage,
      contextCount: count,
      sourceNoteIds: context.seedNotes.map((s) => s.noteId).toList(),
      sourceChunkIds: context.seedChunks.map((c) => c.chunkId).toList(),
    );
  }

  /// Builds a compact summary of [branch] messages for system instruction
  /// injection when the user switches branches. Delegates to [PromptBuilder].
  String buildBranchContextSummary(List<ShivMessageEntity> branch) =>
      _promptBuilder.buildBranchContextSummary(branch);

  /// Clear the personalisation cache (call when profile changes or on logout).
  void clearCache() => _personalization = null;

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<EnrichedContext> _retrieveContext(
    String query, {
    int topK = 5,
    int maxHops = 1,
    List<String> manasIds = const [],
  }) async {
    try {
      // 1. Vector seed — confined to the selected Manas, or the whole library.
      final List<ScoredNote> seedNotes;
      var seedChunks = const <ScoredChunk>[];
      if (manasIds.isNotEmpty) {
        // Manas-scoped: relevance-rank within the picked Manas's notes.
        final packed = await _manasLoader.merge(
          manasIds: manasIds,
          budget: topK * 200, // ~topK notes' worth of tokens
          relevanceQuery: query,
        );
        seedNotes = [
          for (final p in packed.take(topK))
            ScoredNote(noteId: p.id, score: 1.0, content: p.content),
        ];
      } else {
        final vec = await _embedding.embed(query);
        if (vec.isEmpty) return EnrichedContext.empty;
        seedNotes = await _vectorSearch.search(queryVector: vec, topK: topK);
        // Documents are unscoped-chat only: a Manas scopes by note membership,
        // which a PDF blob has none of.
        seedChunks = await _safeChunkSearch(
          vec,
          query,
          math.max(1, topK ~/ 2),
        );
      }
      if (seedNotes.isEmpty && seedChunks.isEmpty) return EnrichedContext.empty;
      // A document-only match has nothing to expand: chunks are not graph nodes
      // and carry no memory summaries.
      if (seedNotes.isEmpty) {
        return EnrichedContext(
          seedNotes: const [],
          seedChunks: seedChunks,
          graphNodes: const [],
          graphEdges: const [],
          memories: const [],
        );
      }

      // 2. Memory for seeds → collect concept keys.
      final seedIds = seedNotes.map((s) => s.noteId).toList();
      final seedMemoriesResult = await _getMemories.call(seedIds);
      final seedMemories =
          seedMemoriesResult.fold((_) => <MemoryNodeEntity>[], (m) => m);
      final conceptKeys = <String>{
        for (final m in seedMemories) ...m.concepts,
      }.toList();

      // 3. Graph expand.
      final edgesResult = await _getNeighbours.call((conceptKeys, maxHops));
      final edges =
          edgesResult.fold((_) => <GraphEdgeEntity>[], (e) => e);

      // 4. Nodes for edge labels.
      final involvedKeys = <String>{
        for (final e in edges) ...[e.sourceKey, e.targetKey]
      }.toList();
      final nodesResult = await _getNodesByKeys.call(involvedKeys);
      final nodes =
          nodesResult.fold((_) => <GraphNodeEntity>[], (n) => n);

      // 5. Memories for notes that asserted these edges (beyond the seeds).
      final expandedNoteIds = <String>{
        for (final e in edges) e.sourceNoteId,
      }.where((id) => !seedIds.contains(id)).toList();
      List<MemoryNodeEntity> expandedMemories = const [];
      if (expandedNoteIds.isNotEmpty) {
        final res = await _getMemories.call(expandedNoteIds);
        expandedMemories =
            res.fold((_) => <MemoryNodeEntity>[], (m) => m);
      }

      return EnrichedContext(
        seedNotes: seedNotes,
        seedChunks: seedChunks,
        graphNodes: nodes,
        graphEdges: edges,
        memories: [...seedMemories, ...expandedMemories],
      );
    } catch (_) {
      return EnrichedContext.empty;
    }
  }

  /// Chunk retrieval must never cost a turn its notes: a failing document store
  /// degrades to notes-only rather than losing the whole context.
  Future<List<ScoredChunk>> _safeChunkSearch(
    List<double> vec,
    String query,
    int topK,
  ) async {
    try {
      return await _vectorSearch.searchChunks(
        queryVector: vec,
        queryText: query,
        topK: topK,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<LlmModelInfo?> _activeModel() async {
    final result = await _getActiveModel.call();
    return result.fold((_) => null, (m) => m);
  }

  Future<PersonalizationContext> _loadPersonalization() async {
    String? name;
    String? bio;

    final userResult = await _getActiveUser.call();
    final pubkey = userResult.fold((_) => null, (u) => u.pubkeyHex);

    if (pubkey != null) {
      final profileResult = await _getOwnProfile.call(pubkey);
      profileResult.fold((_) {}, (profile) {
        name = profile?.name;
        bio = profile?.about;
      });
    }

    return PersonalizationContext(userName: name, userBio: bio);
  }
}

