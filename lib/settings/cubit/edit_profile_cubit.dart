import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

part 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit() : super(const EditProfileState()) {
    _load();
  }

  Future<void> _load() async {
    emit(state.copyWith(status: EditProfileStatus.loading));
    try {
      final userResult = await getIt<UserRepository>().getActiveUser();
      final user = userResult.fold((_) => null, (u) => u);
      if (user == null) {
        emit(state.copyWith(
            status: EditProfileStatus.error, error: 'No active user'));
        return;
      }

      final profileResult =
          await getIt<ProfileRepository>().getOwnProfile(user.pubkeyHex);
      final profile = profileResult.fold((_) => null, (p) => p);

      emit(state.copyWith(
        status: EditProfileStatus.initial,
        pubkeyHex: user.pubkeyHex,
        name: profile?.name ?? '',
        username: profile?.username ?? '',
        about: profile?.about ?? '',
        avatarUrl: profile?.avatarUrl ?? '',
        nip05: profile?.nip05 ?? '',
        isOwn: true,
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
        isOwn: true,
        lastSeenAt: DateTime.now(),
      );

      final result =
          await getIt<ProfileRepository>().saveProfile(entity);
      return result.fold(
        (failure) {
          emit(state.copyWith(
              status: EditProfileStatus.error, error: failure.toString()));
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
