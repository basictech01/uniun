import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

/// Embeds the notes in the pending-embeddings table, one at a time.
///
/// Notes are queued when they are saved or published (see
/// `EmbedAndStoreNoteUseCase`), so nothing is lost if the app dies or the
/// embedder is not ready: the row stays until the vector is stored. With an
/// empty table a pass is one cheap query. There is no background isolate — the
/// embedder already runs in the plugin's own worker isolate — and the pass only
/// runs while the app is open; rows wait for the next launch otherwise.
///
/// While a Shiv chat reply is being generated the worker waits (it checks
/// `InferenceScheduler.isChatRunning` before each note), so embedding never
/// competes with the answer the user is reading.
///
/// One note at a time on purpose. The plugin serves `generateEmbeddings` as one
/// request per text, so batching is no faster (measured: 4 notes, one at a time,
/// two at a time and batched all took ~11.5 s per note on a Snapdragon 710).
@lazySingleton
class NoteEmbeddingWorker {
  NoteEmbeddingWorker(
    this._pending,
    this._embedding,
    this._vector,
    this._extract,
    this._scheduler,
  );

  final PendingEmbeddingRepository _pending;
  final EmbeddingService _embedding;
  final VectorRepository _vector;
  final ExtractKnowledgeUseCase _extract;
  final InferenceScheduler _scheduler;

  /// A note that throws this many times is dropped so it cannot block the rest.
  static const int maxAttempts = 3;

  /// How long to wait before trying again after the embedder was not ready.
  static const Duration retryDelay = Duration(minutes: 5);

  /// How often to look again while a Shiv chat reply is being generated.
  @visibleForTesting
  static Duration chatPollInterval = const Duration(seconds: 2);

  bool _running = false;
  bool _again = false;
  Timer? _retry;

  /// Starts a pass, or asks the running one to look again when it finishes.
  /// Safe to call as often as notes are queued: passes never overlap.
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

  /// Embeds queued notes until the table is empty. Returns true when it had to
  /// stop early and the rows should be retried later.
  Future<bool> _drain() async {
    while (true) {
      final item = await _pending.next();
      if (item == null) return false;
      final shortId =
          item.eventId.length > 8 ? item.eventId.substring(0, 8) : item.eventId;
      // An embed saturates the CPU for seconds on a weak phone: stand down while
      // the user is reading a Shiv reply being generated. Only chat — a Gana or
      // extraction job must not hold notes back for minutes.
      while (_scheduler.isChatRunning) {
        await Future<void>.delayed(chatPollInterval);
      }
      try {
        // `embed` answers [] instead of throwing, for two different reasons.
        // An embedder that is not loaded is "try later" and must never cost the
        // note anything. An embedder that is loaded but failed on this text is
        // counted, or one bad note would sit at the front and block the rest.
        final vec = await _embedding.embed(item.text, isDocument: true);
        if (vec.isEmpty) {
          if (!_embedding.isReady) {
            debugPrint('⚠️ NoteEmbeddingWorker: embedder not ready, keeping '
                '$shortId and stopping');
            return true;
          }
          throw StateError('the embedder returned no vector for this note');
        }
        await _vector.upsert(item.eventId, vec);
        // Row removed last: a crash between the two just embeds it again.
        await _pending.remove(item.eventId);
        debugPrint('✅ NoteEmbeddingWorker: embedded $shortId');
        unawaited(_extract.call((item.eventId, item.text, vec)));
      } catch (e, st) {
        final attempts = await _pending.recordFailure(item.eventId);
        debugPrint('❌ NoteEmbeddingWorker: $shortId failed '
            '($attempts/$maxAttempts): $e\n$st');
        if (attempts < maxAttempts) return true;
        await _pending.remove(item.eventId);
        debugPrint('🗑️ NoteEmbeddingWorker: dropped $shortId after '
            '$maxAttempts failures');
      }
    }
  }
}
