import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/user_key_model.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl extends UserRepository {
  final Isar isar;
  final FlutterSecureStorage _secureStorage;

  // Key used in flutter_secure_storage for the user's nsec.
  static const _nsecStorageKey = 'uniun_nsec';

  UserRepositoryImpl({required this.isar})
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<Either<Failure, UserKeyEntity>> generateKey() async {
    try {
      final keychain = Keychain.generate();
      return _persistKey(
        privkeyHex: keychain.private,
        pubkeyHex: keychain.public,
      );
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserKeyEntity>> importKey(String nsecOrHex) async {
    try {
      final String privkeyHex;
      if (nsecOrHex.startsWith('nsec1')) {
        privkeyHex = Nip19.decodePrivkey(nsecOrHex);
        if (privkeyHex.isEmpty) {
          return const Left(Failure.errorFailure('Invalid nsec — decoding failed'));
        }
      } else if (nsecOrHex.length == 64) {
        privkeyHex = nsecOrHex; // raw 32-byte hex
      } else {
        return const Left(Failure.errorFailure('Unrecognised key format'));
      }

      final keychain = Keychain(privkeyHex);
      return _persistKey(
        privkeyHex: keychain.private,
        pubkeyHex: keychain.public,
      );
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserKeyEntity>> getActiveUser() async {
    try {
      final model = await isar.userKeyModels.where().findFirst();
      if (model == null) {
        return const Left(Failure.notFoundFailure('No active user'));
      }

      final nsec = await _secureStorage.read(key: _nsecStorageKey);
      if (nsec == null) {
        // Isar has a key row but secure storage is cleared (e.g. app re-install
        // on Android without backup). Treat as logged-out.
        await isar.writeTxn(() async => isar.userKeyModels.clear());
        return const Left(Failure.notFoundFailure('Private key missing — please log in again'));
      }

      return Right(model.toDomain(nsec: nsec));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _secureStorage.delete(key: _nsecStorageKey);
      await isar.writeTxn(() async => isar.userKeyModels.clear());
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<Either<Failure, UserKeyEntity>> _persistKey({
    required String privkeyHex,
    required String pubkeyHex,
  }) async {
    try {
      final nsec = Nip19.encodePrivkey(privkeyHex);
      final npub = Nip19.encodePubkey(pubkeyHex);
      final now = DateTime.now();

      // Private key → secure storage (Android Keystore / iOS Keychain)
      await _secureStorage.write(key: _nsecStorageKey, value: nsec);

      // Public identity → Isar (safe to store, not a secret)
      final existing = await isar.userKeyModels.where().findFirst();
      final model = existing ?? UserKeyModel();
      model.pubkeyHex = pubkeyHex;
      model.npub = npub;
      model.createdAt = now;

      await isar.writeTxn(() async => isar.userKeyModels.put(model));

      return Right(UserKeyEntity(
        pubkeyHex: pubkeyHex,
        npub: npub,
        nsec: nsec,
        createdAt: now,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
