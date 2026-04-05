import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/isolate/embedded_server_bridge.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/inputs/note_input.dart';
import 'package:uniun/domain/repositories/note_repository.dart';
import 'package:uniun/domain/repositories/outbound_event_repository.dart';

// ── GetFeedUseCase ────────────────────────────────────────────────────────────

@lazySingleton
class GetFeedUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, GetFeedInput> {
  final NoteRepository repository;
  const GetFeedUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    GetFeedInput input, {
    bool cached = false,
  }) {
    return repository.getFeed(limit: input.limit, before: input.before);
  }
}

// ── GetNoteByIdUseCase ────────────────────────────────────────────────────────

@lazySingleton
class GetNoteByIdUseCase
    extends UseCase<Either<Failure, NoteEntity>, String> {
  final NoteRepository repository;
  const GetNoteByIdUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.getNoteById(eventId);
  }
}

// ── GetRepliesUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class GetRepliesUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository repository;
  const GetRepliesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.getReplies(eventId);
  }
}

// ── SaveNoteUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class SaveNoteUseCase
    extends UseCase<Either<Failure, NoteEntity>, NoteEntity> {
  final NoteRepository repository;
  const SaveNoteUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(
    NoteEntity note, {
    bool cached = false,
  }) {
    return repository.saveNote(note);
  }
}

// ── MarkSeenUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class MarkSeenUseCase extends UseCase<Either<Failure, Unit>, String> {
  final NoteRepository repository;
  const MarkSeenUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.markAsSeen(eventId);
  }
}

// ── GetThreadUseCase ──────────────────────────────────────────────────────────

/// Returns the full thread for a given root note event ID.
/// Result: [root note, ...all replies sorted chronologically]
@lazySingleton
class GetThreadUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository repository;
  const GetThreadUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String rootEventId, {
    bool cached = false,
  }) {
    return repository.getThread(rootEventId);
  }
}

// ── GetReplyCountUseCase ──────────────────────────────────────────────────────

/// Count of direct replies to a note (replyToEventId == eventId).
@lazySingleton
class GetReplyCountUseCase extends UseCase<Either<Failure, int>, String> {
  final NoteRepository _repository;
  const GetReplyCountUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(String eventId, {bool cached = false}) {
    return _repository.getReplyCount(eventId);
  }
}

// ── GetThreadReplyCountUseCase ────────────────────────────────────────────────

/// Count of all notes in a thread (rootEventId == rootEventId).
@lazySingleton
class GetThreadReplyCountUseCase extends UseCase<Either<Failure, int>, String> {
  final NoteRepository _repository;
  const GetThreadReplyCountUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(
    String rootEventId, {
    bool cached = false,
  }) {
    return _repository.getThreadReplyCount(rootEventId);
  }
}

// ── PublishNoteUseCase ────────────────────────────────────────────────────────

/// Publishes a fully signed NoteEntity.
///
/// Input: a [NoteEntity] with id, sig, and all threading fields already set.
///        Signing happens in BrahmaCreateBloc before this is called.
///
/// Steps:
///   1. Save to local Isar via [NoteRepository.saveNote] — note appears in
///      the feed or thread view immediately (optimistic local display).
///   2. Serialize to Nostr event JSON and enqueue in [OutboundEventRepository].
///   3. Ping [EmbeddedServerBridge] — EmbeddedServer flushes the queue to relays.
@lazySingleton
class PublishNoteUseCase
    extends UseCase<Either<Failure, NoteEntity>, NoteEntity> {
  final NoteRepository _noteRepository;
  final OutboundEventRepository _outboundRepository;
  final EmbeddedServerBridge _bridge;

  const PublishNoteUseCase(
    this._noteRepository,
    this._outboundRepository,
    this._bridge,
  );

  @override
  Future<Either<Failure, NoteEntity>> call(
    NoteEntity note, {
    bool cached = false,
  }) async {
    final saveResult = await _noteRepository.saveNote(note);
    if (saveResult.isLeft()) return saveResult;

    final json = _toNostrJson(note);
    final enqueueResult = await _outboundRepository.enqueue(json);
    if (enqueueResult.isLeft()) {
      return Left(
        enqueueResult.fold(
            (f) => f, (_) => const Failure.errorFailure('enqueue failed')),
      );
    }

    _bridge.notifyNewOutboundEvent();
    return saveResult;
  }

  String _toNostrJson(NoteEntity note) {
    final tags = <List<String>>[];

    if (note.rootEventId != null) {
      tags.add(['e', note.rootEventId!, '', 'root']);
    }
    if (note.replyToEventId != null) {
      tags.add(['e', note.replyToEventId!, '', 'reply']);
    }

    final threadingIds = {
      if (note.rootEventId != null) note.rootEventId!,
      if (note.replyToEventId != null) note.replyToEventId!,
    };
    for (final id in note.eTagRefs) {
      if (!threadingIds.contains(id)) {
        tags.add(['e', id, '', 'mention']);
      }
    }

    for (final pubkey in note.pTagRefs) {
      tags.add(['p', pubkey]);
    }
    for (final hashtag in note.tTags) {
      tags.add(['t', hashtag]);
    }

    return jsonEncode({
      'id': note.id,
      'pubkey': note.authorPubkey,
      'created_at': note.created.millisecondsSinceEpoch ~/ 1000,
      'kind': 1,
      'tags': tags,
      'content': note.content,
      'sig': note.sig,
    });
  }
}
