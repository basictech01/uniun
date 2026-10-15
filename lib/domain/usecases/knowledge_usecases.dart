import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/graph_repository.dart';
import 'package:uniun/domain/repositories/memory_repository.dart';
import 'package:uniun/domain/repositories/pending_extraction_repository.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';

/// Extracts a knowledge graph + wiki-style memory entry for a single note by
/// calling Gemma in one-shot mode. Fire-and-forget safe: silently no-ops when
/// no model is active or when the LLM returns unparseable JSON.
///
/// Input: `(noteId, content, queryEmbedding)`. The embedding is reused from
/// the preceding [EmbedAndStoreNoteUseCase] step to avoid re-embedding the
/// note just to find similar ones.
@lazySingleton
class ExtractKnowledgeUseCase
    extends UseCase<void, (String, String, List<double>)> {
  final HasActiveLlmModelUseCase _hasModel;
  final GenerateOneShotUseCase _oneShot;
  final PromptBuilder _promptBuilder;
  final SearchVectorNotesUseCase _searchVector;
  final GraphRepository _graph;
  final MemoryRepository _memory;
  final PendingExtractionRepository _pending;

  ExtractKnowledgeUseCase(
    this._hasModel,
    this._oneShot,
    this._promptBuilder,
    this._searchVector,
    this._graph,
    this._memory,
    this._pending,
  );

  @override
  Future<void> call(
    (String, String, List<double>) input, {
    bool cached = false,
  }) async {
    final (noteId, content, queryVec) = input;
    final shortId = noteId.length > 8 ? noteId.substring(0, 8) : noteId;
    if (content.trim().isEmpty || queryVec.isEmpty) {
      debugPrint('⏭️ Extract: skip $shortId (empty content or vec)');
      return;
    }
    if (!await _hasModel.call()) {
      debugPrint('⏭️ Extract: skip $shortId (no active LLM backend)');
      return;
    }
    debugPrint('🔎 Extract: start $shortId');

    // Mark this note as pending before any LLM work. If the chat path preempts
    // us, the model crashes, or the app dies, the row survives and the Shiv
    // tab's close-time drainer will retry. Only deleted on a clean finish.
    try {
      await _pending.mark(noteId, content, queryVec);
    } catch (e) {
      debugPrint('⚠️ Extract: failed to mark pending $shortId: $e');
    }

    try {
      final similarResult = await _searchVector.call((queryVec, 5, 0.3, null));
      final similar = similarResult
          .fold<List<ScoredNote>>((_) => const [], (s) => s)
          .where((s) => s.noteId != noteId)
          .take(5)
          .toList();
      debugPrint('🔎 Extract: ${similar.length} similar notes as context');

      final prompt = _promptBuilder.buildExtractionPrompt(
        noteContent: content,
        similarNotes: similar,
      );
      debugPrint('🔎 Extract: calling LLM one-shot…');
      final oneShotResult = await _oneShot.call(
        GenerateOneShotInput(prompt: prompt, maxTokens: 2048),
      );
      final raw = oneShotResult.fold((_) => null, (r) => r);
      if (raw == null) {
        debugPrint('⚠️ Extract: LLM returned null (no active model or cancelled)');
        return;
      }
      debugPrint('🔎 Extract: LLM replied (${raw.length} chars)');

      final parsed = _parseExtractionJson(raw);
      if (parsed == null) {
        debugPrint('⚠️ Extract: unparseable LLM output. Raw snippet: '
            '${raw.length > 200 ? raw.substring(0, 200) : raw}');
        return;
      }
      debugPrint('🔎 Extract: parsed — concepts=${parsed.concepts.length} '
          'relations=${parsed.relations.length} keyPoints=${parsed.keyPoints.length}');

      await _persistExtraction(noteId, parsed);
      // Success — remove the pending row so the drainer won't retry.
      try {
        await _pending.clear(noteId);
      } catch (e) {
        debugPrint('⚠️ Extract: failed to clear pending $shortId: $e');
      }
      debugPrint('✅ Extract: persisted graph+memory for $shortId');
    } catch (e, st) {
      debugPrint('❌ Extract failed for $shortId: $e\n$st');
    }
  }

  Future<void> _persistExtraction(
    String noteId,
    _Extraction extraction,
  ) async {
    final now = DateTime.now();

    // Upsert nodes — lowercase key, original-cased name.
    for (final c in extraction.concepts) {
      final key = _normaliseKey(c);
      if (key.isEmpty) continue;
      await _graph.upsertNode(GraphNodeEntity(
        key: key,
        name: c.trim(),
        type: 'Concept',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Upsert edges — ensure both endpoints exist as nodes.
    for (final rel in extraction.relations) {
      final src = _normaliseKey(rel.source);
      final tgt = _normaliseKey(rel.target);
      final type = rel.type.trim().toLowerCase().replaceAll(' ', '_');
      if (src.isEmpty || tgt.isEmpty || type.isEmpty) continue;
      await _graph.upsertNode(GraphNodeEntity(
        key: src,
        name: rel.source.trim(),
        type: 'Concept',
        createdAt: now,
        updatedAt: now,
      ));
      await _graph.upsertNode(GraphNodeEntity(
        key: tgt,
        name: rel.target.trim(),
        type: 'Concept',
        createdAt: now,
        updatedAt: now,
      ));
      await _graph.upsertEdge(GraphEdgeEntity(
        sourceKey: src,
        targetKey: tgt,
        relationType: type,
        sourceNoteId: noteId,
        createdAt: now,
      ));
    }

    // Upsert MemoryNode.
    await _memory.upsert(MemoryNodeEntity(
      noteId: noteId,
      summary: extraction.summary,
      keyPoints: extraction.keyPoints,
      concepts: extraction.concepts.map(_normaliseKey).toList(),
      linkedNoteIds: extraction.links,
      updatedAt: now,
    ));
  }

  String _normaliseKey(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  /// Parses the LLM output into [_Extraction]. Returns null on any failure.
  /// Tolerates surrounding prose / markdown fences by scanning for the first
  /// '{' and last '}' and parsing that slice.
  ///
  /// Falls back to regex-based field extraction when the full JSON is invalid
  /// (e.g. malformed relation objects like `{"A","B","uses"}` that small models
  /// sometimes produce instead of `{"source":"A","target":"B","type":"uses"}`).
  _Extraction? _parseExtractionJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final slice = raw.substring(start, end + 1);

    // ── Fast path: valid JSON ────────────────────────────────────────────────
    try {
      final map = jsonDecode(slice) as Map<String, dynamic>;
      return _extractionFromMap(map);
    } catch (_) {
      // Fall through to repair path.
    }

    // ── Repair path: model emitted partially-invalid JSON ───────────────────
    // Extract only the well-formed relation objects via regex, reconstruct the
    // rest of the fields from a cleaned slice.
    try {
      final relations = _regexRelations(slice);
      final summary = _regexStringField(slice, 'summary') ?? '';
      final keyPoints = _regexStringArray(slice, 'keyPoints');
      final concepts = _regexStringArray(slice, 'concepts');
      final links = _regexStringArray(slice, 'links');
      if (summary.isEmpty && concepts.isEmpty && relations.isEmpty) return null;
      return _Extraction(
        summary: summary,
        keyPoints: keyPoints,
        concepts: concepts,
        relations: relations,
        links: links,
      );
    } catch (_) {
      return null;
    }
  }

  _Extraction? _extractionFromMap(Map<String, dynamic> map) {
    final summary = (map['summary'] as String?)?.trim() ?? '';
    final keyPoints = _stringList(map['keyPoints']);
    final concepts = _stringList(map['concepts']);
    final links = _stringList(map['links']);
    final relations = <_Relation>[];
    final rawRelations = map['relations'];
    if (rawRelations is List) {
      for (final r in rawRelations) {
        if (r is! Map) continue;
        final s = (r['source'] as String?)?.trim() ?? '';
        final t = (r['target'] as String?)?.trim() ?? '';
        final ty = (r['type'] as String?)?.trim() ?? '';
        if (s.isNotEmpty && t.isNotEmpty && ty.isNotEmpty) {
          relations.add(_Relation(source: s, target: t, type: ty));
        }
      }
    }
    if (summary.isEmpty && concepts.isEmpty && relations.isEmpty) return null;
    return _Extraction(
      summary: summary,
      keyPoints: keyPoints,
      concepts: concepts,
      relations: relations,
      links: links,
    );
  }

  /// Extracts only the well-formed relation objects: {"source":"…","target":"…","type":"…"}.
  /// Silently drops malformed objects like {"A","B","uses"}.
  List<_Relation> _regexRelations(String json) {
    final pattern = RegExp(
      r'\{\s*"source"\s*:\s*"([^"]+)"\s*,\s*"target"\s*:\s*"([^"]+)"\s*,\s*"type"\s*:\s*"([^"]+)"\s*\}',
    );
    return pattern
        .allMatches(json)
        .map((m) => _Relation(source: m.group(1)!, target: m.group(2)!, type: m.group(3)!))
        .toList();
  }

  /// Extracts a top-level string field value from a JSON string.
  String? _regexStringField(String json, String field) {
    final m = RegExp('"$field"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"').firstMatch(json);
    return m?.group(1);
  }

  /// Extracts a top-level string-array field from a JSON string.
  List<String> _regexStringArray(String json, String field) {
    final arrMatch = RegExp('"$field"\\s*:\\s*\\[([^\\]]*)\\]').firstMatch(json);
    if (arrMatch == null) return const [];
    final inner = arrMatch.group(1) ?? '';
    return RegExp(r'"((?:[^"\\]|\\.)*)"')
        .allMatches(inner)
        .map((m) => m.group(1)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class _Extraction {
  const _Extraction({
    required this.summary,
    required this.keyPoints,
    required this.concepts,
    required this.relations,
    required this.links,
  });
  final String summary;
  final List<String> keyPoints;
  final List<String> concepts;
  final List<_Relation> relations;
  final List<String> links;
}

class _Relation {
  const _Relation({
    required this.source,
    required this.target,
    required this.type,
  });
  final String source;
  final String target;
  final String type;
}

// ── Read-side use cases ─────────────────────────────────────────────────────

@lazySingleton
class GetMemoriesByNoteIdsUseCase
    extends UseCase<Either<Failure, List<MemoryNodeEntity>>, List<String>> {
  final MemoryRepository _memory;
  GetMemoriesByNoteIdsUseCase(this._memory);

  @override
  Future<Either<Failure, List<MemoryNodeEntity>>> call(
    List<String> input, {
    bool cached = false,
  }) =>
      _memory.getByNoteIds(input);
}

@lazySingleton
class GetGraphNeighboursUseCase
    extends UseCase<Either<Failure, List<GraphEdgeEntity>>, (List<String>, int)> {
  final GraphRepository _graph;
  GetGraphNeighboursUseCase(this._graph);

  @override
  Future<Either<Failure, List<GraphEdgeEntity>>> call(
    (List<String>, int) input, {
    bool cached = false,
  }) {
    final (keys, maxHops) = input;
    return _graph.getNeighbours(keys, maxHops: maxHops);
  }
}

@lazySingleton
class GetGraphNodesByKeysUseCase
    extends UseCase<Either<Failure, List<GraphNodeEntity>>, List<String>> {
  final GraphRepository _graph;
  GetGraphNodesByKeysUseCase(this._graph);

  @override
  Future<Either<Failure, List<GraphNodeEntity>>> call(
    List<String> keys, {
    bool cached = false,
  }) =>
      _graph.getNodesByKeys(keys);
}

/// Replays every pending extraction row through [ExtractKnowledgeUseCase].
/// Used by [ShivAIBloc.close] so any extraction that was preempted by chat is
/// rebuilt the moment the user leaves the AI tab.
@lazySingleton
class DrainPendingExtractionsUseCase extends NoParamsUseCase<void> {
  final PendingExtractionRepository _pending;
  final ExtractKnowledgeUseCase _extract;
  DrainPendingExtractionsUseCase(this._pending, this._extract);

  bool _running = false;

  @override
  Future<void> call() async {
    if (_running) return;
    _running = true;
    try {
      final items = await _pending.all();
      if (items.isEmpty) {
        debugPrint('🔁 Drain: no pending extractions');
        return;
      }
      debugPrint('🔁 Drain: replaying ${items.length} pending extraction(s)');
      for (final item in items) {
        // ExtractKnowledgeUseCase clears the row itself on success; on failure
        // it stays and gets retried next drain.
        await _extract.call((item.noteId, item.content, item.vec));
      }
    } catch (e, st) {
      debugPrint('❌ Drain failed: $e\n$st');
    } finally {
      _running = false;
    }
  }
}

@lazySingleton
class DeleteKnowledgeForNoteUseCase
    extends UseCase<Either<Failure, Unit>, String> {
  final GraphRepository _graph;
  final MemoryRepository _memory;
  DeleteKnowledgeForNoteUseCase(this._graph, this._memory);

  @override
  Future<Either<Failure, Unit>> call(
    String noteId, {
    bool cached = false,
  }) async {
    final g = await _graph.deleteForNote(noteId);
    if (g.isLeft()) return g;
    final m = await _memory.deleteByNoteId(noteId);
    if (m.isLeft()) return m;
    return const Right(unit);
  }
}
