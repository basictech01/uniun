import 'dart:async';
import 'dart:collection';

import 'package:injectable/injectable.dart';

/// Who is asking for an embedding. [interactive] is a person waiting on the
/// answer (a Shiv question); [background] is indexing nobody is waiting for
/// (a note, a PDF or DOCX chunk).
enum EmbedPriority { interactive, background }

/// The single gate every embedding passes through.
///
/// The plugin runs the embedder in one worker isolate that serves requests in
/// order, and one embed took ~11.5 s on a Snapdragon 710 (#231). So one embed is
/// in flight (two at a time measured no faster), and when a slot frees an
/// [EmbedPriority.interactive] waiter goes before queued background ones. It
/// never interrupts the embed already running.
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
