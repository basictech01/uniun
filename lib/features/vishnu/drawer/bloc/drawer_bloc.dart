import 'package:flutter/foundation.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/followed_user/followed_user_entity.dart';
import 'package:uniun/domain/usecases/followed_user_usecases.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/get_groups_usecase.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/private_group_usecases.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_data_source.dart';
import 'dart:async';

part 'drawer_event.dart';
part 'drawer_state.dart';

@injectable
class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnProfileUseCase _getOwnProfile;
  final GetAllFollowedNotesUseCase _getAllFollowedNotes;
  final GetGroupsUseCase _getGroups;
  final GetPrivateGroupsUsecase _getPrivateGroups;
  final GetFollowedUsersUseCase _getFollowedUsers;
  final GetRelaysUseCase _getRelays;
  final RequestProfileFetchUseCase _requestProfileFetch;
  final DrawerDataSource _drawerData;
  StreamSubscription<void>? _dmWatcher;
  StreamSubscription<void>? _groupWatcher;
  StreamSubscription<void>? _privateGroupWatcher;
  StreamSubscription<void>? _followedUsersWatcher;
  StreamSubscription<void>? _followedNotesWatcher;
  StreamSubscription<void>? _unreadWatcher;
  StreamSubscription<void>? _profileWatcher;

  DrawerBloc(
    this._getActiveUser,
    this._getOwnProfile,
    this._getAllFollowedNotes,
    this._getGroups,
    this._getPrivateGroups,
    this._getFollowedUsers,
    this._getRelays,
    this._requestProfileFetch,
    this._drawerData,
  ) : super(DrawerInitial()) {
    // A burst of changes (a batch of notes arriving) restarts the reload
    // instead of queueing one per change, so the dot shows up sooner.
    on<DrawerLoadEvent>(_onLoad, transformer: restartable());

    // NIP-28 public groups: creating/joining a group writes a GroupModel,
    // so the new group shows in the drawer immediately without a refresh.
    _groupWatcher = _drawerData.watchGroups().listen((_) {
      if (!isClosed) add(DrawerLoadEvent());
    });
    _privateGroupWatcher = _getPrivateGroups.execute().listen((_) {
      if (!isClosed) add(DrawerLoadEvent());
    });
    _followedUsersWatcher = _drawerData.watchFollowedUsers().listen((_) {
      if (!isClosed) add(DrawerLoadEvent());
    });
    // Reactive "Following" section: follow/unfollow from a NoteCard writes to
    // followedNoteModels — refresh so the list of rows is up to date.
    _followedNotesWatcher = _drawerData.watchFollowedNotes().listen((_) {
      if (!isClosed) add(DrawerLoadEvent());
    });
    // Unread badges (and derived followed-note ref count): kind-1/42/... inbound
    // handlers insert unread rows and reading a note deletes them.
    _unreadWatcher = _drawerData.watchUnread().listen((_) {
      if (!isClosed) add(DrawerLoadEvent());
    });
    // Kind 0 arriving late: reload so DM/followed-user rows swap the hex
    // fallback for the real display name once the profile lands in Isar.
    _profileWatcher = _drawerData.watchProfiles().listen((_) {
      if (!isClosed) add(DrawerLoadEvent());
    });
  }

  Future<void> _onLoad(DrawerLoadEvent event, Emitter<DrawerState> emit) async {
    _dmWatcher ??= _drawerData.watchDmConversations().listen((_) {
      if (!isClosed) {
        add(DrawerLoadEvent());
      }
    });

    // Only show the loading placeholder on the first load. Reloads fired by the
    // Isar watchers keep the current DrawerLoaded on screen so the top-right
    // avatar and drawer header don't flicker to placeholders mid-reload.
    if (state is! DrawerLoaded) {
      emit(DrawerLoading());
    }

    try {
      // Per-container unread counts from the UnreadNote collection (one batched
      // read; grouped in memory). Exactly one container field is set per row.
      final unreadRows = await _drawerData.unreadRows();
      final groupUnread = <String, int>{};
      final privateGroupUnread = <String, int>{};
      final conversationUnread = <int, int>{};
      for (final r in unreadRows) {
        if (r.groupId != null) {
          groupUnread.update(r.groupId!, (v) => v + 1, ifAbsent: () => 1);
        } else if (r.privateGroupId != null) {
          privateGroupUnread.update(
            r.privateGroupId!,
            (v) => v + 1,
            ifAbsent: () => 1,
          );
        } else if (r.conversationId != null) {
          conversationUnread.update(
            r.conversationId!,
            (v) => v + 1,
            ifAbsent: () => 1,
          );
        }
      }

      final userResult = await _getActiveUser.call();
      final user = userResult.fold((_) => null, (u) => u);

      String displayName = 'Anonymous';
      String npub = '';
      String? avatarUrl;

      if (user != null) {
        // Keep the FULL npub in state. UI is responsible for truncating
        // for display only — Copy must always paste the complete value.
        npub = user.npub;

        final profileResult = await _getOwnProfile.call(user.pubkeyHex);
        final profile = profileResult.fold((_) => null, (p) => p);

        if (profile != null) {
          displayName = profile.name ?? profile.username ?? displayName;
          avatarUrl = profile.avatarUrl;
        }
      }

      // Live query for NIP-28 groups
      final groupsResult = await _getGroups.call();
      final groups = groupsResult.fold(
        (_) => <DrawerGroupItem>[],
        (list) => list
            .map(
              (c) => DrawerGroupItem(
                id: c.groupId,
                name: c.name,
                hasUnread: (groupUnread[c.groupId] ?? 0) > 0,
              ),
            )
            .toList(),
      );
      final dmConversations = await _drawerData.activeDmConversations();
      final dms = <DrawerDmItem>[];
      for (final conv in dmConversations) {
        final profile = await _drawerData.profileByPubkey(conv.otherPubkey);
        if (profile == null) {
          // Nudge the gateway to fetch Kind 0 for this peer. The profile
          // watcher above will reload the drawer once it lands so the row
          // swaps hex for the real display name.
          unawaited(_requestProfileFetch.call(conv.otherPubkey));
        }
        dms.add(
          DrawerDmItem(
            pubkey: conv.otherPubkey,
            name: profile?.name ?? profile?.username ?? conv.otherPubkey,
            avatarUrl: profile?.avatarUrl,
            unreadCount: conversationUnread[conv.id] ?? 0,
          ),
        );
      }

      final followedResult = await _getAllFollowedNotes.call();
      final followedNotes = followedResult.fold(
        (_) => <DrawerFollowedNoteItem>[],
        (list) => list
            .map(
              (e) => DrawerFollowedNoteItem(
                eventId: e.eventId,
                contentPreview: e.contentPreview,
                newReferenceCount: e.newReferenceCount,
              ),
            )
            .toList(),
      );

      final privateGroupResult = await _getPrivateGroups.execute().first;
      final privateGroups = privateGroupResult
          .map(
            (c) => DrawerPrivateGroupItem(
              id: c.groupId,
              name: c.name,
              hasUnread: (privateGroupUnread[c.groupId] ?? 0) > 0,
            ),
          )
          .toList();

      final followedUsersResult = await _getFollowedUsers.call();
      final List<FollowedUserEntity> followedUsersDomain = followedUsersResult
          .fold((_) => const [], (l) => l);
      final followedUsers = <DrawerFollowedUserItem>[];
      for (final f in followedUsersDomain) {
        final profile = await _drawerData.profileByPubkey(f.pubkeyHex);
        if (profile == null) {
          unawaited(_requestProfileFetch.call(f.pubkeyHex));
        }
        final shortKey = f.pubkeyHex.length > 12
            ? '${f.pubkeyHex.substring(0, 12)}…'
            : f.pubkeyHex;
        followedUsers.add(
          DrawerFollowedUserItem(
            pubkey: f.pubkeyHex,
            name: profile?.name ?? profile?.username ?? f.petname ?? shortKey,
            avatarUrl: profile?.avatarUrl,
          ),
        );
      }

      final relaysResult = await _getRelays.call();
      final myRelays = relaysResult.fold(
        (_) => <String>[],
        (list) => list.map((r) => r.url).toList(),
      );

      emit(
        DrawerLoaded(
          userName: displayName,
          npub: npub,
          pubkeyHex: user?.pubkeyHex ?? '',
          avatarUrl: avatarUrl,
          followedNotes: followedNotes,
          groups: groups,
          privateGroups: privateGroups,
          dms: dms,
          followedUsers: followedUsers,
          myRelays: myRelays,
        ),
      );
    } catch (e) {
      emit(DrawerError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _dmWatcher?.cancel();
    _groupWatcher?.cancel();
    _privateGroupWatcher?.cancel();
    _followedUsersWatcher?.cancel();
    _followedNotesWatcher?.cancel();
    _unreadWatcher?.cancel();
    _profileWatcher?.cancel();
    return super.close();
  }
}
