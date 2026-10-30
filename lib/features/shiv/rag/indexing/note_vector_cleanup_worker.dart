import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_vector_ids.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/pending_embedding_model.dart';
import 'package:uniun/data/models/pending_vector_delete_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';

/// Removes the vectors of deleted notes from the vector store.
///
/// `purgeNotesInTxn` queues one row per deleted note, in whichever isolate
/// deleted it. This worker lives in the isolate that owns the store, deletes
/// the vector, and removes the row last, so a kill or a stopped store loses
/// nothing: the row waits for the next pass.
///
/// On launch it also sweeps vectors that have no note (left by builds before
/// deletes were cleaned up, or by a path that removes rows without the purge,
/// such as un-saving a note whose original is gone) and rebuilds the search
/// index once per store format, for ghosts left by older builds. The store
/// itself rebuilds its index shortly after any burst of deletes.
@lazySingleton
class NoteVectorCleanupWorker {
  NoteVectorCleanupWorker(this._isar, this._store, this._settings);

  final Isar _isar;
  final NoteVectorStore _store;
  final AppSettingsStore _settings;

  /// Rows handled per transaction.
  static const int batchSize = 100;

  static const Duration retryDelay = Duration(minutes: 5);

  StreamSubscription<void>? _watch;
  Timer? _retry;
  Future<void>? _active;
  bool _again = false;
  bool _stopped = false;
  bool _launched = false;

  /// Watches the queue and runs once now. Safe to call twice.
  void start() {
    if (_watch != null) return;
    _stopped = false;
    _watch = _isar.pendingVectorDeleteModels
        .watchLazy(fireImmediately: true)
        .listen((_) => _nudge());
  }

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    _retry = null;
    await _watch?.cancel();
    _watch = null;
    await _active;
  }

  /// Completes when the running pass, if any, has finished.
  Future<void> idle() async {
    while (_active != null) {
      await _active;
    }
  }

  void _nudge() {
    if (_active != null) {
      _again = true;
      return;
    }
    _active = _loop().whenComplete(() => _active = null);
  }

  void _scheduleRetry() {
    if (_stopped) return;
    _retry?.cancel();
    _retry = Timer(retryDelay, _nudge);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      try {
        await run();
      } catch (e, st) {
        debugPrint('❌ NoteVectorCleanupWorker pass failed: $e\n$st');
        _scheduleRetry();
      }
    } while (_again && !_stopped);
  }

  /// The queue, then (once per launch) the sweep and the index rebuild.
  @visibleForTesting
  Future<void> run() async {
    await drain();
    if (!_launched) {
      _launched = true;
      await sweepOrphans();
      await rebuildIndexOnce();
    }
  }

  /// Deletes the queued vectors. A row stays when its delete fails.
  @visibleForTesting
  Future<int> drain() async {
    var removed = 0;
    while (!_stopped) {
      final batch = await _isar.pendingVectorDeleteModels
          .where()
          .limit(batchSize)
          .findAll();
      if (batch.isEmpty) break;
      final done = <int>[];
      try {
        for (final row in batch) {
          await _store.deleteNote(row.eventId);
          done.add(row.id);
        }
      } catch (e) {
        debugPrint('⚠️ NoteVectorCleanupWorker: store not ready — $e');
        _scheduleRetry();
      }
      if (done.isNotEmpty) {
        await _isar.writeTxn(
          () => _isar.pendingVectorDeleteModels.deleteAll(done),
        );
        removed += done.length;
      }
      if (done.length < batch.length) break;
    }
    return removed;
  }

  /// Deletes the vectors of notes that no longer exist. Returns how many notes.
  ///
  /// A vector is live while its note is in the notes table, saved, or still
  /// waiting to be embedded. It never runs when there are no notes at all but
  /// vectors exist: that looks like a database that failed to open, and the
  /// vectors cannot be rebuilt until backfill (#232) exists.
  @visibleForTesting
  Future<int> sweepOrphans() async {
    final ids = await _store.ids();
    if (ids.isEmpty) return 0;

    final live = <String>{
      ...await _isar.noteModels.where().eventIdProperty().findAll(),
      ...await _isar.savedNoteModels
          .filter()
          .removedAtIsNull()
          .eventIdProperty()
          .findAll(),
      ...await _isar.pendingEmbeddingModels.where().eventIdProperty().findAll(),
    };
    if (live.isEmpty) return 0;

    // A piece (`<noteId>#<k>`) is live while its note is. One delete takes a
    // note's pieces together, so each gone note is deleted once.
    final gone = {
      for (final id in ids)
        if (!live.contains(noteIdOfVector(id))) noteIdOfVector(id),
    };
    var removed = 0;
    for (final noteId in gone) {
      await _store.deleteNote(noteId);
      removed++;
    }
    if (removed > 0) debugPrint('🧹 NoteVectorCleanupWorker: swept $removed');
    return removed;
  }

  /// Rebuilds the search index once for this store format.
  @visibleForTesting
  Future<void> rebuildIndexOnce() async {
    if (_settings.noteVectorIndexRebuiltFormat == kNoteVectorStoreFormat) {
      return;
    }
    try {
      await _store.rebuild();
      await _settings.setNoteVectorIndexRebuiltFormat(kNoteVectorStoreFormat);
    } catch (e) {
      debugPrint('⚠️ NoteVectorCleanupWorker: rebuild failed — $e');
    }
  }
}
