import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/core/notes/note_vector_ids.dart';

/// Table shape: `id` = a vector id (a Nostr event id, or `<eventId>#<k>` for the
/// later pieces of a long note, see `note_vector_ids.dart`), `embedding` = its
/// vector, cosine distance.
const String embeddingsTableName = 'note_embeddings';
const String embeddingsIdField = 'id';
const String embeddingsVectorField = 'embedding';

/// Gecko 110M emits 768 values per text; the "1024" in its file name is its
/// input length (#234).
const int embeddingsDimensions = 768;

TableSchema _noteVectorSchema() => const TableSchema(
  name: embeddingsTableName,
  primaryKeyConfig: PrimaryKeyConfig(
    name: embeddingsIdField,
    type: PrimaryKeyType.none,
  ),
  fields: [
    FieldSchema(
      name: embeddingsVectorField,
      type: DataType.vector,
      vectorConfig: VectorFieldConfig(dimensions: embeddingsDimensions),
    ),
  ],
  indexes: [
    IndexSchema(
      fields: [embeddingsVectorField],
      type: IndexType.vector,
      vectorConfig: VectorIndexConfig(
        indexType: VectorIndexType.ngh,
        distanceMetric: VectorDistanceMetric.cosine,
      ),
    ),
  ],
);

typedef NoteVectorHit = ({String id, double score});

/// The note vector store, owned by its own isolate.
///
/// ToStore did 600 saves and 600 searches with a worst stall of 522 ms on the
/// main isolate (12 stalls over 16 ms); in its own isolate the worst was 13 ms.
/// Exactly one isolate may open the store — ToStore keeps per-isolate state, so
/// a second opener does not see the first one's writes — which is why every
/// caller goes through this class instead of opening it.
///
/// Commands run one at a time in the order sent, so a search right after an
/// upsert sees it.
class NoteVectorStore {
  NoteVectorStore._(this._isolate, this._commands, this._exit) {
    _exit.listen((_) {
      _stopped = true;
      for (final port in _waiting.toList()) {
        port.sendPort.send(const _Failure('the note vector store has stopped'));
      }
    });
  }

  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _exit;
  final Set<ReceivePort> _waiting = {};
  bool _stopped = false;

  /// [rebuildDelay] is how long after the last delete the search index is
  /// rebuilt: deleted vectors can stay in tostore's index and take top-K
  /// slots from live ones, so a burst of deletes is followed by one rebuild.
  static Future<NoteVectorStore> open(
    String path, {
    Duration rebuildDelay = const Duration(seconds: 30),
  }) async {
    final ready = ReceivePort();
    final exit = ReceivePort();
    final isolate = await Isolate.spawn(_serve, (
      path: path,
      ready: ready.sendPort,
      rebuildDelay: rebuildDelay,
    ), onExit: exit.sendPort);
    final first = await ready.first;
    ready.close();
    if (first is _Failure) {
      exit.close();
      throw StateError(
        'Could not open the note vector store: ${first.message}',
      );
    }
    return NoteVectorStore._(isolate, first as SendPort, exit);
  }

  /// Stores a note's [vectors] (one per piece, first piece first), replacing
  /// every vector the note had, and flushes them to disk before returning.
  Future<void> upsertNote(String noteId, List<List<double>> vectors) =>
      _ask<void>((reply) => _UpsertNote(reply, noteId, vectors));

  /// A note with one vector.
  Future<void> upsert(String noteId, List<double> vector) =>
      upsertNote(noteId, [vector]);

  /// Same as [deleteNote].
  Future<void> delete(String noteId) => deleteNote(noteId);

  /// Removes the note's vector and all its pieces.
  Future<void> deleteNote(String noteId) =>
      _ask<void>((reply) => _DeleteNote(reply, noteId));

  /// Removes all note vectors when switching accounts.
  Future<void> clear() => _ask<void>(_Clear.new);

  Future<bool> contains(String id) =>
      _ask<bool>((reply) => _Contains(reply, id));

  /// Rebuilds the search index from the stored rows. Deleted vectors can
  /// stay in tostore's index (and hide live ones) after many deletes.
  Future<void> rebuild() => _ask<void>(_Rebuild.new);

  /// Every stored vector id (pieces included), for sweeping vectors whose note
  /// is gone.
  Future<Set<String>> ids() async => (await _ask<List>(_Ids.new)).cast<String>().toSet();

  /// The [topK] nearest vectors, best first. Score is similarity in 0..1. A
  /// long note can fill several places: hits are pieces, and [allowedIds] are
  /// note ids (every piece of an allowed note competes).
  Future<List<NoteVectorHit>> search(
    List<double> vector, {
    required int topK,
    Set<String>? allowedIds,
  }) =>
      _ask<List<NoteVectorHit>>(
        (reply) => _Search(reply, vector, topK, allowedIds),
      );

  /// Flushes and closes the store; the isolate then exits.
  Future<void> close() async {
    await _ask<void>(_Close.new);
    _stopped = true;
  }

  @visibleForTesting
  void kill() => _isolate.kill(priority: Isolate.immediate);

  Future<T> _ask<T>(_Command Function(SendPort reply) build) async {
    if (_stopped) throw StateError('the note vector store has stopped');
    final port = ReceivePort();
    _waiting.add(port);
    _commands.send(build(port.sendPort));
    final result = await port.first;
    _waiting.remove(port);
    port.close();
    if (result is _Failure) throw StateError(result.message);
    return result as T;
  }
}

sealed class _Command {
  const _Command(this.reply);
  final SendPort reply;
}

class _UpsertNote extends _Command {
  const _UpsertNote(super.reply, this.noteId, this.vectors);
  final String noteId;
  final List<List<double>> vectors;
}

class _DeleteNote extends _Command {
  const _DeleteNote(super.reply, this.noteId);
  final String noteId;
}

class _Rebuild extends _Command {
  const _Rebuild(super.reply);
}

class _Ids extends _Command {
  const _Ids(super.reply);
}

class _Clear extends _Command {
  const _Clear(super.reply);
}

class _Contains extends _Command {
  const _Contains(super.reply, this.id);
  final String id;
}

class _Search extends _Command {
  const _Search(super.reply, this.vector, this.topK, this.allowedIds);
  final List<double> vector;
  final int topK;
  final Set<String>? allowedIds;
}

class _Close extends _Command {
  const _Close(super.reply);
}

class _Failure {
  const _Failure(this.message);
  final String message;
}

Future<void> _serve(
  ({String path, SendPort ready, Duration rebuildDelay}) init,
) async {
  final ToStore db;
  final commands = ReceivePort();
  Timer? rebuildTimer;

  /// note id → the ids of its later pieces. Built from the table on first use,
  /// then kept in step with every write, so a delete or a scoped search never
  /// scans the table to find a note's pieces.
  Map<String, Set<String>>? pieces;

  /// Queues a rebuild behind whatever commands are already waiting.
  void scheduleRebuild() {
    rebuildTimer?.cancel();
    rebuildTimer = Timer(init.rebuildDelay, () {
      final sink = ReceivePort();
      sink.first.then((_) => sink.close());
      commands.sendPort.send(_Rebuild(sink.sendPort));
    });
  }

  try {
    db = await ToStore.open(dbPath: init.path, schemas: [_noteVectorSchema()]);
  } catch (e) {
    init.ready.send(_Failure(e.toString()));
    return;
  }
  init.ready.send(commands.sendPort);

  Future<Map<String, Set<String>>> pieceIndex() async {
    final known = pieces;
    if (known != null) return known;
    final built = <String, Set<String>>{};
    final rows = await db.query(embeddingsTableName).select([embeddingsIdField]);
    for (final r in rows.data) {
      final id = r[embeddingsIdField] as String;
      final note = noteIdOfVector(id);
      if (note != id) built.putIfAbsent(note, () => {}).add(id);
    }
    return pieces = built;
  }

  /// Removes the note's vector and pieces; reports whether any existed.
  Future<bool> removeNote(String noteId) async {
    final index = await pieceIndex();
    final ids = [noteId, ...?index[noteId]];
    var any = false;
    for (final id in ids) {
      if (await _has(db, id)) {
        await db.delete(embeddingsTableName).where(embeddingsIdField, '=', id);
        any = true;
      }
    }
    index.remove(noteId);
    return any;
  }

  await for (final message in commands) {
    final command = message as _Command;
    try {
      switch (command) {
        case _UpsertNote(:final noteId, :final vectors):
          if (vectors.isEmpty || vectors.any((v) => v.isEmpty)) {
            throw ArgumentError('empty vector for $noteId');
          }
          // tostore leaves the old entry in its search index when an existing id
          // is saved again, and when a row is deleted before a flush. Remove the
          // old ones first so the replaced vectors are the ones searched.
          if (await removeNote(noteId)) {
            await db.flush();
            scheduleRebuild();
          }
          final index = await pieceIndex();
          for (var k = 0; k < vectors.length; k++) {
            final id = pieceId(noteId, k);
            await db.upsert(embeddingsTableName, {
              embeddingsIdField: id,
              embeddingsVectorField: vectors[k],
            });
            if (k > 0) index.putIfAbsent(noteId, () => {}).add(id);
          }
          // Flush so the new entries are searchable before this call returns.
          await db.flush();
          command.reply.send(null);
        case _DeleteNote(:final noteId):
          await removeNote(noteId);
          await db.flush();
          scheduleRebuild();
          command.reply.send(null);
        case _Clear():
          await db.clear(embeddingsTableName);
          await db.flush();
          pieces = {};
          command.reply.send(null);
        case _Rebuild():
          final rows = (await db.query(embeddingsTableName)).data;
          await db.clear(embeddingsTableName);
          await db.flush();
          for (final r in rows) {
            await db.upsert(embeddingsTableName, {
              embeddingsIdField: r[embeddingsIdField],
              embeddingsVectorField: r[embeddingsVectorField],
            });
          }
          await db.flush();
          command.reply.send(null);
        case _Ids():
          final rows = await db.query(embeddingsTableName);
          command.reply.send([
            for (final r in rows.data) r[embeddingsIdField] as String,
          ]);
        case _Contains(:final id):
          command.reply.send(await _has(db, id));
        case _Search(:final vector, :final topK, :final allowedIds):
          if (allowedIds != null && allowedIds.isEmpty) {
            command.reply.send(const <NoteVectorHit>[]);
            break;
          }
          if (allowedIds == null) {
            final hits = await db.vectorSearch(
              embeddingsTableName,
              fieldName: embeddingsVectorField,
              queryVector: VectorData.fromList(vector),
              topK: topK,
            );
            command.reply.send([
              for (final h in hits) (id: h.primaryKey, score: h.score),
            ]);
          } else {
            // Apply the Manas membership filter before vector ranking, so a
            // large unrelated library cannot crowd scoped notes out of top-K.
            final index = await pieceIndex();
            final wanted = <String>{
              for (final note in allowedIds) ...[note, ...?index[note]],
            };
            final rows = await db
                .query(embeddingsTableName)
                .select([embeddingsIdField, embeddingsVectorField])
                .whereIn(embeddingsIdField, wanted.toList())
                .limit(wanted.length);
            final query = VectorData.fromList(vector);
            final hits = <NoteVectorHit>[
              for (final row in rows.data)
                if (row[embeddingsVectorField] case final VectorData stored)
                  (
                    id: row[embeddingsIdField] as String,
                    score: query.cosineSimilarity(stored),
                  ),
            ]
              ..sort((a, b) => b.score.compareTo(a.score));
            command.reply.send(hits.take(topK).toList());
          }
        case _Close():
          rebuildTimer?.cancel();
          await db.close();
          command.reply.send(null);
          commands.close();
      }
    } catch (e) {
      command.reply.send(_Failure(e.toString()));
    }
  }
}

Future<bool> _has(ToStore db, String id) async {
  final rows = await db
      .query(embeddingsTableName)
      .where(embeddingsIdField, '=', id)
      .limit(1);
  return rows.data.isNotEmpty;
}
