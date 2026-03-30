import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

part 'drawer_event.dart';
part 'drawer_state.dart';

@injectable
class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  DrawerBloc() : super(DrawerInitial()) {
    on<DrawerLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(
    DrawerLoadEvent event,
    Emitter<DrawerState> emit,
  ) async {
    emit(DrawerLoading());

    try {
      // Load the active user's keypair
      final userResult = await getIt<UserRepository>().getActiveUser();
      final user = userResult.fold((_) => null, (u) => u);

      String displayName = 'Anonymous';
      String npubShort = '';
      String? avatarUrl;

      if (user != null) {
        npubShort = user.npub.length > 12
            ? '${user.npub.substring(0, 12)}...'
            : user.npub;

        // Load own profile for display name + avatar
        final profileResult = await getIt<ProfileRepository>()
            .getOwnProfile(user.pubkeyHex);
        final profile = profileResult.fold((_) => null, (p) => p);

        if (profile != null) {
          displayName = profile.name ?? profile.username ?? displayName;
          avatarUrl = profile.avatarUrl;
        }
      }

      // Channels + DMs: sample placeholder data until ChannelModel / DMModel
      // repositories are built. Will be replaced with live Isar queries when
      // Kind 40/42 and Kind 14 repositories are implemented.
      const channels = <DrawerChannelItem>[
        DrawerChannelItem(id: 'ch_general', name: 'general', hasUnread: true),
        DrawerChannelItem(id: 'ch_nostr', name: 'nostr-dev'),
        DrawerChannelItem(id: 'ch_uniun', name: 'uniun'),
      ];
      const dms = <DrawerDmItem>[
        DrawerDmItem(pubkey: 'dm1', name: 'Alice', unreadCount: 3),
        DrawerDmItem(pubkey: 'dm2', name: 'Bob'),
      ];

      emit(DrawerLoaded(
        userName: displayName,
        npub: npubShort,
        pubkeyHex: user?.pubkeyHex ?? '',
        avatarUrl: avatarUrl,
        channels: channels,
        dms: dms,
      ));
    } catch (e) {
      emit(DrawerError(e.toString()));
    }
  }
}
