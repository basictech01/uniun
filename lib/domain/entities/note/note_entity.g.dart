// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NoteEntity _$NoteEntityFromJson(Map<String, dynamic> json) => _NoteEntity(
  id: json['id'] as String,
  sig: json['sig'] as String,
  authorPubkey: json['authorPubkey'] as String,
  content: json['content'] as String,
  type: $enumDecode(_$NoteTypeEnumMap, json['type']),
  eTagRefs: (json['eTagRefs'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  pTagRefs: (json['pTagRefs'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tTags: (json['tTags'] as List<dynamic>).map((e) => e as String).toList(),
  created: DateTime.parse(json['created'] as String),
  isSeen: json['isSeen'] as bool,
  rootEventId: json['rootEventId'] as String?,
  replyToEventId: json['replyToEventId'] as String?,
);

Map<String, dynamic> _$NoteEntityToJson(_NoteEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sig': instance.sig,
      'authorPubkey': instance.authorPubkey,
      'content': instance.content,
      'type': _$NoteTypeEnumMap[instance.type]!,
      'eTagRefs': instance.eTagRefs,
      'pTagRefs': instance.pTagRefs,
      'tTags': instance.tTags,
      'created': instance.created.toIso8601String(),
      'isSeen': instance.isSeen,
      'rootEventId': instance.rootEventId,
      'replyToEventId': instance.replyToEventId,
    };

const _$NoteTypeEnumMap = {
  NoteType.text: 'text',
  NoteType.image: 'image',
  NoteType.link: 'link',
  NoteType.reference: 'reference',
};
