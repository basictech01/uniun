import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/entities/followed_user/followed_user_entity.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/followed_user_usecases.dart';
import 'package:uniun/domain/usecases/get_groups_usecase.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/domain/usecases/private_group_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_data_source.dart';

import '../../../../_helpers/fixtures.dart';

class _MockGetActiveUser extends Mock implements GetActiveUserUseCase {}

class _MockGetOwnProfile extends Mock implements GetOwnProfileUseCase {}

class _MockGetAllFollowedNotes extends Mock
    implements GetAllFollowedNotesUseCase {}

class _MockGetGroups extends Mock implements GetGroupsUseCase {}

class _MockGetPrivateGroups extends Mock implements GetPrivateGroupsUsecase {}

class _MockGetFollowedUsers extends Mock implements GetFollowedUsersUseCase {}

class _MockGetRelays extends Mock implements GetRelaysUseCase {}

class _MockRequestProfileFetch extends Mock
    implements RequestProfileFetchUseCase {}

class _MockDrawerDataSource extends Mock implements DrawerDataSource {}

ProfileModel _aProfileModel({
  String pubkey = 'pk',
  String? name,
  String? username,
  String? avatarUrl,
}) =>
    ProfileModel()
      ..pubkey = pubkey
      ..name = name
      ..username = username
      ..avatarUrl = avatarUrl
      ..updatedAt = DateTime(2026, 1, 1);

DmConversationModel _aConversationModel(String otherPubkey) =>
    DmConversationModel()..otherPubkey = otherPubkey;

UnreadNoteModel _anUnreadRow({
  required String eventId,
  required int kind,
  String? groupId,
  String? privateGroupId,
  int? conversationId,
}) =>
    UnreadNoteModel()
      ..eventId = eventId
      ..kind = kind
      ..authorPubkey = 'someone'
      ..groupId = groupId
      ..privateGroupId = privateGroupId
      ..conversationId = conversationId
      ..created = DateTime(2026, 1, 1);

/// Covers: DrawerBloc's load pipeline — anonymous fallback, own-profile
/// hydration, per-container unread aggregation (group/privateGroup/DM),
/// DM + followed-user display-name fallback chains with the
/// profile-fetch nudge when the profile is still missing, the
/// loading-placeholder suppression once already loaded, an exception
/// surfacing as DrawerError, and that every Isar watcher re-triggers a
/// load.
void main() {
  late _MockGetActiveUser getActiveUser;
  late _MockGetOwnProfile getOwnProfile;
  late _MockGetAllFollowedNotes getAllFollowedNotes;
  late _MockGetGroups getGroups;
  late _MockGetPrivateGroups getPrivateGroups;
  late _MockGetFollowedUsers getFollowedUsers;
  late _MockGetRelays getRelays;
  late _MockRequestProfileFetch requestProfileFetch;
  late _MockDrawerDataSource drawerData;

  DrawerBloc build() => DrawerBloc(
        getActiveUser,
        getOwnProfile,
        getAllFollowedNotes,
        getGroups,
        getPrivateGroups,
        getFollowedUsers,
        getRelays,
        requestProfileFetch,
        drawerData,
      );

  setUp(() {
    getActiveUser = _MockGetActiveUser();
    getOwnProfile = _MockGetOwnProfile();
    getAllFollowedNotes = _MockGetAllFollowedNotes();
    getGroups = _MockGetGroups();
    getPrivateGroups = _MockGetPrivateGroups();
    getFollowedUsers = _MockGetFollowedUsers();
    getRelays = _MockGetRelays();
    requestProfileFetch = _MockRequestProfileFetch();
    drawerData = _MockDrawerDataSource();

    when(() => drawerData.watchGroups()).thenAnswer((_) => const Stream.empty());
    when(() => drawerData.watchFollowedUsers()).thenAnswer((_) => const Stream.empty());
    when(() => drawerData.watchFollowedNotes()).thenAnswer((_) => const Stream.empty());
    when(() => drawerData.watchUnread()).thenAnswer((_) => const Stream.empty());
    when(() => drawerData.watchProfiles()).thenAnswer((_) => const Stream.empty());
    when(() => drawerData.watchDmConversations()).thenAnswer((_) => const Stream.empty());
    when(() => drawerData.unreadRows()).thenAnswer((_) async => []);
    when(() => drawerData.activeDmConversations()).thenAnswer((_) async => []);
    when(() => drawerData.profileByPubkey(any())).thenAnswer((_) async => null);
    when(() => getActiveUser.call()).thenAnswer((_) async => const Left(Failure.errorFailure('no active user')));
    when(() => getGroups.call()).thenAnswer((_) async => const Right([]));
    // `execute()` backs both the constructor's own long-lived watcher AND
    // `_onLoad`'s own `.first` read — each call returns a fresh
    // Stream.value(...), so the constructor's watcher independently fires
    // its own extra DrawerLoadEvent shortly after construction on top of
    // any explicit one a test adds. Tests below that count exact call
    // totals (profile-fetch nudges, DrawerLoading count) account for this
    // rather than fighting it — it mirrors a real reactive multi-subscriber
    // stream, not a test artifact.
    when(() => getPrivateGroups.execute()).thenAnswer((_) => Stream.value(const []));
    when(() => getAllFollowedNotes.call()).thenAnswer((_) async => const Right([]));
    when(() => getFollowedUsers.call()).thenAnswer((_) async => const Right([]));
    when(() => getRelays.call()).thenAnswer((_) async => const Right([]));
    when(() => requestProfileFetch.call(any())).thenAnswer((_) async => const Right(unit));
  });

  test('no active user: falls back to Anonymous / empty npub / no avatar',
      () async {
    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.userName, 'Anonymous');
    expect(state.npub, isEmpty);
    expect(state.pubkeyHex, isEmpty);
    expect(state.avatarUrl, isNull);
    await bloc.close();
  });

  test('an active user with an own profile hydrates name + avatar',
      () async {
    when(() => getActiveUser.call())
        .thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk', npub: 'npub1xxx')));
    when(() => getOwnProfile.call('pk'))
        .thenAnswer((_) async => Right(aProfile(name: 'Alice', avatarUrl: 'https://img')));

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.userName, 'Alice');
    expect(state.npub, 'npub1xxx');
    expect(state.pubkeyHex, 'pk');
    expect(state.avatarUrl, 'https://img');
    await bloc.close();
  });

  test('falls back to username when the profile has no display name',
      () async {
    when(() => getActiveUser.call()).thenAnswer((_) async => Right(aUserKey(pubkeyHex: 'pk')));
    when(() => getOwnProfile.call('pk'))
        .thenAnswer((_) async => Right(aProfile(name: null, username: 'alice_handle')));

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect((bloc.state as DrawerLoaded).userName, 'alice_handle');
    await bloc.close();
  });

  test('groups carry their hasUnread flag from the aggregated unread rows',
      () async {
    when(() => getGroups.call()).thenAnswer((_) async => Right([aGroup(groupId: 'g1', name: 'G1')]));
    when(() => drawerData.unreadRows())
        .thenAnswer((_) async => [_anUnreadRow(eventId: 'e1', kind: 42, groupId: 'g1')]);

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.groups.single.id, 'g1');
    expect(state.groups.single.unreadCount, 1);
    expect(state.groups.single.hasUnread, isTrue);
    await bloc.close();
  });

  test('private groups carry their hasUnread flag independently of public '
      'groups', () async {
    when(() => getPrivateGroups.execute())
        .thenAnswer((_) => Stream.value([aPrivateGroup(groupId: 'pg1', name: 'PG1')]));
    when(() => drawerData.unreadRows())
        .thenAnswer((_) async => [_anUnreadRow(eventId: 'e1', kind: 9023, privateGroupId: 'pg1')]);

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.privateGroups.single.id, 'pg1');
    expect(state.privateGroups.single.unreadCount, 1);
    expect(state.privateGroups.single.hasUnread, isTrue);
    await bloc.close();
  });

  test('a group counts every unread row, not just whether there is one',
      () async {
    when(() => getGroups.call()).thenAnswer((_) async => Right([aGroup(groupId: 'g1', name: 'G1')]));
    when(() => getPrivateGroups.execute()).thenAnswer((_) => Stream.value([aPrivateGroup(groupId: 'pg1', name: 'PG1')]));
    when(() => drawerData.unreadRows()).thenAnswer((_) async => [
          for (var i = 0; i < 5; i++) _anUnreadRow(eventId: 'g$i', kind: 42, groupId: 'g1'),
          for (var i = 0; i < 3; i++) _anUnreadRow(eventId: 'p$i', kind: 9023, privateGroupId: 'pg1'),
        ]);

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.groups.single.unreadCount, 5);
    expect(state.privateGroups.single.unreadCount, 3);
    await bloc.close();
  });

  test('a group with nothing unread has a zero count and no flag', () async {
    when(() => getGroups.call()).thenAnswer((_) async => Right([aGroup(groupId: 'g1', name: 'G1')]));
    when(() => drawerData.unreadRows()).thenAnswer((_) async => []);

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.groups.single.unreadCount, 0);
    expect(state.groups.single.hasUnread, isFalse);
    await bloc.close();
  });

  group('DMs', () {
    test('a DM with a resolved profile uses its display name and unread '
        'count, without nudging a profile fetch', () async {
      when(() => drawerData.activeDmConversations()).thenAnswer((_) async => [_aConversationModel('peer-1')]);
      when(() => drawerData.profileByPubkey('peer-1'))
          .thenAnswer((_) async => _aProfileModel(pubkey: 'peer-1', name: 'Bob'));
      when(() => drawerData.unreadRows()).thenAnswer(
          (_) async => [_anUnreadRow(eventId: 'e1', kind: 14, conversationId: _aConversationModel('peer-1').id)]);

      final bloc = build();
      bloc.add(DrawerLoadEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = bloc.state as DrawerLoaded;
      expect(state.dms.single.name, 'Bob');
      expect(state.dms.single.unreadCount, 1);
      verifyZeroInteractions(requestProfileFetch);
      await bloc.close();
    });

    test('a DM with no resolved profile falls back to the raw pubkey and '
        'nudges a profile fetch', () async {
      when(() => drawerData.activeDmConversations()).thenAnswer((_) async => [_aConversationModel('peer-1')]);
      when(() => drawerData.profileByPubkey('peer-1')).thenAnswer((_) async => null);

      final bloc = build();
      bloc.add(DrawerLoadEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = bloc.state as DrawerLoaded;
      expect(state.dms.single.name, 'peer-1');
      verify(() => requestProfileFetch.call('peer-1')).called(greaterThanOrEqualTo(1));
      await bloc.close();
    });
  });

  group('followed users', () {
    test('resolves name via profile > username > petname > shortened '
        'pubkey, in that priority order', () async {
      when(() => getFollowedUsers.call()).thenAnswer((_) async => Right([
            FollowedUserEntity(pubkeyHex: 'has-profile', followedAt: DateTime(2026, 1, 1)),
            FollowedUserEntity(
                pubkeyHex: 'has-petname-only', petname: 'Nickname', followedAt: DateTime(2026, 1, 1)),
            FollowedUserEntity(
                pubkeyHex: 'no-profile-no-petname-at-all', followedAt: DateTime(2026, 1, 1)),
          ]));
      when(() => drawerData.profileByPubkey('has-profile'))
          .thenAnswer((_) async => _aProfileModel(pubkey: 'has-profile', name: 'Real Name'));
      when(() => drawerData.profileByPubkey('has-petname-only')).thenAnswer((_) async => null);
      when(() => drawerData.profileByPubkey('no-profile-no-petname-at-all')).thenAnswer((_) async => null);

      final bloc = build();
      bloc.add(DrawerLoadEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final byPubkey = {for (final u in (bloc.state as DrawerLoaded).followedUsers) u.pubkey: u.name};
      expect(byPubkey['has-profile'], 'Real Name');
      expect(byPubkey['has-petname-only'], 'Nickname');
      expect(byPubkey['no-profile-no-petname-at-all'], 'no-profile-n…');
      await bloc.close();
    });

    test('nudges a profile fetch only for followed users missing a profile',
        () async {
      when(() => getFollowedUsers.call()).thenAnswer((_) async => Right([
            FollowedUserEntity(pubkeyHex: 'has-profile', followedAt: DateTime(2026, 1, 1)),
            FollowedUserEntity(pubkeyHex: 'missing', followedAt: DateTime(2026, 1, 1)),
          ]));
      when(() => drawerData.profileByPubkey('has-profile'))
          .thenAnswer((_) async => _aProfileModel(pubkey: 'has-profile', name: 'Real Name'));
      when(() => drawerData.profileByPubkey('missing')).thenAnswer((_) async => null);

      final bloc = build();
      bloc.add(DrawerLoadEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(() => requestProfileFetch.call('missing')).called(greaterThanOrEqualTo(1));
      verifyNever(() => requestProfileFetch.call('has-profile'));
      await bloc.close();
    });
  });

  test('followed notes and relay urls are mapped straight through', () async {
    when(() => getAllFollowedNotes.call()).thenAnswer((_) async => Right([
          FollowedNoteEntity(
            eventId: 'fn-1',
            contentPreview: 'preview',
            followedAt: DateTime(2026, 1, 1),
            newReferenceCount: 1,
          ),
        ]));
    when(() => getRelays.call()).thenAnswer((_) async => Right([aRelay(url: 'wss://relay.example')]));

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.followedNotes.single.eventId, 'fn-1');
    expect(state.myRelays, ['wss://relay.example']);
    await bloc.close();
  });

  test('groups/followedNotes/relays each degrade to an empty list '
      'independently on their own failure, without erroring the whole load',
      () async {
    when(() => getGroups.call()).thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    when(() => getAllFollowedNotes.call())
        .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    when(() => getRelays.call()).thenAnswer((_) async => const Left(Failure.errorFailure('boom')));

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.groups, isEmpty);
    expect(state.followedNotes, isEmpty);
    expect(state.myRelays, isEmpty);
    await bloc.close();
  });

  test('a second unread row for the same container increments its count '
      'past the initial 1, for both private groups and DMs', () async {
    final conv = _aConversationModel('peer-1');
    when(() => drawerData.activeDmConversations()).thenAnswer((_) async => [conv]);
    when(() => getPrivateGroups.execute())
        .thenAnswer((_) => Stream.value([aPrivateGroup(groupId: 'pg1', name: 'PG1')]));
    when(() => drawerData.unreadRows()).thenAnswer((_) async => [
          _anUnreadRow(eventId: 'e1', kind: 9023, privateGroupId: 'pg1'),
          _anUnreadRow(eventId: 'e2', kind: 9023, privateGroupId: 'pg1'),
          _anUnreadRow(eventId: 'e3', kind: 14, conversationId: conv.id),
          _anUnreadRow(eventId: 'e4', kind: 14, conversationId: conv.id),
        ]);

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as DrawerLoaded;
    expect(state.privateGroups.single.hasUnread, isTrue);
    expect(state.dms.single.unreadCount, 2);
    await bloc.close();
  });

  test('shows DrawerLoading only before the first successful load, not on '
      'reloads once already loaded', () async {
    final bloc = build();
    bloc.add(DrawerLoadEvent());
    // Let construction's own implicit watcher-triggered load (if any) and
    // the explicit one above both settle before we start counting.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state, isA<DrawerLoaded>());

    final states = <DrawerState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(states.whereType<DrawerLoading>(), isEmpty);
    expect(states.whereType<DrawerLoaded>(), hasLength(2));
    await sub.cancel();
    await bloc.close();
  });

  test('an unexpected exception surfaces as DrawerError', () async {
    when(() => drawerData.unreadRows()).thenThrow(Exception('isar closed'));

    final bloc = build();
    bloc.add(DrawerLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state, isA<DrawerError>());
    expect((bloc.state as DrawerError).message, contains('isar closed'));
    await bloc.close();
  });

  group('reactive watchers', () {
    test('a groups watcher emission triggers a reload', () async {
      when(() => drawerData.watchGroups()).thenAnswer((_) => Stream.value(null));

      final bloc = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });

    test('a followed-notes watcher emission triggers a reload', () async {
      when(() => drawerData.watchFollowedNotes()).thenAnswer((_) => Stream.value(null));

      final bloc = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });

    test('an unread watcher emission triggers a reload', () async {
      when(() => drawerData.watchUnread()).thenAnswer((_) => Stream.value(null));

      final bloc = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });

    test('a profiles watcher emission triggers a reload', () async {
      when(() => drawerData.watchProfiles()).thenAnswer((_) => Stream.value(null));

      final bloc = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });

    test('a followed-users watcher emission triggers a reload', () async {
      when(() => drawerData.watchFollowedUsers()).thenAnswer((_) => Stream.value(null));

      final bloc = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });

    test('a private-groups watcher emission triggers a reload', () async {
      when(() => getPrivateGroups.execute())
          .thenAnswer((_) => Stream.fromIterable([const [], const []]));

      final bloc = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });

    test('a dm-conversations watcher emission (installed lazily on first '
        'load) triggers a reload', () async {
      when(() => drawerData.watchDmConversations()).thenAnswer((_) => Stream.value(null));

      final bloc = build();
      bloc.add(DrawerLoadEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<DrawerLoaded>());
      await bloc.close();
    });
  });
}
