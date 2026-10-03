import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';

/// Retrieves the top-K notes, and separately the top-K PDF chunks, most
/// semantically similar to a query vector.
///
/// Delegates to [SearchVectorNotesUseCase] — the underlying storage
/// (currently Tostore) is an implementation detail of [VectorRepository].
@lazySingleton
class VectorSearchService {
  final SearchVectorNotesUseCase _searchUseCase;
  final SearchDocumentChunksUseCase _chunkSearchUseCase;

  VectorSearchService(this._searchUseCase, this._chunkSearchUseCase);

  Future<List<ScoredNote>> search({
    required List<double> queryVector,
    int topK = 5,
    double minScore = 0.3,
  }) async {
    final result = await _searchUseCase((queryVector, topK, minScore));
    return result.fold(
      (failure) => [],
      (notes) => notes,
    );
  }

  /// Top-K PDF chunks most similar to [queryVector].
  ///
  /// Independent of [search] — separate store, separate top-K — so note
  /// retrieval is unchanged by document indexing.
  ///
  /// [queryText], when given, also ranks by the question's exact words.
  Future<List<ScoredChunk>> searchChunks({
    required List<double> queryVector,
    String? queryText,
    int topK = 3,
    double minScore = 0.3,
  }) async {
    final result = await _chunkSearchUseCase(
      (queryVector, topK, minScore, queryText),
    );
    return result.fold((failure) => [], (chunks) => chunks);
  }
}
