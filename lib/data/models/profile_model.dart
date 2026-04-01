import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';

part 'profile_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('NostrProfile')
class ProfileModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String pubkey;

  String? name;
  String? username;
  String? about;
  String? avatarUrl;
  String? nip05;

  late DateTime updatedAt;

  // CleanupManager evicts where lastSeenAt < now - 30 days.
  // Set DateTime(3000, 6, 1) for own profile so it is never evicted.
  DateTime? lastSeenAt;

  ProfileModel();

  factory ProfileModel.fromEvent(Event event) {
    Map<String, dynamic> meta = {};
    try {
      meta = jsonDecode(event.content) as Map<String, dynamic>;
    } catch (_) {}

    final model = ProfileModel();
    model.pubkey = event.pubkey;
    model.name = meta['display_name'] as String? ?? meta['name'] as String?;
    model.username = meta['name'] as String?;
    model.about = meta['about'] as String?;
    model.avatarUrl = meta['picture'] as String?;
    model.nip05 = meta['nip05'] as String?;
    model.updatedAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    model.lastSeenAt = null;
    return model;
  }
}

extension ProfileModelExtension on ProfileModel {
  ProfileEntity toDomain() => ProfileEntity(
        pubkey: pubkey,
        name: name,
        username: username,
        about: about,
        avatarUrl: avatarUrl,
        nip05: nip05,
        updatedAt: updatedAt,
        lastSeenAt: lastSeenAt,
      );
}
