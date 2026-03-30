import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl extends ProfileRepository {
  final Isar isar;
  ProfileRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(String pubkeyHex) async {
    try {
      final profile = await isar.profileModels
          .where()
          .pubkeyEqualTo(pubkeyHex)
          .findFirst();
      if (profile == null) {
        return Left(Failure.notFoundFailure('Profile not found: $pubkeyHex'));
      }
      return Right(profile.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> saveProfile(ProfileEntity profile) async {
    try {
      final existing = await isar.profileModels
          .where()
          .pubkeyEqualTo(profile.pubkey)
          .findFirst();

      final model = existing ?? ProfileModel();
      model.pubkey = profile.pubkey;
      model.name = profile.name;
      model.username = profile.username;
      model.about = profile.about;
      model.avatarUrl = profile.avatarUrl;
      model.nip05 = profile.nip05;
      model.updatedAt = profile.updatedAt;
      model.lastSeenAt = profile.lastSeenAt;

      await isar.writeTxn(() async {
        await isar.profileModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity?>> getOwnProfile(String pubkeyHex) async {
    try {
      final profile = await isar.profileModels
          .where()
          .pubkeyEqualTo(pubkeyHex)
          .findFirst();
      return Right(profile?.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
