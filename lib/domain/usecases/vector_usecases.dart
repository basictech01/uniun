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
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

@lazySingleton
class SearchVectorNotesUseCase
    extends
        UseCase<
          Either<Failure, List<ScoredNote>>,
          (List<double>, int, double)
        > {
  final VectorRepository _repository;

  SearchVectorNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ScoredNote>>> call(
    (List<double>, int, double) input, {
    bool cached = false,
  }) async {
    try {
      final (vec, topK, minScore) = input;
      final result = await _repository.search(
        vec,
        topK: topK,
        minScore: minScore,
      );
      return Right(result);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}

/// Next queued note, newest first, or null when nothing is waiting.
@lazySingleton
class NextPendingEmbeddingUseCase
    extends NoParamsUseCase<Either<Failure, PendingEmbeddingItem?>> {
  final PendingEmbeddingRepository _repository;

  NextPendingEmbeddingUseCase(this._repository);

  @override
  Future<Either<Failure, PendingEmbeddingItem?>> call() => _repository.next();
}

/// Counts one failed embed against a queued note; returns its attempts so far.
@lazySingleton
class RecordEmbeddingFailureUseCase
    extends UseCase<Either<Failure, int>, String> {
  final PendingEmbeddingRepository _repository;

  RecordEmbeddingFailureUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(String input, {bool cached = false}) =>
      _repository.recordFailure(input);
}

/// Removes a note from the embedding queue (its vector is stored, or it is
/// dropped after too many failures).
@lazySingleton
class RemovePendingEmbeddingUseCase
    extends UseCase<Either<Failure, Unit>, String> {
  final PendingEmbeddingRepository _repository;

  RemovePendingEmbeddingUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String input, {bool cached = false}) =>
      _repository.remove(input);
}

/// Stores a note's vector. Input: (eventId, vector). Throws when the vector
/// store fails, so the caller can tell a storage problem from a bad note.
@lazySingleton
class StoreNoteVectorUseCase extends UseCase<void, (String, List<double>)> {
  final VectorRepository _repository;

  StoreNoteVectorUseCase(this._repository);

  @override
  Future<void> call((String, List<double>) input, {bool cached = false}) =>
      _repository.upsert(input.$1, input.$2);
}

/// Queues a note for embedding; `NoteEmbeddingWorker` does the embedding, so a
/// kill or a failed embed does not lose the note.
///
/// Input: (eventId, raw nostr content). Media URLs are stripped (NIP-92
/// attachments put their URL in `content`) and a note with no text left is
/// skipped. Fire-and-forget safe: never throws.
@lazySingleton
class EmbedAndStoreNoteUseCase extends UseCase<void, (String, String)> {
  final PendingEmbeddingRepository _pending;
  final NoteEmbeddingTrigger _trigger;

  EmbedAndStoreNoteUseCase(this._pending, this._trigger);

  static final _urlPattern = RegExp(r'https?://\S+', caseSensitive: false);

  /// Below this many characters after stripping there is no signal worth a
  /// vector: punctuation, a single emoji, an empty caption.
  static const int _minEmbeddableChars = 4;

  @override
  Future<void> call((String, String) input, {bool cached = false}) async {
    final (eventId, rawContent) = input;
    final shortId = eventId.length > 8 ? eventId.substring(0, 8) : eventId;
    final text = rawContent.replaceAll(_urlPattern, '').trim();
    if (text.length < _minEmbeddableChars) {
      debugPrint('🧠 EmbedAndStore: skip note=$shortId (no embeddable text)');
      return;
    }
    final queued = await _pending.enqueue(eventId, text);
    queued.fold(
      (f) => debugPrint('❌ EmbedAndStore: could not queue $shortId: $f'),
      (_) => _trigger.nudge(),
    );
  }
}

/// Top-K PDF chunks most similar to a query vector, from the document store.
///
/// The document twin of [SearchVectorNotesUseCase]: same tuple input
/// `(vector, topK, minScore, queryText)`, separate store, so note retrieval is
/// unaffected.
@lazySingleton
class SearchDocumentChunksUseCase
    extends
        UseCase<
          Either<Failure, List<ScoredChunk>>,
          (List<double>, int, double, String?)
        > {
  final DocumentVectorRepository _repository;

  SearchDocumentChunksUseCase(this._repository);

  @override
  Future<Either<Failure, List<ScoredChunk>>> call(
    (List<double>, int, double, String?) input, {
    bool cached = false,
  }) async {
    try {
      final (vec, topK, minScore, queryText) = input;
      return Right(
        await _repository.search(
          vec,
          queryText: queryText,
          topK: topK,
          minScore: minScore,
        ),
      );
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
