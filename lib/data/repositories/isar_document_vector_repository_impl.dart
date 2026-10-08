import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/text/hybrid_ranker.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';

/// Document chunk vectors stored on the chunk rows themselves, searched by an
/// exact scan.
///
/// An approximate index (ToStore's graph) cannot reach every stored vector —
/// on a phone only 20 of 83 chunks found themselves — so a stored chunk could
/// never come back for any question. Comparing the query with every vector is
/// exact, and cheap at this scale: a few thousand 768-dim vectors is a few
/// milliseconds of arithmetic.
@LazySingleton(as: DocumentVectorRepository)
class IsarDocumentVectorRepositoryImpl implements DocumentVectorRepository {
  IsarDocumentVectorRepositoryImpl(this._isar) : _config = const HybridConfig();

  /// For measuring other settings on a device; the app uses the default.
  @visibleForTesting
  IsarDocumentVectorRepositoryImpl.tuned(this._isar, this._config);

  final Isar _isar;
  final HybridConfig _config;

  /// Rows read per step, so a large library is never held in memory whole.
  static const int _batch = 400;

  @override
  Future<void> upsert(String chunkId, List<double> vector) async {
    if (vector.isEmpty) return;
    final ref = parseChunkId(chunkId);
    if (ref == null) return;
    await _isar.writeTxn(() async {
      final row = await _isar.documentChunkModels
          .where()
          .sha256OrdinalEqualTo(ref.sha256, ref.ordinal)
          .findFirst();
      // The chunk was purged while it was being embedded: nothing to attach to.
      if (row == null) return;
      await _isar.documentChunkModels.put(row..vector = vector);
    });
  }

  @override
  Future<List<ScoredChunk>> search(
    List<double> queryVector, {
    String? queryText,
    int topK = 3,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty || topK <= 0) return const [];
    final ranker = HybridRanker(
      queryVector,
      queryText: queryText,
      config: _config,
      minScore: minScore,
    );
    for (var offset = 0; ; offset += _batch) {
      final rows = await _isar.documentChunkModels
          .where()
          .offset(offset)
          .limit(_batch)
          .findAll();
      if (rows.isEmpty) break;
      for (final row in rows) {
        ranker.add(row.id, row.vector, row.text);
      }
    }

    final results = <ScoredChunk>[];
    // One index lookup per document, not per hit.
    final kinds = <String, DocumentKind?>{};
    for (final id in ranker.ranked()) {
      if (results.length == topK) break;
      final row = await _isar.documentChunkModels.get(id);
      if (row == null) continue;
      final kind = kinds[row.sha256] ??=
          (await _isar.documentIndexModels.getBySha256(row.sha256))?.kind;
      // No index row: the document is mid-index or mid-purge, so its chunks
      // are not yet (or no longer) citable.
      if (kind == null) continue;
      results.add(
        ScoredChunk(
          chunkId: chunkIdOf(row.sha256, row.ordinal),
          sha256: row.sha256,
          kind: kind,
          label: row.label,
          score: ranker.cosines[id]!,
          content: row.text,
        ),
      );
    }
    return results;
  }
}
