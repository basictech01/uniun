// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_key_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserKeyEntity _$UserKeyEntityFromJson(Map<String, dynamic> json) =>
    _UserKeyEntity(
      nsec: json['nsec'] as String,
      npub: json['npub'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserKeyEntityToJson(_UserKeyEntity instance) =>
    <String, dynamic>{
      'nsec': instance.nsec,
      'npub': instance.npub,
      'createdAt': instance.createdAt.toIso8601String(),
    };
