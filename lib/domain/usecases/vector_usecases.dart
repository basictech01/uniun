import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/services/note_embedding_worker.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

@lazySingleton
class SearchVectorNotesUseCase
    extends UseCase<Either<Failure, List<ScoredNote>>, (List<double>, int, double)> {
  final VectorRepository _repository;

  SearchVectorNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ScoredNote>>> call(
      (List<double>, int, double) input,
      {bool cached = false}) async {
    try {
      final (vec, topK, minScore) = input;
      final result = await _repository.search(vec, topK: topK, minScore: minScore);
      return Right(result);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}

/// Queues a note for embedding. Callers never touch the embedder or the vector
/// store: the note goes into the pending-embeddings table and
/// `NoteEmbeddingWorker` embeds it, so a crash, a kill or a failed embed does
/// not lose it.
///
/// Input: (eventId, raw nostr content) tuple. The use case strips media URLs
/// (NIP-92 attachments embed their URL into `content`) and skips entirely
/// when no text remains — image-only / video-only notes have nothing
/// meaningful to embed for RAG.
///
/// Fire-and-forget safe — returns void and never throws.
@lazySingleton
class EmbedAndStoreNoteUseCase extends UseCase<void, (String, String)> {
  final PendingEmbeddingRepository _pending;
  final NoteEmbeddingWorker _worker;

  EmbedAndStoreNoteUseCase(this._pending, this._worker);

  /// Strips http(s) URLs from `content`. Media notes carry their blob URL
  /// inline; embedding it produces a useless vector. A typed caption like
  /// "check this article: https://…" survives with the prose intact.
  static final _urlPattern = RegExp(r'https?://\S+', caseSensitive: false);

  /// Below this many post-strip characters there is no signal worth a
  /// vector — punctuation, single emojis, or empty captions all skip.
  static const int _minEmbeddableChars = 4;

  @override
  Future<void> call((String, String) input, {bool cached = false}) async {
    final (eventId, rawContent) = input;
    final shortId = eventId.length > 8 ? eventId.substring(0, 8) : eventId;
    final text = rawContent.replaceAll(_urlPattern, '').trim();
    if (text.length < _minEmbeddableChars) {
      debugPrint('🧠 EmbedAndStore: skip note=$shortId (no embeddable text — '
          'media-only or empty after URL strip)');
      return;
    }
    try {
      await _pending.enqueue(eventId, text);
      _worker.nudge();
    } catch (e, st) {
      debugPrint('❌ EmbedAndStore: could not queue $shortId: $e\n$st');
    }
  }
}

/// Top-K PDF chunks most similar to a query vector, from the document store.
///
/// The document twin of [SearchVectorNotesUseCase]: same tuple input
/// `(vector, topK, minScore, queryText)`, separate store, so note retrieval is
/// unaffected.
@lazySingleton
class SearchDocumentChunksUseCase extends UseCase<
    Either<Failure, List<ScoredChunk>>,
        (List<double>, int, double, String?)> {
  final DocumentVectorRepository _repository;

  SearchDocumentChunksUseCase(this._repository);

  @override
  Future<Either<Failure, List<ScoredChunk>>> call(
    (List<double>, int, double, String?) input, {
    bool cached = false,
  }) async {
    try {
      final (vec, topK, minScore, queryText) = input;
      return Right(await _repository.search(
        vec,
        queryText: queryText,
        topK: topK,
        minScore: minScore,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}

/// Embeds one PDF chunk and stores its vector against `chunkId`.
///
/// The document twin of [EmbedAndStoreNoteUseCase], kept separate rather than
/// branching inside it: a chunk needs no URL stripping (it is extracted prose,
/// not user-typed content carrying a blob URL), goes to the document store, and
/// asserts no knowledge-graph edges — `ExtractKnowledgeUseCase` is about notes.
///
/// Returns whether the vector was stored. `false` means the embedder was not
/// ready, which the caller must treat as "retry later", NOT as "this document
/// has no text" — [EmbeddingService.embed] answers `[]` instead of throwing.
///
/// The embed goes through [EmbeddingQueue] inside [EmbeddingService], one at a
/// time at background priority, so a document yielding dozens of chunks cannot
/// storm the CPU or hold up a Shiv question.
@lazySingleton
class EmbedAndStoreChunkUseCase extends UseCase<bool, (String, String)> {
  final EmbeddingService _embedding;
  final DocumentVectorRepository _vector;

  EmbedAndStoreChunkUseCase(this._embedding, this._vector);

  @override
  Future<bool> call((String, String) input, {bool cached = false}) async {
    final (chunkId, text) = input;
    try {
      final vec = await _embedding.embed(text, isDocument: true);
      if (vec.isEmpty) return false;
      await _vector.upsert(chunkId, vec);
      return true;
    } catch (e) {
      debugPrint('❌ EmbedAndStoreChunk failed for $chunkId: $e');
      return false;
    }
  }
}
