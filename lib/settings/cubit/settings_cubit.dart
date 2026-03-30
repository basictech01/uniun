import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final userResult = await getIt<UserRepository>().getActiveUser();
      final user = userResult.fold((_) => null, (u) => u);

      if (user == null) {
        emit(state.copyWith(isLoading: false, error: 'No active user'));
        return;
      }

      final npub = user.npub;
      final handle = npub.length > 16 ? '${npub.substring(0, 16)}...' : npub;

      String displayName = 'Anonymous';
      String? avatarUrl;

      final profileResult =
          await getIt<ProfileRepository>().getOwnProfile(user.pubkeyHex);
      final profile = profileResult.fold((_) => null, (p) => p);

      if (profile != null) {
        displayName = profile.name ?? profile.username ?? displayName;
        avatarUrl = profile.avatarUrl;
      }

      emit(state.copyWith(
        isLoading: false,
        userName: displayName,
        handle: handle,
        npub: npub,
        pubkeyHex: user.pubkeyHex,
        avatarUrl: avatarUrl,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void toggleAI(bool value) => emit(state.copyWith(aiEnabled: value));

  void toggleDmNotifications(bool value) =>
      emit(state.copyWith(dmNotifications: value));

  void toggleChannelAlerts(bool value) =>
      emit(state.copyWith(channelAlerts: value));

  Future<void> revealNsec() async {
    if (state.nsecVisible) {
      emit(state.copyWith(nsecVisible: false));
      return;
    }
    try {
      final result = await getIt<UserRepository>().getActiveUser();
      final nsec = result.fold((_) => null, (u) => u.nsec);
      emit(state.copyWith(nsecVisible: true, nsec: nsec));
    } catch (_) {
      emit(state.copyWith(nsecVisible: true));
    }
  }
}
