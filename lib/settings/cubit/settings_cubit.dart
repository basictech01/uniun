import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

part 'settings_state.dart';

@injectable
class SettingsCubit extends Cubit<SettingsState> {
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnProfileUseCase _getOwnProfile;

  SettingsCubit(this._getActiveUser, this._getOwnProfile)
      : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final userResult = await _getActiveUser.call();
      final user = userResult.fold((_) => null, (u) => u);

      if (user == null) {
        emit(state.copyWith(isLoading: false, error: 'No active user'));
        return;
      }

      final npub = user.npub;
      final handle = npub.length > 16 ? '${npub.substring(0, 16)}...' : npub;

      String displayName = 'Anonymous';
      String? avatarUrl;

      final profileResult = await _getOwnProfile.call(user.pubkeyHex);
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
      final result = await _getActiveUser.call();
      final nsec = result.fold((_) => null, (u) => u.nsec);
      emit(state.copyWith(nsecVisible: true, nsec: nsec));
    } catch (_) {
      emit(state.copyWith(nsecVisible: true));
    }
  }
}
