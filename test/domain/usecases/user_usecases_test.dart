import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/logout_session_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

import '../../_helpers/fixtures.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockLogoutSessionRepository extends Mock
    implements LogoutSessionRepository {}

void main() {
  late _MockUserRepository userRepo;
  late _MockProfileRepository profileRepo;

  setUpAll(() {
    registerFallbackValue(aUserKey());
  });

  setUp(() {
    userRepo = _MockUserRepository();
    profileRepo = _MockProfileRepository();
  });

  test('GetActiveUserUseCase delegates to getActiveUser', () async {
    when(
      () => userRepo.getActiveUser(),
    ).thenAnswer((_) async => Right(aUserKey()));

    final result = await GetActiveUserUseCase(userRepo).call();

    expect(result.isRight(), isTrue);
  });

  group('GetActiveUserKeysUseCase', () {
    test('decodes nsec into raw hex privkey', () async {
      when(() => userRepo.getActiveUser()).thenAnswer(
        (_) async => Right(
          aUserKey(pubkeyHex: 'pk', nsec: Nip19.encodePrivkey(kTestPrivHex)),
        ),
      );

      final result = await GetActiveUserKeysUseCase(userRepo).call();

      expect(result.isRight(), isTrue);
      final keys = result.getOrElse(
        () => const UserSigningKeys(privkeyHex: '', pubkeyHex: ''),
      );
      expect(keys.pubkeyHex, 'pk');
      expect(keys.privkeyHex, kTestPrivHex);
    });

    test('a repository failure propagates verbatim', () async {
      const failure = Failure.errorFailure('no active user');
      when(
        () => userRepo.getActiveUser(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await GetActiveUserKeysUseCase(userRepo).call();

      expect(result, const Left<Failure, UserSigningKeys>(failure));
    });
  });

  group('GetActiveUserProfileUseCase', () {
    test('combines the active user with their own profile avatar', () async {
      when(
        () => userRepo.getActiveUser(),
      ).thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk')));
      when(
        () => profileRepo.getOwnProfile('pk'),
      ).thenAnswer((_) async => Right(aProfile(avatarUrl: 'https://img')));

      final result = await GetActiveUserProfileUseCase(
        userRepo,
        profileRepo,
      ).call();

      final profile = result.getOrElse(
        () => const ActiveUserProfile(pubkeyHex: ''),
      );
      expect(profile.pubkeyHex, 'pk');
      expect(profile.avatarUrl, 'https://img');
    });

    test('degrades to a null avatar when the profile lookup fails', () async {
      when(
        () => userRepo.getActiveUser(),
      ).thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk')));
      when(
        () => profileRepo.getOwnProfile('pk'),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('not found')));

      final result = await GetActiveUserProfileUseCase(
        userRepo,
        profileRepo,
      ).call();

      final profile = result.getOrElse(
        () => const ActiveUserProfile(pubkeyHex: ''),
      );
      expect(profile.avatarUrl, isNull);
    });

    test(
      'a missing active user short-circuits before touching profiles',
      () async {
        const failure = Failure.errorFailure('no active user');
        when(
          () => userRepo.getActiveUser(),
        ).thenAnswer((_) async => const Left(failure));

        final result = await GetActiveUserProfileUseCase(
          userRepo,
          profileRepo,
        ).call();

        expect(result, const Left<Failure, ActiveUserProfile>(failure));
        verifyZeroInteractions(profileRepo);
      },
    );
  });

  test('ImportKeyUseCase delegates to importKey', () async {
    when(
      () => userRepo.importKey('nsec1...'),
    ).thenAnswer((_) async => Right(aUserKey()));

    await ImportKeyUseCase(userRepo).call('nsec1...');

    verify(() => userRepo.importKey('nsec1...')).called(1);
  });

  group('LogoutUseCase', () {
    late _MockLogoutSessionRepository session;

    setUp(() {
      session = _MockLogoutSessionRepository();
      when(() => userRepo.logout()).thenAnswer((_) async => const Right(unit));
    });

    test('clears session and model files before removing identity', () async {
      when(
        () => session.clear(keepModelFiles: false),
      ).thenAnswer((_) async => const Right(unit));

      final result = await LogoutUseCase(
        userRepo,
        session,
      ).call(const LogoutParams());

      expect(result, const Right<Failure, Unit>(unit));
      verifyInOrder([
        () => session.clear(keepModelFiles: false),
        () => userRepo.logout(),
      ]);
    });

    test('keeps model files when selected', () async {
      when(
        () => session.clear(keepModelFiles: true),
      ).thenAnswer((_) async => const Right(unit));

      await LogoutUseCase(
        userRepo,
        session,
      ).call(const LogoutParams(keepModelFiles: true));

      verify(() => session.clear(keepModelFiles: true)).called(1);
      verify(() => userRepo.logout()).called(1);
    });

    test('keeps identity if session cleanup fails', () async {
      when(
        () => session.clear(keepModelFiles: false),
      ).thenThrow(StateError('cleanup failed'));

      final result = await LogoutUseCase(
        userRepo,
        session,
      ).call(const LogoutParams());

      expect(result.isLeft(), isTrue);
      verifyNever(() => userRepo.logout());
    });
  });
}
