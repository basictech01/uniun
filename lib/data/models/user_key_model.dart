import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';

part 'user_key_model.g.dart';

/// Stores the logged-in user's public identity in Isar.
///
/// The private key (nsec) is NEVER stored here — it lives in
/// flutter_secure_storage (Android Keystore / iOS Keychain).
@Collection(ignore: {'copyWith'})
@Name('UserKey')
class UserKeyModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String pubkeyHex; // secp256k1 hex public key — used in all Nostr events

  late String npub;      // bech32 display form of pubkeyHex (npub1...)
  late DateTime createdAt;
}

extension UserKeyModelExtension on UserKeyModel {
  /// [nsec] is passed in from secure storage — never read from this model.
  UserKeyEntity toDomain({required String nsec}) => UserKeyEntity(
        pubkeyHex: pubkeyHex,
        npub: npub,
        nsec: nsec,
        createdAt: createdAt,
      );
}
