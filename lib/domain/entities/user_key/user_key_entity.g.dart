// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_key_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserKeyEntity _$UserKeyEntityFromJson(Map<String, dynamic> json) =>
    _UserKeyEntity(
      pubkeyHex: json['pubkeyHex'] as String,
      npub: json['npub'] as String,
      nsec: json['nsec'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserKeyEntityToJson(_UserKeyEntity instance) =>
    <String, dynamic>{
      'pubkeyHex': instance.pubkeyHex,
      'npub': instance.npub,
      'nsec': instance.nsec,
      'createdAt': instance.createdAt.toIso8601String(),
    };
