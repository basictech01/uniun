import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_key_entity.freezed.dart';
part 'user_key_entity.g.dart';

@freezed
abstract class UserKeyEntity with _$UserKeyEntity {
  const factory UserKeyEntity({
    required String nsec,
    required String npub,
    required DateTime createdAt,
  }) = _UserKeyEntity;

  factory UserKeyEntity.fromJson(Map<String, dynamic> json) =>
      _$UserKeyEntityFromJson(json);
}
