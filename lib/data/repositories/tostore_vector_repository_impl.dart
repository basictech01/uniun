import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';

@LazySingleton(as: VectorRepository)
class TostoreVectorRepositoryImpl implements VectorRepository {
  final NoteVectorStore _store;
  final Isar _isar;

  TostoreVectorRepositoryImpl(this._store, this._isar);

  @override
  Future<void> upsert(String id, List<double> vector) async {
    if (vector.isEmpty) return;
    await _store.upsert(id, vector);
  }

  @override
  Future<void> delete(String id) => _store.delete(id);

  @override
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty) return const [];

    final hits = await _store.search(queryVector, topK: topK);
    debugPrint('🔍 Tostore.vectorSearch → ${hits.length} raw hit(s)');

    // Keep qualifying hits in score order, then resolve ALL their content in
    // two batch queries instead of 2×N sequential lookups (one saved + one own
    // query per hit). Same precedence (saved > own) and ordering as before.
    final qualified = [
      for (final h in hits)
        if (h.score >= minScore) h,
    ];
    final contentById = await _lookupContents(
      qualified.map((h) => h.id).toList(),
    );

    final results = <ScoredNote>[
      for (final h in qualified)
        if (contentById[h.id] != null)
          ScoredNote(noteId: h.id, score: h.score, content: contentById[h.id]!),
    ];
    debugPrint('🔍 Tostore ANN returning ${results.length} ScoredNote(s)');
    return results;
  }

  /// Resolve content for many eventIds in TWO batch queries (saved → own),
  /// precedence saved > own. Replaces the per-hit 2×N sequential lookups.
  Future<Map<String, String>> _lookupContents(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final wanted = ids.toSet();
    final out = <String, String>{};

    final saved = await _isar.savedNoteModels
        .filter()
        .removedAtIsNull()
        .anyOf(wanted, (q, id) => q.eventIdEqualTo(id))
        .findAll();
    for (final s in saved) {
      out.putIfAbsent(s.eventId, () => s.content);
    }

    final remaining = wanted.where((id) => !out.containsKey(id)).toSet();
    if (remaining.isNotEmpty) {
      final own = await _isar.noteModels
          .filter()
          .anyOf(remaining, (q, id) => q.eventIdEqualTo(id))
          .findAll();
      for (final n in own) {
        out.putIfAbsent(n.eventId, () => n.content);
      }
    }
    return out;
  }
}
