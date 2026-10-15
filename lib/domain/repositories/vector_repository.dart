import 'package:uniun/domain/entities/shiv/scored_note.dart';

/// Abstract contract for vector storage and similarity search.
///
/// The current implementation ([IsarVectorRepositoryImpl]) stores vectors
/// in-line with [SavedNoteModel] and [NoteModel] in Isar and performs
/// brute-force cosine similarity in memory.
///
/// When switching to a dedicated vector DB (e.g. tostore), only this
/// implementation changes — nothing above it is affected.
abstract class VectorRepository {
  /// Store or update the embedding vector for [id].
  /// Covers both saved (bookmarked) notes and own authored notes.
  Future<void> upsert(String id, List<double> vector);

  /// Remove the embedding vector for [id] (e.g. when a note is unsaved).
  Future<void> delete(String id);

  /// Return up to [topK] notes whose cosine similarity to [queryVector]
  /// is at or above [minScore], sorted highest-first. When [allowedNoteIds]
  /// is provided, only those notes compete for top-K.
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
    Set<String>? allowedNoteIds,
  });
}
