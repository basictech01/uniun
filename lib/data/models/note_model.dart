import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'note_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('Note')
class NoteModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  late String sig;
  late String authorPubkey;
  late String content;

  @Enumerated(EnumType.name)
  late NoteType type;

  late List<String> eTagRefs;

  /// NIP-10: event ID of the thread root (["e", id, relay, "root"])
  /// null = this note IS the root (top-level feed note)
  @Index()
  String? rootEventId;

  /// NIP-10: event ID of the direct parent (["e", id, relay, "reply"])
  /// null = top-level note
  @Index()
  String? replyToEventId;

  late List<String> pTagRefs;
  late List<String> tTags;

  late DateTime created;
  late bool isSeen;

  NoteModel({
    required this.eventId,
    required this.sig,
    required this.authorPubkey,
    required this.content,
    required this.type,
    required this.eTagRefs,
    this.rootEventId,
    this.replyToEventId,
    required this.pTagRefs,
    required this.tTags,
    required this.created,
    required this.isSeen,
  });

  /// Parse a Kind 1 Nostr event (from the Dart Gateway / EmbeddedServer) into a NoteModel.
  ///
  /// NIP-10 threading rules applied here:
  ///   - e-tag with marker "root"  → rootEventId
  ///   - e-tag with marker "reply" → replyToEventId
  ///   - all e-tag ids (including root/reply/mention) → eTagRefs
  factory NoteModel.fromEvent(Event event) {
    final eTagRefs = <String>[];
    String? rootEventId;
    String? replyToEventId;
    final pTagRefs = <String>[];
    final tTags = <String>[];

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final tagName = tag[0];
      if (tagName == 'e' && tag.length >= 2) {
        final eventId = tag[1];
        eTagRefs.add(eventId);
        if (tag.length >= 4) {
          final marker = tag[3];
          if (marker == 'root') rootEventId = eventId;
          if (marker == 'reply') replyToEventId = eventId;
        }
      } else if (tagName == 'p' && tag.length >= 2) {
        pTagRefs.add(tag[1]);
      } else if (tagName == 't' && tag.length >= 2) {
        tTags.add(tag[1]);
      }
    }

    // Infer NoteType from content/tags
    NoteType type = NoteType.text;
    if (eTagRefs.isNotEmpty && event.content.isEmpty) {
      type = NoteType.reference;
    } else if (event.content.startsWith('http') &&
        (event.content.contains('.jpg') ||
            event.content.contains('.jpeg') ||
            event.content.contains('.png') ||
            event.content.contains('.gif') ||
            event.content.contains('.webp'))) {
      type = NoteType.image;
    } else if (event.content.startsWith('http')) {
      type = NoteType.link;
    }

    return NoteModel(
      eventId: event.id,
      sig: event.sig,
      authorPubkey: event.pubkey,
      content: event.content,
      type: type,
      eTagRefs: eTagRefs,
      rootEventId: rootEventId,
      replyToEventId: replyToEventId,
      pTagRefs: pTagRefs,
      tTags: tTags,
      created: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      isSeen: false,
    );
  }
}

extension NoteModelExtension on NoteModel {
  NoteEntity toDomain() => NoteEntity(
        id: eventId,
        sig: sig,
        authorPubkey: authorPubkey,
        content: content,
        type: type,
        eTagRefs: eTagRefs,
        rootEventId: rootEventId,
        replyToEventId: replyToEventId,
        pTagRefs: pTagRefs,
        tTags: tTags,
        created: created,
        isSeen: isSeen,
      );
}
