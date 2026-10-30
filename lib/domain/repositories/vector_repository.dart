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
  /// Store the embedding vectors of note [noteId], replacing any it had. A
  /// short note has one; a long note has one per piece, first piece first.
  /// Covers both saved (bookmarked) notes and own authored notes.
  Future<void> upsertNote(String noteId, List<List<double>> vectors);

  /// Remove every vector of note [noteId], pieces included (e.g. when a note
  /// is deleted).
  Future<void> delete(String noteId);

  /// Return up to [topK] notes whose best piece has cosine similarity to
  /// [queryVector] at or above [minScore], sorted highest-first, each note
  /// once. When [allowedNoteIds] is provided, only those notes compete.
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
    Set<String>? allowedNoteIds,
  });
}
