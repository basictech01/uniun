import 'dart:async';
import 'dart:collection';

import 'package:injectable/injectable.dart';

/// Who is asking for an embedding. [interactive] is a person waiting on the
/// answer (a Shiv question); [background] is indexing nobody is waiting for
/// (a note, a PDF or DOCX chunk).
enum EmbedPriority { interactive, background }

/// The single gate every embedding passes through.
///
/// The embedder (`flutter_gemma_embeddings`) is a small dedicated model on a
/// separate chip path — it does NOT contend with the main chat model loaded
/// in [AIModelRunner], so it is not on [InferenceScheduler]. But the plugin runs
/// it in one worker isolate that serves requests strictly in order, and one
/// embed took about 11.5 s on a Snapdragon 710 (#231). Two things follow:
///
/// - Running two at once buys nothing (measured: one at a time and two at a
///   time were both 11.55 s per note), so only one embed is in flight.
/// - Whatever is in flight cannot be interrupted, so an [interactive] request
///   waits for at most that one, not for a backlog of indexing queued before
///   it: when a slot frees, interactive waiters go first.
///
/// Interactive requests are rare (one per question), so they cannot starve
/// background work for long.
@lazySingleton
class EmbeddingQueue {
  static const _maxConcurrent = 1;

  int _inFlight = 0;
  final Queue<Completer<void>> _interactive = Queue();
  final Queue<Completer<void>> _background = Queue();

  /// Runs [work] with at most [_maxConcurrent] in flight at a time, serving
  /// [EmbedPriority.interactive] waiters before background ones.
  Future<T> run<T>(
    Future<T> Function() work, {
    EmbedPriority priority = EmbedPriority.background,
  }) async {
    await _acquire(priority);
    try {
      return await work();
    } finally {
      _release();
    }
  }

  Future<void> _acquire(EmbedPriority priority) {
    if (_inFlight < _maxConcurrent) {
      _inFlight++;
      return Future.value();
    }
    final c = Completer<void>();
    (priority == EmbedPriority.interactive ? _interactive : _background).add(c);
    return c.future;
  }

  void _release() {
    // The freed slot passes straight to the next waiter, so `_inFlight` stays.
    if (_interactive.isNotEmpty) {
      _interactive.removeFirst().complete();
      return;
    }
    if (_background.isNotEmpty) {
      _background.removeFirst().complete();
      return;
    }
    if (_inFlight > 0) _inFlight--;
  }
}
