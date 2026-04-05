import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

// ── UserSigningKeys ───────────────────────────────────────────────────────────

/// Decoded signing keys, ready for use in Nostr event construction.
class UserSigningKeys {
  const UserSigningKeys({
    required this.privkeyHex,
    required this.pubkeyHex,
  });
  final String privkeyHex;
  final String pubkeyHex;
}

// ── GetActiveUserUseCase ──────────────────────────────────────────────────────

@lazySingleton
class GetActiveUserUseCase
    extends NoParamsUseCase<Either<Failure, UserKeyEntity>> {
  final UserRepository _repository;
  const GetActiveUserUseCase(this._repository);

  @override
  Future<Either<Failure, UserKeyEntity>> call() => _repository.getActiveUser();
}

// ── GetActiveUserKeysUseCase ──────────────────────────────────────────────────

/// Fetches the active user from secure storage and decodes their keys into
/// hex format. Use this whenever a note needs to be signed — in Brahma,
/// reply flows, or any future note-creation surface.
@lazySingleton
class GetActiveUserKeysUseCase
    extends NoParamsUseCase<Either<Failure, UserSigningKeys>> {
  final UserRepository _repository;
  const GetActiveUserKeysUseCase(this._repository);

  @override
  Future<Either<Failure, UserSigningKeys>> call() async {
    final result = await _repository.getActiveUser();
    return result.fold(
      Left.new,
      (user) => Right(UserSigningKeys(
        privkeyHex: Nip19.decodePrivkey(user.nsec),
        pubkeyHex: user.pubkeyHex,
      )),
    );
  }
}

// ── ActiveUserProfile ─────────────────────────────────────────────────────────

class ActiveUserProfile {
  const ActiveUserProfile({required this.pubkeyHex, this.avatarUrl});
  final String pubkeyHex;
  final String? avatarUrl;
}

// ── GetActiveUserProfileUseCase ───────────────────────────────────────────────

/// Fetches the active user's pubkey and their avatar URL in a single call.
/// Used by any screen that needs to show the current user's avatar in the
/// reply composer (e.g. ThreadPage, ChannelPage).
@lazySingleton
class GetActiveUserProfileUseCase
    extends NoParamsUseCase<Either<Failure, ActiveUserProfile>> {
  final UserRepository _userRepository;
  final ProfileRepository _profileRepository;

  const GetActiveUserProfileUseCase(
    this._userRepository,
    this._profileRepository,
  );

  @override
  Future<Either<Failure, ActiveUserProfile>> call() async {
    final userResult = await _userRepository.getActiveUser();
    return userResult.fold(
      Left.new,
      (user) async {
        final profileResult =
            await _profileRepository.getOwnProfile(user.pubkeyHex);
        final avatarUrl =
            profileResult.fold((_) => null, (p) => p?.avatarUrl);
        return Right(ActiveUserProfile(
          pubkeyHex: user.pubkeyHex,
          avatarUrl: avatarUrl,
        ));
      },
    );
  }
}

// ── ImportKeyUseCase ──────────────────────────────────────────────────────────

@lazySingleton
class ImportKeyUseCase
    extends UseCase<Either<Failure, UserKeyEntity>, String> {
  final UserRepository _repository;
  const ImportKeyUseCase(this._repository);

  @override
  Future<Either<Failure, UserKeyEntity>> call(
    String nsec, {
    bool cached = false,
  }) {
    return _repository.importKey(nsec);
  }
}
