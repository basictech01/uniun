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
  late String pubkey;     // secp256k1 public key — the Nostr identity

  String? name;
  String? username;
  String? about;
  String? avatarUrl;
  String? nip05;          // verified internet identifier (user@domain.com)

  late DateTime updatedAt; // last time this Kind 0 was received/updated

  ProfileModel();

  /// Parse a Kind 0 (User Metadata) Nostr event into a ProfileModel.
  ///
  /// Kind 0 content is a JSON string: {"name": "...", "about": "...", "picture": "...", "nip05": "..."}
  /// Silently ignores unknown or malformed content fields.
  factory ProfileModel.fromEvent(Event event) {
    Map<String, dynamic> meta = {};
    try {
      meta = jsonDecode(event.content) as Map<String, dynamic>;
    } catch (_) {
      // malformed JSON — treat as empty profile metadata
    }

    final model = ProfileModel();
    model.pubkey = event.pubkey;
    model.name = meta['display_name'] as String? ?? meta['name'] as String?;
    model.username = meta['name'] as String?;
    model.about = meta['about'] as String?;
    model.avatarUrl = meta['picture'] as String?;
    model.nip05 = meta['nip05'] as String?;
    model.updatedAt = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
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
      );
}
