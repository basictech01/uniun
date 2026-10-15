import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/enum/relay_status.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/manas_note_link_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/note_relation_model.dart';
import 'package:uniun/data/models/private_group_join_request_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/models/shiv_message_model.dart';
import 'package:uniun/data/models/notes/media_attachment.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/report_model.dart';

import 'fixtures.dart';

// ── Builders (return the model, no I/O) ─────────────────────────────────────
//
// Use these when several rows go into the same `isar.writeTxn(...)` block —
// batching is faster than one-txn-per-row and lets tests mirror the app's
// atomic-commit pattern. Callers do the `writeTxn` + `put` themselves.

/// Build a [NoteModel] row without committing it.
///
/// All fields have sane defaults. Override any subset:
/// - Feed note (default): `noteRow('ev-1')`
/// - Group message: `noteRow('gm', kind: kGroupMessageKind, groupId: 'g-1')`
/// - DM: `noteRow('dm', kind: kDmTextKind, conversationId: 42)`
/// - Reply: `noteRow('r', rootEventId: 'root', replyToEventId: 'parent')`
/// - Media: `noteRow('m', type: NoteType.image, attachments: [aMediaAttachment(...)])`
NoteModel noteRow(
  String eventId, {
  String content = 'x',
  String authorPubkey = kAlicePub,
  String sig = 'sig',
  int kind = kNoteKind,
  NoteType type = NoteType.text,
  DateTime? created,
  List<String> eTagRefs = const [],
  List<String> pTagRefs = const [],
  List<String> tTags = const [],
  String? rootEventId,
  String? replyToEventId,
  String? groupId,
  String? privateGroupId,
  int? conversationId,
  String? embeddedNoteJson,
  List<MediaAttachment> attachments = const [],
}) =>
    NoteModel(
      eventId: eventId,
      sig: sig,
      authorPubkey: authorPubkey,
      content: content,
      kind: kind,
      type: type,
      eTagRefs: eTagRefs,
      pTagRefs: pTagRefs,
      tTags: tTags,
      rootEventId: rootEventId,
      replyToEventId: replyToEventId,
      groupId: groupId,
      privateGroupId: privateGroupId,
      conversationId: conversationId,
      embeddedNoteJson: embeddedNoteJson,
      attachments: attachments,
      created: created ?? tNow,
    );

/// Build an active or tombstoned note-membership edge for a Manas.
ManasNoteLinkModel manasNoteLinkRow(
  String manasId,
  String noteId, {
  DateTime? addedAt,
  DateTime? removedAt,
}) =>
    ManasNoteLinkModel()
      ..manasId = manasId
      ..noteId = noteId
      ..addedAt = addedAt ?? tNow
      ..removedAt = removedAt;

/// Build an [UnreadNoteModel] row without committing it.
UnreadNoteModel unreadRow(
  String eventId, {
  int kind = kNoteKind,
  String authorPubkey = kAlicePub,
  String? groupId,
  String? privateGroupId,
  int? conversationId,
  DateTime? created,
}) =>
    UnreadNoteModel()
      ..eventId = eventId
      ..kind = kind
      ..authorPubkey = authorPubkey
      ..groupId = groupId
      ..privateGroupId = privateGroupId
      ..conversationId = conversationId
      ..created = created ?? tNow;

/// Build a [NoteRelationModel] edge row without committing it.
NoteRelationModel relationEdge(
  String parentId,
  String childId, {
  DateTime? createdAt,
}) =>
    NoteRelationModel()
      ..parentId = parentId
      ..childId = childId
      ..createdAt = createdAt ?? tNow;

/// Build a [ReportModel] row without committing it.
ReportModel reportRow({
  required String eventId,
  required String reportType,
  String targetPubkey = kSampleTargetPubkeyHex,
  String? targetEventId,
  String content = '',
  DateTime? created,
}) =>
    ReportModel()
      ..eventId = eventId
      ..reportType = reportType
      ..targetEventId = targetEventId
      ..targetPubkey = targetPubkey
      ..content = content
      ..created = created ?? tT0;

/// Build a [DeletedNoteModel] tombstone row without committing it.
DeletedNoteModel deletedNoteRow(
  String eventId, {
  DateTime? deletedAt,
}) =>
    DeletedNoteModel()
      ..eventId = eventId
      ..deletedAt = deletedAt ?? tNow;

/// Build an [EventQueueModel] row without committing it. Full param surface
/// so canonical tag-order tests can exercise every serializer branch:
/// - Report: `eventQueueRow('ev', kind: kReportKind, reportType: 'spam')`
/// - Draft: `eventQueueRow('d', kind: kDraftWrapKind, dTag: 'id', quoteKind: 1)`
/// - Private group: `eventQueueRow('pg', kind: kPrivateGroupKind, hTag: 'g')`
EventQueueModel eventQueueRow(
  String eventId, {
  String authorPubkey = kAlicePub,
  String sig = 'sig',
  int kind = kNoteKind,
  String content = 'x',
  List<String> eTagRefs = const [],
  List<String> pTagRefs = const [],
  List<String> tTags = const [],
  String? rootEventId,
  String? replyToEventId,
  String? embeddedNoteJson,
  int? quoteKind,
  String? hTag,
  String? dTag,
  int? expirationSec,
  List<String> serverTags = const [],
  List<MediaAttachment> imeta = const [],
  String? reportType,
  DateTime? created,
  int sentCount = 0,
  DateTime? enqueuedAt,
}) =>
    EventQueueModel()
      ..eventId = eventId
      ..authorPubkey = authorPubkey
      ..sig = sig
      ..kind = kind
      ..content = content
      ..eTagRefs = List<String>.from(eTagRefs)
      ..pTagRefs = List<String>.from(pTagRefs)
      ..tTags = List<String>.from(tTags)
      ..rootEventId = rootEventId
      ..replyToEventId = replyToEventId
      ..embeddedNoteJson = embeddedNoteJson
      ..quoteKind = quoteKind
      ..hTag = hTag
      ..dTag = dTag
      ..expirationSec = expirationSec
      ..serverTags = List<String>.from(serverTags)
      ..imeta = imeta
      ..reportType = reportType
      ..created = created ?? tNow
      ..sentCount = sentCount
      ..enqueuedAt = enqueuedAt ?? tNow;

/// Build a [MediaCacheModel] row without committing it.
MediaCacheModel mediaCacheRow(
  String sha256, {
  String? localPath,
  DateTime? downloadedAt,
  String mime = 'image/jpeg',
  int sizeBytes = 1,
}) =>
    MediaCacheModel()
      ..sha256 = sha256
      ..localPath = localPath ?? '/data/media/$sha256'
      ..downloadedAt = downloadedAt ?? tNow
      ..mime = mime
      ..sizeBytes = sizeBytes;

/// Build a [PrivateGroupJoinRequestModel] row without committing it.
PrivateGroupJoinRequestModel joinRequestRow(
  String eventId, {
  String groupId = 'pgroup-1',
  String senderPubkey = kBobPub,
  String keyPackageB64 = 'a2V5cGFja2FnZQ==',
  DateTime? timestamp,
  bool handled = false,
}) =>
    PrivateGroupJoinRequestModel()
      ..eventId = eventId
      ..groupId = groupId
      ..senderPubkey = senderPubkey
      ..keyPackageB64 = keyPackageB64
      ..timestamp = timestamp ?? tNow
      ..handled = handled;

/// Build a [ProfileModel] row without committing it.
ProfileModel profileRow(
  String pubkey, {
  String? name = 'Alice',
  String? username,
  String? about,
  String? avatarUrl,
  String? nip05,
  DateTime? updatedAt,
  DateTime? lastSeenAt,
}) =>
    ProfileModel()
      ..pubkey = pubkey
      ..name = name
      ..username = username
      ..about = about
      ..avatarUrl = avatarUrl
      ..nip05 = nip05
      ..updatedAt = updatedAt ?? tNow
      ..lastSeenAt = lastSeenAt;

/// Build a [DmConversationModel] row without committing it.
DmConversationModel dmConversationRow(
  String otherPubkey, {
  List<String> relays = const [],
}) =>
    DmConversationModel()
      ..otherPubkey = otherPubkey
      ..relays = List<String>.from(relays);

/// Build a [RelayModel] row without committing it.
RelayModel relayRow(
  String url, {
  bool read = true,
  bool write = true,
  RelayStatus status = RelayStatus.disconnected,
  DateTime? lastConnectedAt,
  bool isSystem = false,
}) =>
    RelayModel()
      ..url = url
      ..read = read
      ..write = write
      ..status = status
      ..lastConnectedAt = lastConnectedAt
      ..isSystem = isSystem;

/// Build a [SavedNoteModel] row without committing it.
SavedNoteModel savedNoteRow(
  String eventId, {
  String content = 'x',
  String authorPubkey = kAlicePub,
  String sig = 'sig',
  NoteType type = NoteType.text,
  List<String> eTagRefs = const [],
  List<String> pTagRefs = const [],
  List<String> tTags = const [],
  String? rootEventId,
  String? replyToEventId,
  String? sourceGroupId,
  String? sourcePrivateGroupId,
  String? embeddedNoteJson,
  List<MediaAttachment> attachments = const [],
  DateTime? created,
  DateTime? savedAt,
}) =>
    SavedNoteModel()
      ..eventId = eventId
      ..sig = sig
      ..authorPubkey = authorPubkey
      ..content = content
      ..type = type
      ..eTagRefs = List<String>.from(eTagRefs)
      ..pTagRefs = List<String>.from(pTagRefs)
      ..tTags = List<String>.from(tTags)
      ..rootEventId = rootEventId
      ..replyToEventId = replyToEventId
      ..sourceGroupId = sourceGroupId
      ..sourcePrivateGroupId = sourcePrivateGroupId
      ..embeddedNoteJson = embeddedNoteJson
      ..attachments = attachments
      ..created = created ?? tNow
      ..savedAt = savedAt ?? tNow;

/// Build a [ShivConversationModel] row without committing it.
ShivConversationModel shivConversationRow(
  String conversationId, {
  String title = 'chat',
  String? activeLeafMessageId,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    ShivConversationModel()
      ..conversationId = conversationId
      ..title = title
      ..activeLeafMessageId = activeLeafMessageId
      ..createdAt = createdAt ?? tNow
      ..updatedAt = updatedAt ?? tNow;

/// Build a [ShivMessageModel] row without committing it.
ShivMessageModel shivMessageRow(
  String messageId, {
  String conversationId = 'conv-1',
  String? parentId,
  MessageRole role = MessageRole.user,
  String content = 'x',
  DateTime? createdAt,
}) =>
    ShivMessageModel()
      ..messageId = messageId
      ..conversationId = conversationId
      ..parentId = parentId
      ..role = role
      ..content = content
      ..createdAt = createdAt ?? tNow;

/// Build a [MediaAttachment] embedded row without committing it. Convenient
/// when a test needs a note carrying media via [noteRow]`.attachments`.
MediaAttachment mediaAttachmentRow({
  String sha256 = 'sha',
  String mime = 'image/jpeg',
  int sizeBytes = 42,
  String? url = 'https://s/sha.jpg',
  int? width,
  int? height,
  String? blurhash,
  String? filename,
}) =>
    MediaAttachment()
      ..sha256 = sha256
      ..mime = mime
      ..sizeBytes = sizeBytes
      ..url = url
      ..width = width
      ..height = height
      ..blurhash = blurhash
      ..filename = filename;

// ── Committers (one write per call) ─────────────────────────────────────────
//
// Convenience wrappers when a test only needs to insert one row and doesn't
// care about batching. Each wraps its own `writeTxn`.

Future<void> seedNoteRow(
  Isar isar,
  String eventId, {
  String content = 'x',
  String authorPubkey = kAlicePub,
  int kind = kNoteKind,
  NoteType type = NoteType.text,
  DateTime? created,
  List<String> eTagRefs = const [],
  List<String> pTagRefs = const [],
  List<String> tTags = const [],
  String? rootEventId,
  String? replyToEventId,
  String? groupId,
  String? privateGroupId,
  int? conversationId,
  String? embeddedNoteJson,
  List<MediaAttachment> attachments = const [],
}) async {
  await isar.writeTxn(() async {
    await isar.noteModels.put(noteRow(
      eventId,
      content: content,
      authorPubkey: authorPubkey,
      kind: kind,
      type: type,
      created: created,
      eTagRefs: eTagRefs,
      pTagRefs: pTagRefs,
      tTags: tTags,
      rootEventId: rootEventId,
      replyToEventId: replyToEventId,
      groupId: groupId,
      privateGroupId: privateGroupId,
      conversationId: conversationId,
      embeddedNoteJson: embeddedNoteJson,
      attachments: attachments,
    ));
  });
}

Future<void> seedUnreadRow(
  Isar isar,
  String eventId, {
  int kind = kNoteKind,
  String authorPubkey = kAlicePub,
  String? groupId,
  String? privateGroupId,
  int? conversationId,
  DateTime? created,
}) async {
  await isar.writeTxn(() async {
    await isar.unreadNoteModels.put(unreadRow(
      eventId,
      kind: kind,
      authorPubkey: authorPubkey,
      groupId: groupId,
      privateGroupId: privateGroupId,
      conversationId: conversationId,
      created: created,
    ));
  });
}

Future<void> seedProfile(
  Isar isar,
  String pubkey, {
  String? name = 'Alice',
  String? username,
  String? about,
  String? avatarUrl,
  String? nip05,
  DateTime? updatedAt,
  DateTime? lastSeenAt,
}) async {
  await isar.writeTxn(() async {
    await isar.profileModels.put(profileRow(
      pubkey,
      name: name,
      username: username,
      about: about,
      avatarUrl: avatarUrl,
      nip05: nip05,
      updatedAt: updatedAt,
      lastSeenAt: lastSeenAt,
    ));
  });
}

Future<void> seedRelationEdge(
  Isar isar,
  String parentId,
  String childId, {
  DateTime? createdAt,
}) async {
  await isar.writeTxn(() async {
    await isar.noteRelationModels
        .put(relationEdge(parentId, childId, createdAt: createdAt));
  });
}

Future<void> seedDeletedNote(
  Isar isar,
  String eventId, {
  DateTime? deletedAt,
}) async {
  await isar.writeTxn(() async {
    await isar.deletedNoteModels
        .put(deletedNoteRow(eventId, deletedAt: deletedAt));
  });
}

Future<void> seedDmConversation(
  Isar isar,
  String otherPubkey, {
  List<String> relays = const [],
}) async {
  await isar.writeTxn(() async {
    await isar.dmConversationModels
        .put(dmConversationRow(otherPubkey, relays: relays));
  });
}

Future<void> seedRelay(
  Isar isar,
  String url, {
  bool read = true,
  bool write = true,
  RelayStatus status = RelayStatus.disconnected,
  DateTime? lastConnectedAt,
  bool isSystem = false,
}) async {
  await isar.writeTxn(() async {
    await isar.relayModels.put(relayRow(
      url,
      read: read,
      write: write,
      status: status,
      lastConnectedAt: lastConnectedAt,
      isSystem: isSystem,
    ));
  });
}

Future<void> seedReport(
  Isar isar, {
  required String eventId,
  required String reportType,
  String targetPubkey = kSampleTargetPubkeyHex,
  String? targetEventId,
  String content = '',
  DateTime? created,
}) async {
  await isar.writeTxn(() async {
    await isar.reportModels.put(reportRow(
      eventId: eventId,
      reportType: reportType,
      targetPubkey: targetPubkey,
      targetEventId: targetEventId,
      content: content,
      created: created,
    ));
  });
}
