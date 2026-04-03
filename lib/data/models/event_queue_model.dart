import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/note_model.dart';

part 'event_queue_model.g.dart';

/// Durable outbound event queue. Each row represents one signed Nostr event
/// that needs to be published to one or more relays.
///
/// [id] is the Isar autoincrement integer — used as the ordered cursor by
/// every [WebSocketService] so each connection tracks its own send position
/// independently via [WebSocketService._lastSentQueueId].
///
/// An entry is eligible for dequeue when:
///   sentCount >= number of currently connected write relays
///   AND enqueuedAt < now - 30 minutes
@Collection(ignore: {'copyWith'})
@Name('EventQueue')
class EventQueueModel {
  Id id = Isar.autoIncrement;

  /// Nostr event ID (SHA256 hex) — unique per event.
  @Index(unique: true)
  late String eventId;

  /// The complete, ready-to-send relay wire message:
  /// '["EVENT", {"id":..., "pubkey":..., "sig":..., ...}]'
  /// Sent verbatim by WebSocketService — no re-encoding.
  late String serializedRelayMessage;

  /// Number of write-relay connections that have received ["OK", id, true].
  /// Incremented atomically by each WebSocketService on successful ACK.
  late int sentCount;

  /// When this event was enqueued. Used for the 30-minute dequeue gate.
  late DateTime enqueuedAt;
}

/// Serialization owned by [EventQueueModel] — it is the queue's responsibility
/// to know how to turn a [NoteModel] into a relay wire message.
///
/// Tag reconstruction order (must match [PublishNoteUseCase._buildTags]):
///   1. root e-tag (NIP-10)
///   2. reply e-tag (NIP-10)
///   3. mention e-tags (remaining eTagRefs)
///   4. p-tags
///   5. t-tags
extension EventQueueModelExtension on EventQueueModel {
  /// Populates this instance from [note] and returns [this] for chaining.
  EventQueueModel populateFromNote(NoteModel note) {
    final tags = <List<String>>[
      if (note.rootEventId != null) ['e', note.rootEventId!, '', 'root'],
      if (note.replyToEventId != null) ['e', note.replyToEventId!, '', 'reply'],
      for (final ref in note.eTagRefs)
        if (ref != note.rootEventId && ref != note.replyToEventId)
          ['e', ref, '', 'mention'],
      for (final p in note.pTagRefs) ['p', p],
      for (final t in note.tTags) ['t', t],
    ];

    eventId = note.eventId;
    serializedRelayMessage = jsonEncode([
      'EVENT',
      <String, dynamic>{
        'id': note.eventId,
        'pubkey': note.authorPubkey,
        'created_at': note.created.millisecondsSinceEpoch ~/ 1000,
        'kind': 1,
        'tags': tags,
        'content': note.content,
        'sig': note.sig,
      },
    ]);
    sentCount = 0;
    enqueuedAt = DateTime.now();
    return this;
  }
}
