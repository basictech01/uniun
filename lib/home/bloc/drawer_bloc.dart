import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

part 'drawer_event.dart';
part 'drawer_state.dart';

@injectable
class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnProfileUseCase _getOwnProfile;
  final GetAllFollowedNotesUseCase _getAllFollowedNotes;

  DrawerBloc(
    this._getActiveUser,
    this._getOwnProfile,
    this._getAllFollowedNotes,
  ) : super(DrawerInitial()) {
    on<DrawerLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(
    DrawerLoadEvent event,
    Emitter<DrawerState> emit,
  ) async {
    emit(DrawerLoading());

    try {
      final userResult = await _getActiveUser.call();
      final user = userResult.fold((_) => null, (u) => u);

      String displayName = 'Anonymous';
      String npubShort = '';
      String? avatarUrl;

      if (user != null) {
        npubShort = user.npub.length > 12
            ? '${user.npub.substring(0, 12)}...'
            : user.npub;

        final profileResult = await _getOwnProfile.call(user.pubkeyHex);
        final profile = profileResult.fold((_) => null, (p) => p);

        if (profile != null) {
          displayName = profile.name ?? profile.username ?? displayName;
          avatarUrl = profile.avatarUrl;
        }
      }

      // Placeholder — replaced with live Isar queries once ChannelRepository
      // (Kind 40/42) and DMRepository (Kind 14) are built.
      const channels = <DrawerChannelItem>[
        DrawerChannelItem(id: 'ch_general', name: 'general', hasUnread: true),
        DrawerChannelItem(id: 'ch_nostr', name: 'nostr-dev'),
        DrawerChannelItem(id: 'ch_uniun', name: 'uniun'),
      ];
      const dms = <DrawerDmItem>[
        DrawerDmItem(pubkey: 'dm1', name: 'Alice', unreadCount: 3),
        DrawerDmItem(pubkey: 'dm2', name: 'Bob'),
      ];

      final followedResult = await _getAllFollowedNotes.call();
      final followedNotes = followedResult.fold(
        (_) => <DrawerFollowedNoteItem>[],
        (list) => list
            .map((e) => DrawerFollowedNoteItem(
                  eventId: e.eventId,
                  contentPreview: e.contentPreview,
                  newReferenceCount: e.newReferenceCount,
                ))
            .toList(),
      );

      emit(DrawerLoaded(
        userName: displayName,
        npub: npubShort,
        pubkeyHex: user?.pubkeyHex ?? '',
        avatarUrl: avatarUrl,
        followedNotes: followedNotes,
        channels: channels,
        dms: dms,
      ));
    } catch (e) {
      emit(DrawerError(e.toString()));
    }
  }
}
