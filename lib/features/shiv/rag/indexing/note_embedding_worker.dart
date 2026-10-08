import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

/// Embeds the notes waiting in the pending-embeddings table, one at a time and
/// newest first, then hands each vector to knowledge extraction.
///
/// A row is deleted only after its vector is stored, so a kill, a crash or an
/// embedder that is not ready loses nothing. Main isolate only, while the app
/// is open: the embedder already runs in the plugin's own worker isolate.
///
/// One note at a time because batching and two-at-a-time measured no faster
/// (~11.5 s a note on a Snapdragon 710, whatever the text length). Waits while
/// a Shiv chat reply is being generated.
@LazySingleton(as: NoteEmbeddingTrigger)
class NoteEmbeddingWorker implements NoteEmbeddingTrigger {
  NoteEmbeddingWorker(
    this._nextPending,
    this._recordFailure,
    this._removePending,
    this._embedding,
    this._storeVector,
    this._extract,
    this._scheduler,
  );

  final NextPendingEmbeddingUseCase _nextPending;
  final RecordEmbeddingFailureUseCase _recordFailure;
  final RemovePendingEmbeddingUseCase _removePending;
  final EmbeddingService _embedding;
  final StoreNoteVectorUseCase _storeVector;
  final ExtractKnowledgeUseCase _extract;
  final InferenceScheduler _scheduler;

  /// A note that fails this many times is dropped so it cannot block the rest.
  static const int maxAttempts = 3;

  static const Duration retryDelay = Duration(minutes: 5);

  @visibleForTesting
  static Duration chatPollInterval = const Duration(seconds: 2);

  bool _running = false;

  @visibleForTesting
  bool get isRunning => _running;
  bool _again = false;
  Timer? _retry;

  /// Starts a pass, or asks the running one to look again when it finishes.
  @override
  void nudge() {
    if (_running) {
      _again = true;
      return;
    }
    unawaited(_run());
  }

  Future<void> _run() async {
    _running = true;
    _retry?.cancel();
    _retry = null;
    try {
      do {
        _again = false;
        if (await _drain()) {
          _retry = Timer(retryDelay, nudge);
          return;
        }
      } while (_again);
    } catch (e, st) {
      debugPrint('❌ NoteEmbeddingWorker pass failed: $e\n$st');
      _retry = Timer(retryDelay, nudge);
    } finally {
      _running = false;
    }
  }

  /// Embeds queued notes until the table is empty. True when it stopped early
  /// and should be retried later.
  Future<bool> _drain() async {
    while (true) {
      final queued = await _nextPending.call();
      final item = queued.fold<PendingEmbeddingItem?>((f) {
        debugPrint('❌ NoteEmbeddingWorker: cannot read the queue: $f');
        return null;
      }, (i) => i);
      if (item == null) return queued.isLeft();

      final shortId = item.eventId.length > 8
          ? item.eventId.substring(0, 8)
          : item.eventId;
      while (_scheduler.isChatRunning) {
        await Future<void>.delayed(chatPollInterval);
      }
      final List<double> vec;
      try {
        // `embed` answers [] both when the model is not loaded (try later, keep
        // the note) and when it failed on this text (count it, or one bad note
        // would block the queue).
        vec = await _embedding.embed(item.text, isDocument: true);
        if (vec.isEmpty) {
          if (!_embedding.isReady) {
            debugPrint(
              '⚠️ NoteEmbeddingWorker: embedder not ready, keeping '
              '$shortId and stopping',
            );
            return true;
          }
          throw StateError('the embedder returned no vector for this note');
        }
      } catch (e, st) {
        final attempts = (await _recordFailure.call(
          item.eventId,
        )).getOrElse(() => 0);
        debugPrint(
          '❌ NoteEmbeddingWorker: $shortId failed '
          '($attempts/$maxAttempts): $e\n$st',
        );
        if (attempts < maxAttempts) return true;
        await _removePending.call(item.eventId);
        debugPrint(
          '🗑️ NoteEmbeddingWorker: dropped $shortId after '
          '$maxAttempts failures',
        );
        continue;
      }

      try {
        await _storeVector.call((item.eventId, vec));
      } catch (e) {
        // A storage problem is not this note's fault: keep it, don't count it,
        // and try again later.
        debugPrint(
          '⚠️ NoteEmbeddingWorker: vector store failed, keeping $shortId '
          'and stopping: $e',
        );
        return true;
      }
      // Row removed last: a crash between the two just embeds it again.
      (await _removePending.call(item.eventId)).leftMap(
        (f) =>
            debugPrint('⚠️ NoteEmbeddingWorker: could not clear $shortId: $f'),
      );
      debugPrint('✅ NoteEmbeddingWorker: embedded $shortId');
      unawaited(_extract.call((item.eventId, item.text, vec)));
    }
  }
}
