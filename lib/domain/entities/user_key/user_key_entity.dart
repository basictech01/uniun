import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_key_entity.freezed.dart';
part 'user_key_entity.g.dart';

/// The logged-in user's full identity, assembled at runtime.
///
/// [pubkeyHex] and [npub] come from Isar (UserKeyModel).
/// [nsec] comes from flutter_secure_storage — never persisted in Isar.
@freezed
abstract class UserKeyEntity with _$UserKeyEntity {
  const factory UserKeyEntity({
    required String pubkeyHex, // hex public key — used in Nostr event authorship
    required String npub,      // bech32 public key — display only
    required String nsec,      // bech32 private key — from secure storage only
    required DateTime createdAt,
  }) = _UserKeyEntity;

  factory UserKeyEntity.fromJson(Map<String, dynamic> json) =>
      _$UserKeyEntityFromJson(json);
}
