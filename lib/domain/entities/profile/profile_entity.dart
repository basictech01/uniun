import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';
part 'profile_entity.g.dart';

@freezed
abstract class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String pubkey,      // hex public key — matches Nostr event pubkey
    String? name,
    String? username,
    String? about,
    String? avatarUrl,
    String? nip05,
    required DateTime updatedAt,
    required bool isOwn,         // true = logged-in user's profile, never evicted
    DateTime? lastSeenAt,        // for 30-day eviction of non-persistent profiles
  }) = _ProfileEntity;

  factory ProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileEntityFromJson(json);
}
