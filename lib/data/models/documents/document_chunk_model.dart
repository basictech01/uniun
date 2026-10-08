import 'package:isar_community/isar.dart';

part 'document_chunk_model.g.dart';

/// One retrievable piece of an indexed document.
///
/// RAG infrastructure, not a Note — it sits beside `MemoryNodeModel`, so the
/// one-Note-collection rule is untouched. The chunk's embedding
/// is stored beside its text as [vector], so a question is answered by an exact
/// comparison against every chunk — an approximate index cannot reach every
/// stored vector (measured: 24 % of 83 chunks found themselves).
@Collection(ignore: {'copyWith'})
@Name('DocumentChunk')
class DocumentChunkModel {
  Id id = Isar.autoIncrement;

  /// The blob's SHA-256 — joins to [MediaCacheModel.sha256].
  @Index(composite: [CompositeIndex('ordinal')], unique: true, replace: true)
  late String sha256;

  /// Position across the whole document, `0..n-1`.
  late int ordinal;

  /// Where the chunk came from — the 1-based page of a PDF, the heading above
  /// it in a DOCX, `''` when there is none — so a citation can be verified.
  late String label;

  late String text;

  /// The embedding, stored as 32-bit floats (3 KB for 768 dimensions), or
  /// `null` until the chunk has been embedded — a chunk with no vector is
  /// never returned by search.
  List<float>? vector;
}
