import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/repositories/followed_note_repository_impl.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';
import '../../_helpers/stub_user_repository.dart';

/// End-to-end tests for [FollowedNoteRepositoryImpl]. Real Isar so the derived
/// `newReferenceCount` join against the edge + unread tables is exercised.
void main() {
  late Isar isar;
  late FollowedNoteRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    // Signer with a logged-out stub — `sign()` returns null so rows are
    // written with `signedNostrEvent = null`. These tests assert on Isar
    // shape only; the wire form is covered by mesh integration tests.
    final signer = MeshEventSigner(StubUserRepository()..keys = null);
    repo = FollowedNoteRepositoryImpl(isar: isar, signer: signer);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Future<void> seedEdge(String parent, String child) =>
      seedRelationEdge(isar, parent, child);
  Future<void> seedUnread(String eventId, {int kind = 1}) =>
      seedUnreadRow(isar, eventId, kind: kind);

  // ── followNote / unfollowNote ────────────────────────────────────────────

  group('followNote', () {
    test('creates row on first follow', () async {
      final r = await repo.followNote('ev-1', 'preview');
      expect(r.isRight(), isTrue);
      final rows = await isar.followedNoteModels.where().findAll();
      expect(rows, hasLength(1));
      expect(rows.single.eventId, 'ev-1');
      expect(rows.single.contentPreview, 'preview');
      expect(rows.single.followedAt, isNotNull);
    });

    test('second follow of same eventId is a no-op Right', () async {
      await repo.followNote('ev-1', 'first-preview');
      await repo.followNote('ev-1', 'second-preview');
      final rows = await isar.followedNoteModels.where().findAll();
      expect(rows, hasLength(1));
      expect(
        rows.single.contentPreview,
        'first-preview',
        reason: 'second follow must not overwrite existing metadata',
      );
    });

    test('unicode + emoji + RTL preview persist', () async {
      const payload = '🚨 ${Content.unicode} ${Content.rtl}';
      await repo.followNote('ev-u', payload);
      final row = (await isar.followedNoteModels.where().findAll()).single;
      expect(row.contentPreview, payload);
    });
  });

  group('unfollowNote', () {
    test('tombstones the row (mesh-idempotent undo per §5a)', () async {
      await repo.followNote('ev-1', 'x');
      await repo.unfollowNote('ev-1');
      // Row survives as a tombstone so mesh negentropy propagates the undo.
      final row = (await isar.followedNoteModels.where().findAll()).single;
      expect(row.removedAt, isNotNull);
      // getAll() hides tombstones from the UI.
      final active = (await repo.getAll()).getOrElse(() => throw 'x');
      expect(active, isEmpty);
    });

    test('unfollow non-existent id is a no-op Right', () async {
      final r = await repo.unfollowNote('ghost');
      expect(r.isRight(), isTrue);
    });
  });

  // ── isFollowed / watchIsFollowed ─────────────────────────────────────────

  group('isFollowed', () {
    test('returns true iff a row exists', () async {
      await repo.followNote('ev-1', 'x');
      expect((await repo.isFollowed('ev-1')).getOrElse(() => false), isTrue);
      expect((await repo.isFollowed('ghost')).getOrElse(() => true), isFalse);
    });
  });

  group('watchIsFollowed', () {
    test(
      'fires immediately + emits false→true→false on follow/unfollow',
      () async {
        final emissions = <bool>[];
        final sub = repo.watchIsFollowed('ev-1').listen(emissions.add);
        // Give Isar's watcher a tick to deliver the initial fire.
        await Future.delayed(const Duration(milliseconds: 30));
        await repo.followNote('ev-1', 'x');
        await Future.delayed(const Duration(milliseconds: 30));
        await repo.unfollowNote('ev-1');
        await Future.delayed(const Duration(milliseconds: 30));
        await sub.cancel();
        expect(emissions.first, isFalse);
        expect(emissions, contains(true));
        expect(emissions.last, isFalse);
      },
    );
  });

  // ── getAll + derived newReferenceCount ───────────────────────────────────

  group('getAll', () {
    test('empty when nothing followed', () async {
      final r = await repo.getAll();
      expect(r.getOrElse(() => throw 'x'), isEmpty);
    });

    test('sorts newest followedAt first', () async {
      await repo.followNote('a', 'A');
      await Future.delayed(const Duration(milliseconds: 5));
      await repo.followNote('b', 'B');
      await Future.delayed(const Duration(milliseconds: 5));
      await repo.followNote('c', 'C');
      final list = (await repo.getAll()).getOrElse(() => throw 'x');
      expect(list.map((e) => e.eventId).toList(), ['c', 'b', 'a']);
    });

    test('newReferenceCount = number of children that STILL have a live '
        'unread row', () async {
      await repo.followNote('root', 'r');
      await seedEdge('root', 'child-1');
      await seedEdge('root', 'child-2');
      await seedEdge('root', 'child-3');
      // Only two children are still unread.
      await seedUnread('child-1');
      await seedUnread('child-2');

      final list = (await repo.getAll()).getOrElse(() => throw 'x');
      expect(list.single.newReferenceCount, 2);
    });

    test('newReferenceCount is 0 when no edges exist', () async {
      await repo.followNote('lonely', 'x');
      final list = (await repo.getAll()).getOrElse(() => throw 'x');
      expect(list.single.newReferenceCount, 0);
    });

    test(
      'newReferenceCount is 0 when edges exist but children are all read',
      () async {
        await repo.followNote('root', 'x');
        await seedEdge('root', 'c-1');
        // No unread row seeded → child is "read".
        final list = (await repo.getAll()).getOrElse(() => throw 'x');
        expect(list.single.newReferenceCount, 0);
      },
    );
  });

  // ── nested replies ───────────────────────────────────────────────────────

  group('replies of replies', () {
    test(
      'the badge counts unread notes at every depth below the note',
      () async {
        await repo.followNote('root', 'x');
        await seedEdge('root', 'r1');
        await seedEdge('r1', 'r2');
        await seedEdge('r2', 'r3');
        await seedUnread('r3');
        await seedUnread('r1');
        await seedUnread('elsewhere');

        final list = (await repo.getAll()).getOrElse(() => throw 'x');

        expect(list.single.newReferenceCount, 2);
      },
    );

    test('reading the deep note drops the count by one', () async {
      await repo.followNote('root', 'x');
      await seedEdge('root', 'r1');
      await seedEdge('r1', 'r2');
      await seedUnread('r1');
      await seedUnread('r2');
      await isar.writeTxn(
        () => isar.unreadNoteModels.filter().eventIdEqualTo('r2').deleteAll(),
      );

      final list = (await repo.getAll()).getOrElse(() => throw 'x');

      expect(list.single.newReferenceCount, 1);
    });

    test('a reference cycle does not loop forever', () async {
      await repo.followNote('a', 'x');
      await seedEdge('a', 'b');
      await seedEdge('b', 'a');
      await seedUnread('b');

      final list = (await repo.getAll()).getOrElse(() => throw 'x');

      expect(list.single.newReferenceCount, 1);
    });
  });

  // ── watchThreadUnreadMarkers ─────────────────────────────────────────────

  group('watchThreadUnreadMarkers', () {
    test('an unread reply is marked, its parent shows unread inside', () async {
      await repo.followNote('root', 'x');
      await seedEdge('root', 'r1');
      await seedEdge('r1', 'r2');
      await seedEdge('r2', 'r3');
      await seedUnread('r3');

      final m = await repo.watchThreadUnreadMarkers(['r1', 'r2', 'r3']).first;

      expect(m['r3']!.unread, isTrue);
      expect(m['r3']!.unreadInside, isFalse);
      expect(m['r2']!.unread, isFalse);
      expect(m['r2']!.unreadInside, isTrue);
      expect(m['r1']!.unreadInside, isTrue);
    });

    test('a note outside every followed tree gets no marker', () async {
      await repo.followNote('root', 'x');
      await seedEdge('other', 'o1');
      await seedUnread('o1');

      final m = await repo.watchThreadUnreadMarkers(['other', 'o1']).first;

      expect(m, isEmpty);
    });

    test('nothing followed means no markers at all', () async {
      await seedEdge('root', 'r1');
      await seedUnread('r1');

      expect(
        await repo.watchThreadUnreadMarkers(['root', 'r1']).first,
        isEmpty,
      );
    });

    test('a read branch is left out', () async {
      await repo.followNote('root', 'x');
      await seedEdge('root', 'a');
      await seedEdge('root', 'b');
      await seedUnread('b');

      final m = await repo.watchThreadUnreadMarkers(['a', 'b']).first;

      expect(m.keys, ['b']);
    });

    test('the followed note itself can carry a dot', () async {
      await repo.followNote('root', 'x');
      await seedUnread('root');

      final m = await repo.watchThreadUnreadMarkers(['root']).first;

      expect(m['root']!.unread, isTrue);
    });

    test('opening the new note clears it and the trail above', () async {
      await repo.followNote('root', 'x');
      await seedEdge('root', 'r1');
      await seedEdge('r1', 'r2');
      await seedUnread('r2');
      final seen = <Map<String, Object?>>[];
      final sub = repo
          .watchThreadUnreadMarkers(['r1', 'r2'])
          .listen((m) => seen.add({for (final e in m.entries) e.key: e.value}));
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await isar.writeTxn(
        () => isar.unreadNoteModels.filter().eventIdEqualTo('r2').deleteAll(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await sub.cancel();

      expect(seen.first.keys, containsAll(['r1', 'r2']));
      expect(seen.last, isEmpty);
    });

    test('an empty id list is empty, not an error', () async {
      await repo.followNote('root', 'x');
      await seedUnread('root');

      expect(await repo.watchThreadUnreadMarkers(const []).first, isEmpty);
    });
  });

  // ── Scale ────────────────────────────────────────────────────────────────

  group('scale', () {
    test('50 followed notes + edge/unread joins terminate quickly', () async {
      for (var i = 0; i < 50; i++) {
        await repo.followNote('n-$i', 'preview $i');
        await seedEdge('n-$i', 'c-$i');
        await seedUnread('c-$i');
      }
      final list = (await repo.getAll()).getOrElse(() => throw 'x');
      expect(list, hasLength(50));
      expect(list.every((e) => e.newReferenceCount == 1), isTrue);
    });
  });
}
