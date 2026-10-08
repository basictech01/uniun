import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/core/utils/fast_hash.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/repositories/unread_repository_impl.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: UnreadRepositoryImpl markSeen / markGroupSeen /
/// markPrivateGroupSeen / markConversationSeen row deletion scoping,
/// idempotency on no-match, and oldestUnreadTimeForGroup.
void main() {
  late Isar isar;
  late UnreadRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    repo = UnreadRepositoryImpl(isar: isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Future<List<String>> remainingIds() async =>
      (await isar.unreadNoteModels.where().findAll())
          .map((r) => r.eventId)
          .toList();

  group('markSeen', () {
    test('deletes exactly the matching eventId row', () async {
      await seedUnreadRow(isar, 'ev-1');
      await seedUnreadRow(isar, 'ev-2');

      final r = await repo.markSeen('ev-1');
      expect(r.isRight(), isTrue);
      expect(await remainingIds(), ['ev-2']);
    });

    test('idempotent: no matching row → Right, nothing deleted', () async {
      await seedUnreadRow(isar, 'ev-1');
      final r = await repo.markSeen('ghost');
      expect(r.isRight(), isTrue);
      expect(await remainingIds(), ['ev-1']);
    });
  });

  group('markGroupSeen', () {
    test(
      'deletes all rows of the group, leaves other groups + feed notes',
      () async {
        await seedUnreadRow(
          isar,
          'g1-a',
          kind: kGroupMessageKind,
          groupId: 'g-1',
        );
        await seedUnreadRow(
          isar,
          'g1-b',
          kind: kGroupMessageKind,
          groupId: 'g-1',
        );
        await seedUnreadRow(
          isar,
          'g2-a',
          kind: kGroupMessageKind,
          groupId: 'g-2',
        );
        await seedUnreadRow(isar, 'feed-note');

        final r = await repo.markGroupSeen('g-1');
        expect(r.isRight(), isTrue);
        expect(await remainingIds(), containsAll(['g2-a', 'feed-note']));
        expect(await remainingIds(), hasLength(2));
      },
    );

    test('unknown groupId → Right, no-op', () async {
      await seedUnreadRow(
        isar,
        'g1-a',
        kind: kGroupMessageKind,
        groupId: 'g-1',
      );
      expect((await repo.markGroupSeen('nowhere')).isRight(), isTrue);
      expect(await remainingIds(), ['g1-a']);
    });
  });

  group('markPrivateGroupSeen', () {
    test(
      'deletes only the private group rows — not a same-named public group',
      () async {
        await seedUnreadRow(
          isar,
          'pg-a',
          kind: kPrivateGroupKind,
          privateGroupId: 'shared-id',
        );
        await seedUnreadRow(
          isar,
          'pub-a',
          kind: kGroupMessageKind,
          groupId: 'shared-id',
        );

        final r = await repo.markPrivateGroupSeen('shared-id');
        expect(r.isRight(), isTrue);
        expect(await remainingIds(), ['pub-a']);
      },
    );
  });

  group('markConversationSeen', () {
    test('deletes all rows of the conversation, leaves others', () async {
      await seedUnreadRow(isar, 'dm-1', kind: kDmTextKind, conversationId: 7);
      await seedUnreadRow(isar, 'dm-2', kind: kDmFileKind, conversationId: 7);
      await seedUnreadRow(
        isar,
        'dm-other',
        kind: kDmTextKind,
        conversationId: 8,
      );

      final r = await repo.markConversationSeen(7);
      expect(r.isRight(), isTrue);
      expect(await remainingIds(), ['dm-other']);
    });

    test('unknown conversation → Right, no-op', () async {
      expect((await repo.markConversationSeen(999)).isRight(), isTrue);
    });
  });

  group('oldestUnreadTimeForGroup', () {
    test('returns the earliest created among the group rows', () async {
      final earliest = tNow.subtract(const Duration(hours: 3));
      await seedUnreadRow(
        isar,
        'g1-new',
        kind: kGroupMessageKind,
        groupId: 'g-1',
        created: tNow,
      );
      await seedUnreadRow(
        isar,
        'g1-old',
        kind: kGroupMessageKind,
        groupId: 'g-1',
        created: earliest,
      );
      await seedUnreadRow(
        isar,
        'g2-older',
        kind: kGroupMessageKind,
        groupId: 'g-2',
        created: tNow.subtract(const Duration(days: 1)),
      );

      final r = await repo.oldestUnreadTimeForGroup('g-1');
      // Isar round-trips DateTime as local time — compare instants.
      expect(r.getOrElse(() => null)!.isAtSameMomentAs(earliest), isTrue);
    });

    test('no rows for the group → Right(null)', () async {
      final r = await repo.oldestUnreadTimeForGroup('empty');
      expect(r.isRight(), isTrue);
      expect(r.getOrElse(() => tNow), isNull);
    });
  });

  group('live unread counts', () {
    test('a group count follows rows being added and read', () async {
      final seen = <int>[];
      final sub = repo.watchGroupUnreadCount('g1').listen(seen.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await seedUnreadRow(isar, 'a', kind: kGroupMessageKind, groupId: 'g1');
      await seedUnreadRow(isar, 'b', kind: kGroupMessageKind, groupId: 'g1');
      await seedUnreadRow(isar, 'c', kind: kGroupMessageKind, groupId: 'g2');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await repo.markGroupSeen('g1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(seen.first, 0);
      expect(seen, contains(2));
      expect(seen.last, 0);
    });

    test('a private group count ignores other groups', () async {
      await seedUnreadRow(
        isar,
        'a',
        kind: kPrivateGroupKind,
        privateGroupId: 'p1',
      );
      await seedUnreadRow(
        isar,
        'b',
        kind: kPrivateGroupKind,
        privateGroupId: 'p2',
      );

      expect(await repo.watchPrivateGroupUnreadCount('p1').first, 1);
    });

    test('a DM count is 0 while no conversation exists', () async {
      expect(await repo.watchDmUnreadCount(kBobPub).first, 0);
    });

    test('a DM count counts only that conversation', () async {
      await seedDmConversation(isar, kAlicePub);
      await seedDmConversation(isar, kBobPub);
      final alice = fastHash(kAlicePub);
      final bob = fastHash(kBobPub);
      await seedUnreadRow(isar, 'a1', kind: kDmTextKind, conversationId: alice);
      await seedUnreadRow(isar, 'a2', kind: kDmTextKind, conversationId: alice);
      await seedUnreadRow(isar, 'b1', kind: kDmTextKind, conversationId: bob);

      expect(await repo.watchDmUnreadCount(kAlicePub).first, 2);
      expect(await repo.watchDmUnreadCount(kBobPub).first, 1);
    });

    test('nothing unread is 0, not an error', () async {
      expect(await repo.watchGroupUnreadCount('none').first, 0);
    });
  });

  group('oldest unread time for private groups and DMs', () {
    test('a private group returns its oldest unread row only', () async {
      final t0 = DateTime.utc(2026, 1, 1);
      await seedUnreadRow(
        isar,
        'a',
        kind: kPrivateGroupKind,
        privateGroupId: 'p1',
        created: t0.add(const Duration(hours: 2)),
      );
      await seedUnreadRow(
        isar,
        'b',
        kind: kPrivateGroupKind,
        privateGroupId: 'p1',
        created: t0.add(const Duration(hours: 1)),
      );
      await seedUnreadRow(
        isar,
        'c',
        kind: kPrivateGroupKind,
        privateGroupId: 'p2',
        created: t0,
      );

      final r = await repo.oldestUnreadTimeForPrivateGroup('p1');

      expect(
        r.getOrElse(() => null)!.toUtc(),
        t0.add(const Duration(hours: 1)),
      );
    });

    test('a private group with nothing unread is null', () async {
      final r = await repo.oldestUnreadTimeForPrivateGroup('none');

      expect(r.getOrElse(() => DateTime(1)), isNull);
    });

    test('a DM returns the oldest unread row of that conversation', () async {
      final t0 = DateTime.utc(2026, 1, 1);
      await seedDmConversation(isar, kAlicePub);
      await seedDmConversation(isar, kBobPub);
      await seedUnreadRow(
        isar,
        'a1',
        kind: kDmTextKind,
        conversationId: fastHash(kAlicePub),
        created: t0.add(const Duration(hours: 3)),
      );
      await seedUnreadRow(
        isar,
        'a2',
        kind: kDmTextKind,
        conversationId: fastHash(kAlicePub),
        created: t0.add(const Duration(hours: 1)),
      );
      await seedUnreadRow(
        isar,
        'b1',
        kind: kDmTextKind,
        conversationId: fastHash(kBobPub),
        created: t0,
      );

      final r = await repo.oldestUnreadTimeForDm(kAlicePub);

      expect(
        r.getOrElse(() => null)!.toUtc(),
        t0.add(const Duration(hours: 1)),
      );
    });

    test('a DM with no conversation or nothing unread is null', () async {
      expect(
        (await repo.oldestUnreadTimeForDm(
          kBobPub,
        )).getOrElse(() => DateTime(1)),
        isNull,
      );
      await seedDmConversation(isar, kBobPub);
      expect(
        (await repo.oldestUnreadTimeForDm(
          kBobPub,
        )).getOrElse(() => DateTime(1)),
        isNull,
      );
    });
  });
}
