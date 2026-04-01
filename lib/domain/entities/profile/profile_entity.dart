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
    // CleanupManager evicts where lastSeenAt < now - 30 days.
    // Own profile uses DateTime(3000, 6, 1) so it is never evicted.
    DateTime? lastSeenAt,
  }) = _ProfileEntity;

  factory ProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileEntityFromJson(json);
}
