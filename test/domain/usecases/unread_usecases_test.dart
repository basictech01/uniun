import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/repositories/unread_repository.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';

class _MockUnreadRepository extends Mock implements UnreadRepository {}

void main() {
  late _MockUnreadRepository repo;

  setUp(() {
    repo = _MockUnreadRepository();
  });

  test('MarkUnreadSeenUseCase delegates to markSeen', () async {
    when(() => repo.markSeen('n1')).thenAnswer((_) async => const Right(unit));

    final result = await MarkUnreadSeenUseCase(repo).call('n1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('MarkGroupSeenUseCase delegates to markGroupSeen', () async {
    when(
      () => repo.markGroupSeen('g1'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await MarkGroupSeenUseCase(repo).call('g1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test(
    'MarkPrivateGroupSeenUseCase delegates to markPrivateGroupSeen',
    () async {
      when(
        () => repo.markPrivateGroupSeen('pg1'),
      ).thenAnswer((_) async => const Right(unit));

      final result = await MarkPrivateGroupSeenUseCase(repo).call('pg1');

      expect(result, const Right<Failure, Unit>(unit));
    },
  );

  test(
    'MarkConversationSeenUseCase delegates to markConversationSeen',
    () async {
      when(
        () => repo.markConversationSeen(7),
      ).thenAnswer((_) async => const Right(unit));

      final result = await MarkConversationSeenUseCase(repo).call(7);

      expect(result, const Right<Failure, Unit>(unit));
    },
  );

  test('GetGroupOldestUnreadTimeUseCase delegates to '
      'oldestUnreadTimeForGroup', () async {
    final time = DateTime(2026, 1, 1);
    when(
      () => repo.oldestUnreadTimeForGroup('g1'),
    ).thenAnswer((_) async => Right(time));

    final result = await GetGroupOldestUnreadTimeUseCase(repo).call('g1');

    expect(result, Right<Failure, DateTime?>(time));
  });

  test('WatchGroupUnreadCountUseCase streams the repository count', () async {
    when(
      () => repo.watchGroupUnreadCount('g1'),
    ).thenAnswer((_) => Stream.fromIterable([0, 2, 1]));

    expect(await WatchGroupUnreadCountUseCase(repo).call('g1').toList(), [
      0,
      2,
      1,
    ]);
  });

  test(
    'WatchPrivateGroupUnreadCountUseCase streams the repository count',
    () async {
      when(
        () => repo.watchPrivateGroupUnreadCount('p1'),
      ).thenAnswer((_) => Stream.fromIterable([3]));

      expect(
        await WatchPrivateGroupUnreadCountUseCase(repo).call('p1').toList(),
        [3],
      );
    },
  );

  test('WatchDmUnreadCountUseCase streams the repository count', () async {
    when(
      () => repo.watchDmUnreadCount('pk'),
    ).thenAnswer((_) => Stream.fromIterable([1, 0]));

    expect(await WatchDmUnreadCountUseCase(repo).call('pk').toList(), [1, 0]);
  });

  test('GetPrivateGroupOldestUnreadTimeUseCase delegates', () async {
    final t = DateTime.utc(2026);
    when(
      () => repo.oldestUnreadTimeForPrivateGroup('p1'),
    ).thenAnswer((_) async => Right(t));

    expect(
      await GetPrivateGroupOldestUnreadTimeUseCase(repo).call('p1'),
      Right<Failure, DateTime?>(t),
    );
  });

  test('GetDmOldestUnreadTimeUseCase delegates', () async {
    when(
      () => repo.oldestUnreadTimeForDm('pk'),
    ).thenAnswer((_) async => const Right(null));

    expect(
      await GetDmOldestUnreadTimeUseCase(repo).call('pk'),
      const Right<Failure, DateTime?>(null),
    );
  });
}
