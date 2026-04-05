import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';

// ── GetProfileUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class GetProfileUseCase
    extends UseCase<Either<Failure, ProfileEntity>, String> {
  final ProfileRepository _repository;
  const GetProfileUseCase(this._repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(
    String pubkey, {
    bool cached = false,
  }) {
    return _repository.getProfile(pubkey);
  }
}

// ── GetOwnProfileUseCase ──────────────────────────────────────────────────────

@lazySingleton
class GetOwnProfileUseCase
    extends UseCase<Either<Failure, ProfileEntity?>, String> {
  final ProfileRepository _repository;
  const GetOwnProfileUseCase(this._repository);

  @override
  Future<Either<Failure, ProfileEntity?>> call(
    String pubkeyHex, {
    bool cached = false,
  }) {
    return _repository.getOwnProfile(pubkeyHex);
  }
}

// ── SaveProfileUseCase ────────────────────────────────────────────────────────

@lazySingleton
class SaveProfileUseCase
    extends UseCase<Either<Failure, ProfileEntity>, ProfileEntity> {
  final ProfileRepository _repository;
  const SaveProfileUseCase(this._repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(
    ProfileEntity profile, {
    bool cached = false,
  }) {
    return _repository.saveProfile(profile);
  }
}
