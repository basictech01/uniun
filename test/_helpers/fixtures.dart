// ignore_for_file: lines_longer_than_80_chars
//
// Shared test fixtures: factory functions for every common domain entity.
// One source of truth for entity construction so tests don't reinvent
// boilerplate and a schema change only updates this file.
//
// - Every factory has non-null defaults and named overrides.
// - Returns are freezed entities — no Isar models (those need a live Isar).
// - Times default to [tT0] / [tNow] so tests are deterministic.

import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/enum/relay_status.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/group/group_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/entities/media/media_blob_entity.dart';
import 'package:uniun/domain/entities/media/media_dim.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/private_group/private_group_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/entities/relay/relay_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

// ── Fixed clocks ─────────────────────────────────────────────────────────────

final DateTime tT0 = DateTime.utc(2026, 1, 1);
final DateTime tNow = DateTime.utc(2026, 6, 30, 12, 0, 0);

/// Own-profile eviction sentinel — mirrors the production value the
/// CleanupManager never reaches (`ProfileModel.lastSeenAt` docs).
final DateTime tOwnProfileSentinel = DateTime(3000, 6, 1);

// ── Predefined pubkeys ───────────────────────────────────────────────────────

const String kSelfPub = 'self-pub';
const String kAlicePub = 'alice-pub';
const String kBobPub = 'bob-pub';
const String kCarolPub = 'carol-pub';
const String kEvePub = 'eve-pub';

String pubkeyN(int n) => 'pubkey-$n';

// ── 64-char hex constants ────────────────────────────────────────────────────
//
// Nostr event ids and pubkeys must be exactly 64 hex chars — some code paths
// (e.g. `nostr.Event.from`, NIP-56 tag validators) reject shorter strings.
// Use these when the code under test cares about hex shape; use the short
// [kAlicePub] / [kBobPub] labels when the value is just an opaque identifier.

const String kSampleEventIdHex =
    '1111111111111111111111111111111111111111111111111111111111111111';
const String kSampleTargetPubkeyHex =
    '2222222222222222222222222222222222222222222222222222222222222222';
String eventIdN(int n) => 'evt-$n';

// ── NoteEntity ───────────────────────────────────────────────────────────────

/// Defaults to a top-level Kind-1 feed note by [kAlicePub].
NoteEntity aNote({
  String id = 'note-1',
  String sig = 'sig',
  String authorPubkey = kAlicePub,
  String content = 'hello world',
  String? subject,
  int kind = kNoteKind,
  NoteType type = NoteType.text,
  List<String> eTagRefs = const [],
  List<String> pTagRefs = const [],
  List<String> tTags = const [],
  DateTime? created,
  int? conversationId,
  String? rootEventId,
  String? replyToEventId,
  int cachedReplyCount = 0,
  int referenceCount = 0,
  String? sourceGroupId,
  String? sourcePrivateGroupId,
  String? sourceLabel,
  String? embeddedNoteJson,
  NoteEntity? quotedNote,
  List<MediaBlobEntity> attachments = const [],
}) {
  return NoteEntity(
    id: id,
    sig: sig,
    authorPubkey: authorPubkey,
    content: content,
    subject: subject,
    kind: kind,
    type: type,
    eTagRefs: eTagRefs,
    pTagRefs: pTagRefs,
    tTags: tTags,
    created: created ?? tNow,
    conversationId: conversationId,
    rootEventId: rootEventId,
    replyToEventId: replyToEventId,
    cachedReplyCount: cachedReplyCount,
    referenceCount: referenceCount,
    sourceGroupId: sourceGroupId,
    sourcePrivateGroupId: sourcePrivateGroupId,
    sourceLabel: sourceLabel,
    embeddedNoteJson: embeddedNoteJson,
    quotedNote: quotedNote,
    attachments: attachments,
  );
}

/// Reply with NIP-10 markers wired to [parent].
NoteEntity aReply({
  required NoteEntity parent,
  String id = 'reply-1',
  String content = 'replying',
  String authorPubkey = kBobPub,
  DateTime? created,
}) {
  return aNote(
    id: id,
    content: content,
    authorPubkey: authorPubkey,
    created: created ?? parent.created.add(const Duration(minutes: 1)),
    rootEventId: parent.rootEventId ?? parent.id,
    replyToEventId: parent.id,
    eTagRefs: [parent.rootEventId ?? parent.id, parent.id],
  );
}

/// Kind-42 public-group message.
NoteEntity aGroupMessage({
  required String groupId,
  String id = 'gm-1',
  String content = 'group msg',
  String authorPubkey = kAlicePub,
  DateTime? created,
}) {
  return aNote(
    id: id,
    content: content,
    authorPubkey: authorPubkey,
    kind: kGroupMessageKind,
    sourceGroupId: groupId,
    sourceLabel: '#$groupId',
    created: created,
  );
}

/// NIP-29 private-group (Kind 9023) message.
NoteEntity aPrivateGroupMessage({
  required String groupId,
  String id = 'pgm-1',
  String content = 'private msg',
  String authorPubkey = kAlicePub,
}) {
  return aNote(
    id: id,
    content: content,
    authorPubkey: authorPubkey,
    kind: kPrivateGroupKind,
    sourcePrivateGroupId: groupId,
    sourceLabel: '🔒 $groupId',
  );
}

/// NIP-17 DM text rumor (Kind 14).
NoteEntity aDmText({
  required int conversationId,
  String id = 'dm-1',
  String content = 'hi there',
  String authorPubkey = kAlicePub,
  String? recipient,
}) {
  return aNote(
    id: id,
    content: content,
    authorPubkey: authorPubkey,
    kind: kDmTextKind,
    conversationId: conversationId,
    pTagRefs: recipient == null ? const [] : [recipient],
  );
}

/// Note that quotes [original] by value (embeddedNoteJson path).
NoteEntity aQuoteOf(NoteEntity original, {String id = 'quote-1'}) {
  return aNote(
    id: id,
    content: 'see this',
    quotedNote: original,
  );
}

/// [n] notes by [authorPubkey], newest first.
List<NoteEntity> aFeed({
  int n = 20,
  String authorPubkey = kAlicePub,
  DateTime? start,
}) {
  final base = start ?? tNow;
  return [
    for (var i = 0; i < n; i++)
      aNote(
        id: 'feed-$i',
        content: 'feed note #$i',
        authorPubkey: authorPubkey,
        created: base.subtract(Duration(minutes: i)),
      ),
  ];
}

/// Linear reply chain root → r1 → r2 → … of length [depth].
/// First element is the root; last is the deepest leaf.
List<NoteEntity> aThread({int depth = 5}) {
  if (depth <= 0) return const [];
  final root = aNote(id: 'root', content: 'thread root');
  final chain = <NoteEntity>[root];
  for (var i = 1; i < depth; i++) {
    chain.add(aReply(parent: chain.last, id: 'reply-$i'));
  }
  return chain;
}

// ── Edge-case content payloads ───────────────────────────────────────────────

class Content {
  Content._();

  static const String empty = '';
  static const String oneChar = 'x';
  static const String emoji = '🐉 hello 👋 world 🚀';
  static const String unicode = 'مرحبا بالعالم — Здравствуй, мир — 你好世界';
  static const String rtl = 'مرحبا hello مرحبا';

  static const String singleNewline = 'first\nsecond';
  static const String manyNewlines = 'a\nb\nc\nd\ne\nf\ng\nh\ni';

  /// `max + 1` chars: just over ExpandableNoteText's threshold.
  static String longJustOver(int max) => 'x' * (max + 1);

  /// 200 newline-separated lines.
  static String veryLong() => List.generate(200, (i) => 'line $i').join('\n');

  static const String bareHttp = 'see http://example.com/path?q=1#x';
  static const String bareHttps = 'see https://uniun.in/note/abc';
  static const String multipleUrls =
      'a https://x.com/1 then b http://y.org and c https://z.net';
  static const String nostrUri = 'follow nostr:npub1abc';
  static const String mixedSchemes =
      'a https://x.com b nostr:npub1abc c http://y.org';

  static const String snakeCase = 'check my_variable_name in code';
  static const String boldOnly = '**bold word**';
  static const String italicOnly = '_italic word_';
  static const String codeOnly = '`code word`';
  static const String mixedInline =
      '**bold** and _italic_ and `code` and [link](https://x)';
  static const String allHeadings = '# H1\n## H2\n### H3';
  static const String bulletList = '- a\n- b\n- c';
  static const String numberedList = '1. a\n2. b\n3. c';
  static const String blockquote = '> a quote\n> spans two lines';

  /// Pre-formatted markdown link — must NOT be re-shortened.
  static const String alreadyBracketed = '[docs](https://uniun.in/x)';

  static const String urlInSentence =
      'For more see https://example.com/path/to/page about it.';
}

// ── ProfileEntity ────────────────────────────────────────────────────────────

ProfileEntity aProfile({
  String pubkey = kAlicePub,
  String? name = 'Alice',
  String? username,
  String? about,
  String? avatarUrl,
  String? nip05,
  DateTime? updatedAt,
  DateTime? lastSeenAt,
}) {
  return ProfileEntity(
    pubkey: pubkey,
    name: name,
    username: username,
    about: about,
    avatarUrl: avatarUrl,
    nip05: nip05,
    updatedAt: updatedAt ?? tNow,
    lastSeenAt: lastSeenAt,
  );
}

/// Profile with no name and no username — forces short-pubkey fallback.
ProfileEntity anAnonymousProfile({String pubkey = kAlicePub}) =>
    aProfile(pubkey: pubkey, name: null, username: null);

// ── GroupEntity (NIP-28 public group) ────────────────────────────────────────

GroupEntity aGroup({
  String groupId = 'group-1',
  String creatorPubKey = kAlicePub,
  String name = 'General',
  String about = 'a public group',
  String picture = '',
  List<String> relays = const ['wss://relay.example'],
  int createdAt = 1720000000,
  int updatedAt = 1720000000,
  String? lastMetaEvent,
}) {
  return GroupEntity(
    groupId: groupId,
    creatorPubKey: creatorPubKey,
    name: name,
    about: about,
    picture: picture,
    relays: relays,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastMetaEvent: lastMetaEvent,
  );
}

// ── PrivateGroupEntity (MLS e2ee group) ──────────────────────────────────────

PrivateGroupEntity aPrivateGroup({
  int id = 0,
  String groupId = 'pgroup-1',
  String? mlsGroupId,
  String name = 'Secret',
  String description = 'a private group',
  List<String> relays = const ['wss://relay.example'],
  String adminPubkey = kAlicePub,
}) {
  return PrivateGroupEntity(
    id: id,
    groupId: groupId,
    mlsGroupId: mlsGroupId ?? 'mls_$groupId',
    relays: relays,
    name: name,
    description: description,
    adminPubkey: adminPubkey,
  );
}

// ── DmConversationEntity ─────────────────────────────────────────────────────

DmConversationEntity aDmConversation({
  int id = 0,
  String otherPubkey = kSampleTargetPubkeyHex,
  List<String> relays = const [],
}) {
  return DmConversationEntity(
    id: id,
    otherPubkey: otherPubkey,
    relays: relays,
  );
}

// ── RelayEntity ──────────────────────────────────────────────────────────────

RelayEntity aRelay({
  String url = 'wss://relay.example',
  bool read = true,
  bool write = true,
  RelayStatus status = RelayStatus.disconnected,
  DateTime? lastConnectedAt,
  bool isSystem = false,
}) {
  return RelayEntity(
    url: url,
    read: read,
    write: write,
    status: status,
    lastConnectedAt: lastConnectedAt,
    isSystem: isSystem,
  );
}

// ── SavedNoteEntity ──────────────────────────────────────────────────────────

SavedNoteEntity aSavedNote({
  String eventId = 'saved-1',
  String sig = 'sig',
  String authorPubkey = kBobPub,
  String content = 'a saved note',
  NoteType type = NoteType.text,
  List<String> eTagRefs = const [],
  List<String> pTagRefs = const [],
  List<String> tTags = const [],
  DateTime? created,
  DateTime? savedAt,
  String? rootEventId,
  String? replyToEventId,
  int cachedReplyCount = 0,
  int referenceCount = 0,
  String? sourceGroupId,
  String? sourcePrivateGroupId,
  NoteEntity? quotedNote,
}) {
  return SavedNoteEntity(
    eventId: eventId,
    sig: sig,
    authorPubkey: authorPubkey,
    content: content,
    type: type,
    eTagRefs: eTagRefs,
    pTagRefs: pTagRefs,
    tTags: tTags,
    created: created ?? tNow,
    savedAt: savedAt ?? tNow,
    rootEventId: rootEventId,
    replyToEventId: replyToEventId,
    cachedReplyCount: cachedReplyCount,
    referenceCount: referenceCount,
    sourceGroupId: sourceGroupId,
    sourcePrivateGroupId: sourcePrivateGroupId,
    quotedNote: quotedNote,
  );
}

// ── ManasEntity ──────────────────────────────────────────────────────────────

ManasEntity aManas({
  String manasId = 'manas-1',
  String name = 'Work',
  String? description,
  String? iconName,
  DateTime? createdAt,
  DateTime? updatedAt,
  int noteCount = 0,
}) {
  return ManasEntity(
    manasId: manasId,
    name: name,
    description: description,
    iconName: iconName,
    createdAt: createdAt ?? tT0,
    updatedAt: updatedAt ?? tNow,
    noteCount: noteCount,
  );
}

List<ManasEntity> manyManas(int n) => [
      for (var i = 0; i < n; i++) aManas(manasId: 'm-$i', name: 'Manas $i'),
    ];

// ── GanaEntity ───────────────────────────────────────────────────────────────

GanaEntity aGana({
  String ganaId = 'gana-1',
  String name = 'Test Gana',
  List<String> manasIds = const [],
  String taskPrompt = 'Say something useful',
  GanaOutputType outputType = GanaOutputType.feed,
  String? outputGroupId,
  String? outputPrivateGroupId,
  int? outputDmConversationId,
  String? desiredModelId,
  LlmBackendType? desiredBackend,
  bool triggerReactive = false,
  int? triggerIntervalMinutes,
  GanaTriggerMode triggerMode = GanaTriggerMode.recurring,
  int? maxOutputs,
  bool enabled = false,
  int runsSucceeded = 0,
  int runsFailed = 0,
  int runsSkipped = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return GanaEntity(
    ganaId: ganaId,
    name: name,
    manasIds: manasIds,
    taskPrompt: taskPrompt,
    outputType: outputType,
    outputGroupId: outputGroupId,
    outputPrivateGroupId: outputPrivateGroupId,
    outputDmConversationId: outputDmConversationId,
    desiredModelId: desiredModelId,
    desiredBackend: desiredBackend,
    triggerReactive: triggerReactive,
    triggerIntervalMinutes: triggerIntervalMinutes,
    triggerMode: triggerMode,
    maxOutputs: maxOutputs,
    enabled: enabled,
    runsSucceeded: runsSucceeded,
    runsFailed: runsFailed,
    runsSkipped: runsSkipped,
    createdAt: createdAt ?? tT0,
    updatedAt: updatedAt ?? tNow,
  );
}

GanaRunEntity aGanaRun({
  String runId = 'run-1',
  String ganaId = 'gana-1',
  DateTime? startedAt,
  GanaRunStatus status = GanaRunStatus.succeeded,
  String? error,
}) {
  return GanaRunEntity(
    runId: runId,
    ganaId: ganaId,
    startedAt: startedAt ?? tNow,
    status: status,
    error: error,
  );
}

// ── Graph entities ───────────────────────────────────────────────────────────

GraphNodeEntity aGraphNode({
  String key = 'node-1',
  String name = 'Node One',
  String type = 'topic',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return GraphNodeEntity(
    key: key,
    name: name,
    type: type,
    createdAt: createdAt ?? tT0,
    updatedAt: updatedAt ?? tNow,
  );
}

GraphEdgeEntity aGraphEdge({
  String sourceKey = 'node-1',
  String targetKey = 'node-2',
  String relationType = 'mentions',
  String sourceNoteId = 'note-1',
  DateTime? createdAt,
}) {
  return GraphEdgeEntity(
    sourceKey: sourceKey,
    targetKey: targetKey,
    relationType: relationType,
    sourceNoteId: sourceNoteId,
    createdAt: createdAt ?? tNow,
  );
}

// ── MemoryNodeEntity ─────────────────────────────────────────────────────────

MemoryNodeEntity aMemoryNode({
  String noteId = 'note-1',
  String summary = 'a wiki-style summary',
  List<String> keyPoints = const ['point'],
  List<String> concepts = const ['concept'],
  List<String> linkedNoteIds = const [],
  DateTime? updatedAt,
}) {
  return MemoryNodeEntity(
    noteId: noteId,
    summary: summary,
    keyPoints: keyPoints,
    concepts: concepts,
    linkedNoteIds: linkedNoteIds,
    updatedAt: updatedAt ?? tNow,
  );
}

// ── UserKeyEntity ────────────────────────────────────────────────────────────

UserKeyEntity aUserKey({
  String pubkeyHex = kSelfPub,
  String? npub,
  String? nsec,
  DateTime? createdAt,
}) {
  return UserKeyEntity(
    pubkeyHex: pubkeyHex,
    npub: npub ?? 'npub1$pubkeyHex',
    nsec: nsec ?? 'nsec1$pubkeyHex',
    createdAt: createdAt ?? tT0,
  );
}

// ── UserSigningKeys ──────────────────────────────────────────────────────────
//
// Hex-format keys ready for Nostr `Event.from` signing. The default privkey
// is a valid secp256k1 scalar (64 hex chars, non-zero, below the curve order).
// The pubkey field is a placeholder — nostr's `Event.from` derives the real
// pubkey from privkey at sign time; tests that check pubkey shape assert on
// the derived value, not this constant.

const String kTestPrivHex =
    '1111111111111111111111111111111111111111111111111111111111111111';
const String kTestPubHex =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

UserSigningKeys aSigningKeys({
  String privkeyHex = kTestPrivHex,
  String pubkeyHex = kTestPubHex,
}) =>
    UserSigningKeys(privkeyHex: privkeyHex, pubkeyHex: pubkeyHex);

/// Compile-time signing keys — for `Right(...)` returns and other const
/// contexts where a factory call would prevent const promotion.
const UserSigningKeys kSigningKeys =
    UserSigningKeys(privkeyHex: kTestPrivHex, pubkeyHex: kTestPubHex);

// ── MediaBlobEntity ──────────────────────────────────────────────────────────

MediaBlobEntity aMediaBlob({
  String sha256 = 'sha256-aaa',
  String mime = 'image/jpeg',
  int sizeBytes = 1024,
  MediaDim? dim,
  String? blurhash,
  String? filename,
  List<String> serverUrls = const ['https://blossom.example/sha256-aaa'],
  String? localPath,
  DateTime? downloadedAt,
}) {
  return MediaBlobEntity(
    sha256: sha256,
    mime: mime,
    sizeBytes: sizeBytes,
    dim: dim,
    blurhash: blurhash,
    filename: filename,
    serverUrls: serverUrls,
    localPath: localPath,
    downloadedAt: downloadedAt,
  );
}

MediaBlobEntity aPdfBlob() => aMediaBlob(
      sha256: 'sha256-pdf',
      mime: 'application/pdf',
      filename: 'report.pdf',
      sizeBytes: 25_000,
    );

MediaBlobEntity aVideoBlob() => aMediaBlob(
      sha256: 'sha256-vid',
      mime: 'video/mp4',
      filename: 'clip.mp4',
      sizeBytes: 5_000_000,
    );

// ── Blossom wire payload (BlobDescriptor.fromJson input) ─────────────────────
//
// A minimal, well-formed BUD-01 blob descriptor as the server returns it. Use
// `overrides` to drop-in individual malformed / missing fields for negative
// tests, or pass `explicit: {'uploaded': null}` to inject an explicit null
// (the two shapes are distinct on the wire and must be tested separately).
Map<String, dynamic> aBlobDescriptorJson({
  String? url,
  String? sha256,
  Object? size,
  Object? type = 'image/jpeg',
  Object? uploaded,
  Map<String, Object?> explicit = const {},
}) {
  final base = <String, dynamic>{
    'url': url ?? 'https://s/x.jpg',
    'sha256': sha256 ?? 'sha',
    'size': size ?? 1,
    if (type != null) 'type': type,
    if (uploaded != null) 'uploaded': uploaded,
  };
  base.addAll(explicit);
  return base;
}
