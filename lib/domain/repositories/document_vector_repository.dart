import 'package:uniun/domain/entities/shiv/scored_chunk.dart';

/// Vector storage and similarity search over document chunks.
///
/// Sibling of `VectorRepository` (notes), deliberately separate so the note
/// retrieval path is untouched by document indexing.
///
/// Vectors live on the chunk rows (`DocumentChunkModel.vector`) and [search] is
/// an exact comparison against every one, so a stored chunk is always
/// reachable and purging a document's rows removes its vectors with them.
/// (The approximate index this replaced could reach only 24 % of 83 chunks.)
abstract class DocumentVectorRepository {
  /// Attach [vector] to the already-written chunk row [chunkId] (see
  /// `chunkIdOf`), replacing any earlier one. A no-op when the row is gone — the
  /// chunk was purged while it was being embedded.
  Future<void> upsert(String chunkId, List<double> vector);

  /// Up to [topK] chunks whose cosine similarity to [queryVector] is at least
  /// [minScore], best first, with their text and page label resolved from Isar.
  ///
  /// With [queryText], the ranking also weighs exact words (BM25): a chunk that
  /// contains the question's rare words — a number, a name — rises even when
  /// its meaning-based score is modest. Without it, ranking is by meaning
  /// alone. [ScoredChunk.score] is always the cosine similarity.
  Future<List<ScoredChunk>> search(
    List<double> queryVector, {
    String? queryText,
    int topK = 3,
    double minScore = 0.3,
  });
}
