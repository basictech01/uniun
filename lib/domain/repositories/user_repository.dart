import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';

abstract class UserRepository {
  /// Generate a new Nostr keypair and save it locally.
  Future<Either<Failure, UserKeyEntity>> generateKey();

  /// Import an existing keypair from a nsec string.
  Future<Either<Failure, UserKeyEntity>> importKey(String nsec);

  /// Get the currently active user's keypair. Returns notFoundFailure if no user.
  Future<Either<Failure, UserKeyEntity>> getActiveUser();

  /// Remove the stored keypair. Use LogoutUseCase for full account logout.
  Future<Either<Failure, Unit>> logout();

  /// Returns the active user's keys in raw hex form, ready for use in
  /// background isolates (e.g. the Gateway) where FlutterSecureStorage and
  /// SharedPreferences plugins are unavailable. Returns null when no active
  /// user is logged in or the stored keys are inconsistent.
  Future<({String privkeyHex, String pubkeyHex})?> getActiveKeysHex();
}
