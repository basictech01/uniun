import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart';
import 'package:uniun/features/vishnu/drawer/utils/drawer_search.dart';

/// Edge-case coverage for `buildDrawerSearchResults`. The companion file
/// `drawer_search_test.dart` covers the happy path (one match per section);
/// this file fills in the gaps: ordering, trimming, both directions of the
/// unread / new-reference flags, avatar passthrough, and empty / multi-match
/// behaviour.
DrawerLoaded _state({
  List<DrawerGroupItem> groups = const [],
  List<DrawerPrivateGroupItem> privateGroups = const [],
  List<DrawerDmItem> dms = const [],
  List<DrawerFollowedNoteItem> followedNotes = const [],
  List<DrawerFollowedUserItem> followedUsers = const [],
}) {
  return DrawerLoaded(
    userName: 'me',
    npub: 'npub',
    pubkeyHex: 'hex',
    followedNotes: followedNotes,
    groups: groups,
    privateGroups: privateGroups,
    dms: dms,
    followedUsers: followedUsers,
    myRelays: const [],
  );
}

void main() {
  group('buildDrawerSearchResults — query normalisation', () {
    final state = _state(
      groups: const [DrawerGroupItem(id: 'c1', name: 'Alice')],
    );

    test('trims leading + trailing whitespace before matching', () {
      expect(buildDrawerSearchResults(state, '  alice  '), hasLength(1));
    });

    test('whitespace-only query returns no results', () {
      expect(buildDrawerSearchResults(state, '\t\n  '), isEmpty);
    });

    test('match is case-insensitive in both directions', () {
      // Query upper, label lower
      expect(
        buildDrawerSearchResults(
          _state(groups: const [DrawerGroupItem(id: 'c', name: 'alice')]),
          'ALICE',
        ),
        hasLength(1),
      );
      // Query lower, label mixed
      expect(
        buildDrawerSearchResults(
          _state(groups: const [DrawerGroupItem(id: 'c', name: 'AlIcE')]),
          'alice',
        ),
        hasLength(1),
      );
    });

    test('substring matches at start, middle, and end of the label', () {
      final s = _state(
        groups: const [
          DrawerGroupItem(id: 's', name: 'devops-team'),
          DrawerGroupItem(id: 'm', name: 'team-devops'),
          DrawerGroupItem(id: 'e', name: 'about-devops'),
        ],
      );
      expect(buildDrawerSearchResults(s, 'devops'), hasLength(3));
    });
  });

  group('buildDrawerSearchResults — result ordering', () {
    test('results are emitted in section order regardless of input order', () {
      final state = _state(
        // Each section has one matching item — assert the section iteration
        // order groups → privateGroups → dms → followedNotes →
        // followedUsers is preserved.
        followedUsers: const [
          DrawerFollowedUserItem(pubkey: 'u', name: 'foo user'),
        ],
        followedNotes: const [
          DrawerFollowedNoteItem(eventId: 'n', contentPreview: 'foo note'),
        ],
        dms: const [DrawerDmItem(pubkey: 'd', name: 'foo dm')],
        privateGroups: const [
          DrawerPrivateGroupItem(id: 'p', name: 'foo private'),
        ],
        groups: const [DrawerGroupItem(id: 'c', name: 'foo group')],
      );
      final results = buildDrawerSearchResults(state, 'foo');
      expect(
        results.map((r) => r.kind).toList(),
        [
          DrawerSearchKind.group,
          DrawerSearchKind.privateGroup,
          DrawerSearchKind.dm,
          DrawerSearchKind.followedNote,
          DrawerSearchKind.followedUser,
        ],
      );
    });

    test('multiple matches in the same section keep their input order', () {
      final state = _state(
        groups: const [
          DrawerGroupItem(id: 'c1', name: 'devops-prod'),
          DrawerGroupItem(id: 'c2', name: 'random'),
          DrawerGroupItem(id: 'c3', name: 'devops-staging'),
        ],
      );
      final results = buildDrawerSearchResults(state, 'devops');
      expect(results.map((r) => r.id).toList(), ['c1', 'c3']);
    });
  });

  group('buildDrawerSearchResults — unread / new-reference flags', () {
    test('group with hasUnread=false yields hasUnread=false on the hit',
        () {
      final state = _state(
        groups: const [
          DrawerGroupItem(id: 'c', name: 'news'),
        ],
      );
      expect(buildDrawerSearchResults(state, 'news').single.hasUnread,
          isFalse);
    });

    test('private group hasUnread flag flows through', () {
      final state = _state(
        privateGroups: const [
          DrawerPrivateGroupItem(id: 'g', name: 'inner', unreadCount: 1),
        ],
      );
      expect(buildDrawerSearchResults(state, 'inner').single.hasUnread,
          isTrue);
    });

    test('DM unreadCount > 0 → hasUnread=true; == 0 → hasUnread=false', () {
      final unread = _state(
        dms: const [DrawerDmItem(pubkey: 'p1', name: 'bob', unreadCount: 3)],
      );
      final clean = _state(
        dms: const [DrawerDmItem(pubkey: 'p2', name: 'bob')],
      );
      expect(buildDrawerSearchResults(unread, 'bob').single.hasUnread, isTrue);
      expect(buildDrawerSearchResults(clean, 'bob').single.hasUnread, isFalse);
    });

    test(
        'followed note newReferenceCount > 0 → hasUnread=true; == 0 → false',
        () {
      final hot = _state(
        followedNotes: const [
          DrawerFollowedNoteItem(
              eventId: 'e1', contentPreview: 'topic', newReferenceCount: 1),
        ],
      );
      final cold = _state(
        followedNotes: const [
          DrawerFollowedNoteItem(eventId: 'e2', contentPreview: 'topic'),
        ],
      );
      expect(buildDrawerSearchResults(hot, 'topic').single.hasUnread, isTrue);
      expect(buildDrawerSearchResults(cold, 'topic').single.hasUnread,
          isFalse);
    });
  });

  group('buildDrawerSearchResults — passthrough fields', () {
    test('label is the original-case label, not the lowercased query', () {
      // The display label must preserve the source casing — the lowercase
      // form is used only for the substring match.
      final state = _state(
        groups: const [DrawerGroupItem(id: 'c', name: 'DevOps')],
      );
      expect(buildDrawerSearchResults(state, 'devops').single.label, 'DevOps');
    });

    test('id carries the surface-specific identifier', () {
      // DMs key by pubkey; followed notes by eventId — the row uses these to
      // navigate, so they must reach the result intact.
      final state = _state(
        dms: const [DrawerDmItem(pubkey: 'pk-bob', name: 'Bob')],
        followedNotes: const [
          DrawerFollowedNoteItem(eventId: 'evt-7', contentPreview: 'Bob said'),
        ],
        followedUsers: const [
          DrawerFollowedUserItem(pubkey: 'pk-alice', name: 'Alice Bob'),
        ],
      );
      final byKind = {
        for (final r in buildDrawerSearchResults(state, 'bob')) r.kind: r.id,
      };
      expect(byKind[DrawerSearchKind.dm], 'pk-bob');
      expect(byKind[DrawerSearchKind.followedNote], 'evt-7');
      expect(byKind[DrawerSearchKind.followedUser], 'pk-alice');
    });

    test('DM and followed-user avatar URLs flow through to the hit', () {
      final state = _state(
        dms: const [
          DrawerDmItem(
              pubkey: 'p1', name: 'avatar-dm', avatarUrl: 'https://dm.png'),
        ],
        followedUsers: const [
          DrawerFollowedUserItem(
              pubkey: 'p2',
              name: 'avatar-user',
              avatarUrl: 'https://user.png'),
        ],
      );
      final dmHit = buildDrawerSearchResults(state, 'avatar-dm').single;
      final userHit = buildDrawerSearchResults(state, 'avatar-user').single;
      expect(dmHit.avatarUrl, 'https://dm.png');
      expect(userHit.avatarUrl, 'https://user.png');
    });

    test('groups and followed notes do NOT carry an avatar URL', () {
      // Sanity: only DM + followedUser have avatars in the data model. The
      // other DrawerSearchResults must report null so the row picks the
      // correct icon strategy.
      final state = _state(
        groups: const [DrawerGroupItem(id: 'c', name: 'noavatar')],
        followedNotes: const [
          DrawerFollowedNoteItem(eventId: 'n', contentPreview: 'noavatar'),
        ],
      );
      for (final r in buildDrawerSearchResults(state, 'noavatar')) {
        expect(r.avatarUrl, isNull,
            reason: '${r.kind} should not surface an avatar');
      }
    });
  });

  group('buildDrawerSearchResults — empty / sparse states', () {
    test('totally empty state always returns empty list', () {
      expect(buildDrawerSearchResults(_state(), 'anything'), isEmpty);
    });

    test('non-matching items in populated sections still return empty', () {
      final state = _state(
        groups: const [DrawerGroupItem(id: 'c', name: 'general')],
        dms: const [DrawerDmItem(pubkey: 'p', name: 'alice')],
      );
      expect(buildDrawerSearchResults(state, 'zzz-no-match'), isEmpty);
    });

    test('match against label text only — not against id / pubkey / eventId',
        () {
      // The search filters by visible label, NOT by hidden identifiers.
      // A user searching for a pubkey fragment wouldn't expect a result
      // unless the label itself contains it.
      final state = _state(
        groups: const [DrawerGroupItem(id: 'group-id-abc', name: 'chat')],
        dms: const [DrawerDmItem(pubkey: 'pk-xyz', name: 'Bob')],
      );
      expect(buildDrawerSearchResults(state, 'group-id-abc'), isEmpty);
      expect(buildDrawerSearchResults(state, 'pk-xyz'), isEmpty);
    });
  });
}
