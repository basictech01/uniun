// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileEntity _$ProfileEntityFromJson(Map<String, dynamic> json) =>
    _ProfileEntity(
      pubkey: json['pubkey'] as String,
      name: json['name'] as String?,
      username: json['username'] as String?,
      about: json['about'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      nip05: json['nip05'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProfileEntityToJson(_ProfileEntity instance) =>
    <String, dynamic>{
      'pubkey': instance.pubkey,
      'name': instance.name,
      'username': instance.username,
      'about': instance.about,
      'avatarUrl': instance.avatarUrl,
      'nip05': instance.nip05,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
