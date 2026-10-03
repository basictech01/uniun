import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';

/// In-memory [DocumentVectorRepository]: records writes and the last query,
/// returns a preset search result.
class FakeDocumentVectors implements DocumentVectorRepository {
  final Map<String, List<double>> stored = {};

  List<ScoredChunk> searchResult = const [];

  /// Last query [search] was called with, or null if never.
  List<double>? lastQuery;
  String? lastQueryText;
  int? lastTopK;

  @override
  Future<void> upsert(String chunkId, List<double> vector) async =>
      stored[chunkId] = vector;

  @override
  Future<List<ScoredChunk>> search(
    List<double> queryVector, {
    String? queryText,
    int topK = 3,
    double minScore = 0.3,
  }) async {
    lastQuery = queryVector;
    lastQueryText = queryText;
    lastTopK = topK;
    return searchResult;
  }
}
