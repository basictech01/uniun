import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/data/models/manas_note_link_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';

/// One note prepared for prompt packing. Source-agnostic — saved, own, and
/// draft notes are all flattened to this shape after resolution.
class PackedNote {
  final String id;
  final String content;
  final DateTime created;
  final PackedNoteSource source;

  const PackedNote({
    required this.id,
    required this.content,
    required this.created,
    required this.source,
  });
}

enum PackedNoteSource { saved, own, draft }

/// Resolves a multi-Manas membership set into a token-budgeted list of
/// packed notes for prompt construction.
///
/// ## Isolate note (why this is NOT an Isar-holding singleton)
/// The background Gana WorkManager dispatcher
/// (`gana_workmanager.dart`) runs in its OWN isolate with its OWN `Isar`
/// handle and no get_it. So `isar` is always a **method parameter**, never an
/// injected field — both isolates pass their own handle. The relevance path
/// (vector search) is main-isolate only and uses the injected
/// [EmbeddingService] / [VectorSearchService]; the background isolate only
/// ever calls the **static** newest-first / pool loaders, which need no
/// services.
///
/// Two ranking modes for [merge]:
///   • **By relevance** — when `relevanceQuery` is non-null/non-empty. The
///     query is embedded, the vector index searched, and hits intersected
///     with the Manas membership set. Best for reactive Ganas responding to a
///     specific input message.
///   • **Newest-first** — fallback / standalone Ganas with no input to rank
///     against (and the only mode reachable from the background isolate).
@lazySingleton
class ManasContextLoader {
  ManasContextLoader(this._isar, this._embedder, this._searcher);

  /// The main-isolate Isar singleton, used by the instance [merge] so callers
  /// (cubits, engines) don't pass it. The background isolate has its own Isar
  /// and uses the STATIC loaders ([packNewest]/[loadPool]/[loadAll]) instead.
  final Isar _isar;
  final EmbeddingService _embedder;
  final VectorSearchService _searcher;

  /// Most tokenizers average ~4 chars / token for English. Pad with a
  /// 15% safety margin to absorb prompt overhead (headers, separators).
  static const int _charsPerTokenEstimate = 4;
  static const double _safetyMargin = 0.85;

  /// How many vector hits to consider before intersecting with the Manas
  /// set. The intersection can be small, so we pull a generous pool.
  static const int _vectorPoolSize = 50;

  // ── Main-isolate entry (relevance-aware) ───────────────────────────────────

  /// Build the context for a Gana on the main isolate. Set semantics: a note
  /// in multiple requested Manases is included once.
  ///
  /// [budget] is in tokens. [relevanceQuery] (optional) ranks Manas notes by
  /// cosine similarity to this text; when null, falls back to newest-first.
  Future<List<PackedNote>> merge({
    required List<String> manasIds,
    required int budget,
    String? relevanceQuery,
  }) async {
    if (manasIds.isEmpty || budget <= 0) return const [];

    final charBudget = (budget * _charsPerTokenEstimate * _safetyMargin).floor();
    final unique = await _noteIdsForManases(_isar, manasIds);
    if (unique.isEmpty) return const [];

    if (relevanceQuery != null && relevanceQuery.trim().isNotEmpty) {
      final byRelevance = await _packByRelevance(
        isar: _isar,
        query: relevanceQuery,
        allowedNoteIds: unique,
        charBudget: charBudget,
      );
      if (byRelevance != null) return byRelevance;
      // Embedder/vector unavailable → fall through to newest-first.
    }

    return _packNewestFromIds(isar: _isar, noteIds: unique, charBudget: charBudget);
  }

  /// Pack the whole Brahma knowledge base for a foreground Gana run.
  Future<List<PackedNote>> mergeAll({
    required String selfPubkey,
    required int budget,
    String? relevanceQuery,
  }) async {
    if (budget <= 0) return const [];
    final all = await loadAll(isar: _isar, selfPubkey: selfPubkey);
    if (all.isEmpty) return const [];
    final charBudget = (budget * _charsPerTokenEstimate * _safetyMargin)
        .floor();
    if (relevanceQuery != null && relevanceQuery.trim().isNotEmpty) {
      final byRelevance = await _packByRelevance(
        isar: _isar,
        query: relevanceQuery,
        allowedNoteIds: all.map((n) => n.id).toSet(),
        charBudget: charBudget,
      );
      if (byRelevance != null) return byRelevance;
    }
    all.sort((a, b) => b.created.compareTo(a.created));
    return _packUnderBudget(all, charBudget);
  }

  /// Relevance-rank over the WHOLE vector index (no Manas filter) — the
  /// "All notes" scope of the composer-chat / Shiv chat. Returns up to [topK]
  /// packed notes ranked by similarity to [query]. Empty if the embedder or
  /// vector index isn't ready.
  Future<List<PackedNote>> searchAll({
    required String query,
    int topK = 6,
  }) async {
    if (query.trim().isEmpty) return const [];
    try {
      final vec = await _embedder.embed(query);
      if (vec.isEmpty) return const [];
      final hits = await _searcher.search(queryVector: vec, topK: topK);
      return [
        for (final h in hits)
          PackedNote(
            id: h.noteId,
            content: h.content,
            // `created` is unused by the chat prompt; the vector hit carries no
            // timestamp, so stamp it now (the order is already by score).
            created: DateTime.now(),
            source: PackedNoteSource.own,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<PackedNote>?> _packByRelevance({
    required Isar isar,
    required String query,
    required Set<String> allowedNoteIds,
    required int charBudget,
  }) async {
    try {
      // `embed()` lazily calls `init()` internally if not ready.
      final vec = await _embedder.embed(query);
      if (vec.isEmpty) return null;

      final hits = await _searcher.search(
        queryVector: vec,
        topK: _vectorPoolSize,
        minScore: 0.0, // filter by Manas membership, not score
      );
      if (hits.isEmpty) return null;

      // Intersect with the Manas set, preserving search order (score desc),
      // then resolve all survivors in a single batch.
      final orderedIds = <String>[];
      final seen = <String>{};
      for (final h in hits) {
        if (!allowedNoteIds.contains(h.noteId)) continue;
        if (seen.add(h.noteId)) orderedIds.add(h.noteId);
      }
      if (orderedIds.isEmpty) return null;

      final byId = await _resolveMany(isar, orderedIds);
      final ordered = [
        for (final id in orderedIds)
          if (byId[id] != null) byId[id]!,
      ];
      return _packUnderBudget(ordered, charBudget);
    } catch (e, st) {
      // Vector path is best-effort. Any failure (no embedder, no index yet,
      // etc.) falls back to newest-first.
      debugPrint('ManasContextLoader: vector retrieval failed, falling '
          'back to newest-first: $e\n$st');
      return null;
    }
  }

  // ── Background-isolate-safe statics (no services needed) ────────────────────

  /// Newest-first packing for the union of [manasIds] under a token [budget].
  /// The only mode the background Gana isolate uses (no relevance query).
  static Future<List<PackedNote>> packNewest({
    required Isar isar,
    required List<String> manasIds,
    required int budget,
  }) async {
    if (manasIds.isEmpty || budget <= 0) return const [];
    final charBudget = (budget * _charsPerTokenEstimate * _safetyMargin).floor();
    final unique = await _noteIdsForManases(isar, manasIds);
    if (unique.isEmpty) return const [];
    return _packNewestFromIds(isar: isar, noteIds: unique, charBudget: charBudget);
  }

  /// Pack the whole Brahma knowledge base in the background isolate.
  static Future<List<PackedNote>> packAllNewest({
    required Isar isar,
    required String selfPubkey,
    required int budget,
  }) async {
    if (budget <= 0) return const [];
    final all = await loadAll(isar: isar, selfPubkey: selfPubkey);
    all.sort((a, b) => b.created.compareTo(a.created));
    final charBudget = (budget * _charsPerTokenEstimate * _safetyMargin)
        .floor();
    return _packUnderBudget(all, charBudget);
  }

  /// Full note pool (no ranking, no token budget) for the union of [manasIds].
  /// Used by Nataraj to randomly sample combinations. Dedupes across manases.
  static Future<List<PackedNote>> loadPool({
    required Isar isar,
    required List<String> manasIds,
  }) async {
    final unique = await _noteIdsForManases(isar, manasIds);
    if (unique.isEmpty) return const [];
    final byId = await _resolveMany(isar, unique.toList());
    return byId.values.toList();
  }

  /// The whole Brahma knowledge base: saved notes + the user's own notes
  /// ([selfPubkey]) + drafts + every Manas-linked note. Used by Nataraj's
  /// "All notes" scope. Dedupes by id.
  static Future<List<PackedNote>> loadAll({
    required Isar isar,
    required String selfPubkey,
  }) async {
    final out = <PackedNote>[];
    final seen = <String>{};
    void add(PackedNote p) {
      if (seen.add(p.id)) out.add(p);
    }

    final saved =
        await isar.savedNoteModels.filter().removedAtIsNull().findAll();
    for (final s in saved) {
      add(PackedNote(
        id: s.eventId,
        content: s.content,
        created: s.created,
        source: PackedNoteSource.saved,
      ));
    }
    final own = await isar.noteModels
        .filter()
        .authorPubkeyEqualTo(selfPubkey)
        .kindEqualTo(kNoteKind)
        .findAll();
    for (final n in own) {
      add(PackedNote(
        id: n.eventId,
        content: n.content,
        created: n.created,
        source: PackedNoteSource.own,
      ));
    }
    final drafts = await isar.draftModels.where().findAll();
    for (final d in drafts) {
      add(PackedNote(
        id: d.draftId,
        content: d.content,
        created: d.createdAt,
        source: PackedNoteSource.draft,
      ));
    }
    // Also include every note grouped into ANY Manas — a Manas can hold notes
    // the user didn't author, so "All notes" must be a true superset of every
    // scope (else those scopes spark cards but "All notes" reports < 2).
    // Tombstoned edges are excluded — a "remove note from Manas" mesh event
    // means the user no longer wants the note grouped there.
    final linkIds = (await isar.manasNoteLinkModels
            .filter()
            .removedAtIsNull()
            .findAll())
        .map((l) => l.noteId)
        .toList();
    final byId = await _resolveMany(isar, linkIds);
    byId.values.forEach(add);
    return out;
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  /// Union of note ids across all selected Manases.
  static Future<Set<String>> _noteIdsForManases(
    Isar isar,
    List<String> manasIds,
  ) async {
    if (manasIds.isEmpty) return const {};
    final links = await isar.manasNoteLinkModels
        .filter()
        .anyOf(manasIds, (q, id) => q.manasIdEqualTo(id))
        .and()
        .removedAtIsNull()
        .findAll();
    return links.map((l) => l.noteId).toSet();
  }

  static Future<List<PackedNote>> _packNewestFromIds({
    required Isar isar,
    required Set<String> noteIds,
    required int charBudget,
  }) async {
    final byId = await _resolveMany(isar, noteIds.toList());
    final resolved = byId.values.toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    return _packUnderBudget(resolved, charBudget);
  }

  /// Keep high-priority (already-ordered) notes first; skip oversize entries
  /// rather than truncate (truncation changes meaning).
  static List<PackedNote> _packUnderBudget(
    List<PackedNote> ordered,
    int charBudget,
  ) {
    final packed = <PackedNote>[];
    var used = 0;
    for (final n in ordered) {
      final cost = n.content.length;
      if (used + cost > charBudget) continue;
      packed.add(n);
      used += cost;
    }
    return packed;
  }

  /// Resolve many note ids in **3 batch queries** (saved → own → draft) instead
  /// of 3×N sequential lookups. Precedence saved > own > draft matches the old
  /// per-note resolution order. Returns a map keyed by id.
  static Future<Map<String, PackedNote>> _resolveMany(
    Isar isar,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final wanted = ids.toSet();
    final out = <String, PackedNote>{};

    final saved = await isar.savedNoteModels
        .filter()
        .removedAtIsNull()
        .anyOf(wanted, (q, id) => q.eventIdEqualTo(id))
        .findAll();
    for (final s in saved) {
      out.putIfAbsent(
        s.eventId,
        () => PackedNote(
          id: s.eventId,
          content: s.content,
          created: s.created,
          source: PackedNoteSource.saved,
        ),
      );
    }

    final remainingOwn = wanted.where((id) => !out.containsKey(id)).toSet();
    if (remainingOwn.isNotEmpty) {
      final own = await isar.noteModels
          .filter()
          .anyOf(remainingOwn, (q, id) => q.eventIdEqualTo(id))
          .findAll();
      for (final n in own) {
        out.putIfAbsent(
          n.eventId,
          () => PackedNote(
            id: n.eventId,
            content: n.content,
            created: n.created,
            source: PackedNoteSource.own,
          ),
        );
      }
    }

    final remainingDraft = wanted.where((id) => !out.containsKey(id)).toSet();
    if (remainingDraft.isNotEmpty) {
      final drafts = await isar.draftModels
          .filter()
          .anyOf(remainingDraft, (q, id) => q.draftIdEqualTo(id))
          .findAll();
      for (final d in drafts) {
        out.putIfAbsent(
          d.draftId,
          () => PackedNote(
            id: d.draftId,
            content: d.content,
            created: d.createdAt,
            source: PackedNoteSource.draft,
          ),
        );
      }
    }

    return out;
  }
}
