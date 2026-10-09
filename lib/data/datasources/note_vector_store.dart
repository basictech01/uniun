import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:tostore/tostore.dart';

/// Table shape: `id` = Nostr event id (string primary key), `embedding` = the
/// note's vector, cosine distance.
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

  static Future<NoteVectorStore> open(String path) async {
    final ready = ReceivePort();
    final exit = ReceivePort();
    final isolate = await Isolate.spawn(_serve, (
      path: path,
      ready: ready.sendPort,
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

  /// Stores [vector] for [id] and flushes it to disk before returning.
  Future<void> upsert(String id, List<double> vector) =>
      _ask<void>((reply) => _Upsert(reply, id, vector));

  Future<void> delete(String id) => _ask<void>((reply) => _Delete(reply, id));

  /// Removes all note vectors when switching accounts.
  Future<void> clear() => _ask<void>(_Clear.new);

  Future<bool> contains(String id) =>
      _ask<bool>((reply) => _Contains(reply, id));

  /// The [topK] nearest to [vector], best first. Score is similarity in 0..1.
  Future<List<NoteVectorHit>> search(
    List<double> vector, {
    required int topK,
  }) => _ask<List<NoteVectorHit>>((reply) => _Search(reply, vector, topK));

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

class _Upsert extends _Command {
  const _Upsert(super.reply, this.id, this.vector);
  final String id;
  final List<double> vector;
}

class _Delete extends _Command {
  const _Delete(super.reply, this.id);
  final String id;
}

class _Clear extends _Command {
  const _Clear(super.reply);
}

class _Contains extends _Command {
  const _Contains(super.reply, this.id);
  final String id;
}

class _Search extends _Command {
  const _Search(super.reply, this.vector, this.topK);
  final List<double> vector;
  final int topK;
}

class _Close extends _Command {
  const _Close(super.reply);
}

class _Failure {
  const _Failure(this.message);
  final String message;
}

Future<void> _serve(({String path, SendPort ready}) init) async {
  final ToStore db;
  final commands = ReceivePort();
  try {
    db = await ToStore.open(dbPath: init.path, schemas: [_noteVectorSchema()]);
  } catch (e) {
    init.ready.send(_Failure(e.toString()));
    return;
  }
  init.ready.send(commands.sendPort);

  await for (final message in commands) {
    final command = message as _Command;
    try {
      switch (command) {
        case _Upsert(:final id, :final vector):
          if (vector.isEmpty) throw ArgumentError('empty vector for $id');
          // tostore leaves the old entry in its search index when an existing id
          // is saved again, and when a row is deleted before a flush. Remove the
          // old one first so a replaced vector is the one that gets searched.
          if (await _has(db, id)) {
            await db
                .delete(embeddingsTableName)
                .where(embeddingsIdField, '=', id);
            await db.flush();
          }
          await db.upsert(embeddingsTableName, {
            embeddingsIdField: id,
            embeddingsVectorField: vector,
          });
          // Flush so the new entry is searchable before this call returns.
          await db.flush();
          command.reply.send(null);
        case _Delete(:final id):
          await db
              .delete(embeddingsTableName)
              .where(embeddingsIdField, '=', id);
          await db.flush();
          command.reply.send(null);
        case _Clear():
          await db.clear(embeddingsTableName);
          await db.flush();
          command.reply.send(null);
        case _Contains(:final id):
          command.reply.send(await _has(db, id));
        case _Search(:final vector, :final topK):
          final hits = await db.vectorSearch(
            embeddingsTableName,
            fieldName: embeddingsVectorField,
            queryVector: VectorData.fromList(vector),
            topK: topK,
          );
          command.reply.send([
            for (final h in hits) (id: h.primaryKey, score: h.score),
          ]);
        case _Close():
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
