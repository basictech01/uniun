import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

part 'edit_profile_state.dart';

@injectable
class EditProfileCubit extends Cubit<EditProfileState> {
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnProfileUseCase _getOwnProfile;
  final SaveProfileUseCase _saveProfile;

  // Start in loading state so controllers are only initialised after data arrives.
  EditProfileCubit(this._getActiveUser, this._getOwnProfile, this._saveProfile)
      : super(const EditProfileState(status: EditProfileStatus.loading)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final userResult = await _getActiveUser.call();
      final user = userResult.fold((_) => null, (u) => u);
      if (user == null) {
        emit(state.copyWith(
            status: EditProfileStatus.error, error: 'No active user'));
        return;
      }

      final profileResult = await _getOwnProfile.call(user.pubkeyHex);
      final profile = profileResult.fold((_) => null, (p) => p);

      emit(state.copyWith(
        status: EditProfileStatus.initial,
        pubkeyHex: user.pubkeyHex,
        name: profile?.name ?? '',
        username: profile?.username ?? '',
        about: profile?.about ?? '',
        avatarUrl: profile?.avatarUrl ?? '',
        nip05: profile?.nip05 ?? '',
      ));
    } catch (e) {
      emit(state.copyWith(
          status: EditProfileStatus.error, error: e.toString()));
    }
  }

  void updateName(String v) => emit(state.copyWith(name: v));
  void updateUsername(String v) => emit(state.copyWith(username: v));
  void updateAbout(String v) => emit(state.copyWith(about: v));
  void updateAvatarUrl(String v) => emit(state.copyWith(avatarUrl: v));
  void updateNip05(String v) => emit(state.copyWith(nip05: v));

  Future<bool> save() async {
    if (state.pubkeyHex.isEmpty) return false;
    emit(state.copyWith(status: EditProfileStatus.saving));
    try {
      final entity = ProfileEntity(
        pubkey: state.pubkeyHex,
        name: state.name.trim().isEmpty ? null : state.name.trim(),
        username:
            state.username.trim().isEmpty ? null : state.username.trim(),
        about: state.about.trim().isEmpty ? null : state.about.trim(),
        avatarUrl:
            state.avatarUrl.trim().isEmpty ? null : state.avatarUrl.trim(),
        nip05: state.nip05.trim().isEmpty ? null : state.nip05.trim(),
        updatedAt: DateTime.now(),
        // Own profile never evicted — lastSeenAt set far in the future.
        lastSeenAt: DateTime(3000, 6, 1),
      );

      final result = await _saveProfile.call(entity);
      return result.fold(
        (failure) {
          emit(state.copyWith(
              status: EditProfileStatus.error, error: failure.toMessage()));
          return false;
        },
        (_) {
          emit(state.copyWith(status: EditProfileStatus.saved));
          return true;
        },
      );
    } catch (e) {
      emit(state.copyWith(
          status: EditProfileStatus.error, error: e.toString()));
      return false;
    }
  }
}
