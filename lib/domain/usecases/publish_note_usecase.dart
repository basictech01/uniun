import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/isolate/embedded_server_bridge.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';
import 'package:uniun/domain/repositories/outbound_event_repository.dart';

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
    // Step 1: Save locally so the note shows up in the UI immediately.
    final saveResult = await _noteRepository.saveNote(note);
    if (saveResult.isLeft()) return saveResult;

    // Step 2: Serialize and enqueue for relay broadcast.
    final json = _toNostrJson(note);
    final enqueueResult = await _outboundRepository.enqueue(json);
    if (enqueueResult.isLeft()) {
      return Left(
        enqueueResult.fold((f) => f, (_) => const Failure.errorFailure('enqueue failed')),
      );
    }

    // Step 3: Wake the EmbeddedServer so it flushes without polling delay.
    _bridge.notifyNewOutboundEvent();

    return saveResult;
  }

  /// Serialize a signed [NoteEntity] into a Nostr Kind 1 event JSON string.
  ///
  /// Tag reconstruction:
  ///   - rootEventId     → ["e", id, "", "root"]
  ///   - replyToEventId  → ["e", id, "", "reply"]
  ///   - eTagRefs (minus root/reply) → ["e", id, "", "mention"]
  ///   - pTagRefs        → ["p", pubkey]
  ///   - tTags           → ["t", hashtag]
  String _toNostrJson(NoteEntity note) {
    final tags = <List<String>>[];

    // Threading tags first (NIP-10 ordering convention)
    if (note.rootEventId != null) {
      tags.add(['e', note.rootEventId!, '', 'root']);
    }
    if (note.replyToEventId != null) {
      tags.add(['e', note.replyToEventId!, '', 'reply']);
    }

    // Remaining e-tags that are not root or reply are "mention"
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
