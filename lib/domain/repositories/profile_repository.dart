import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';

abstract class ProfileRepository {
  /// Get a profile by pubkey from local Isar. Written by the Dart Gateway from Kind 0 events.
  Future<Either<Failure, ProfileEntity>> getProfile(String pubkey);

  /// Save or update a profile in Isar (idempotent — upsert by pubkey).
  Future<Either<Failure, ProfileEntity>> saveProfile(ProfileEntity profile);

  /// Get the logged-in user's own profile by their npub. Null if not yet fetched from relay.
  Future<Either<Failure, ProfileEntity?>> getOwnProfile(String npub);
}
