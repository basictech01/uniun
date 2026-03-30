import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';
part 'profile_entity.g.dart';

@freezed
abstract class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String pubkey,
    String? name,
    String? username,
    String? about,
    String? avatarUrl,
    String? nip05,
    required DateTime updatedAt,
    // Own profile is never evicted: caller sets lastSeenAt = DateTime(3000, 6, 1).
    // CleanupManager evicts profiles where lastSeenAt < now - 30 days.
    // Null lastSeenAt = never evict (safe default for own profile).
    DateTime? lastSeenAt,
  }) = _ProfileEntity;

  factory ProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileEntityFromJson(json);
}
