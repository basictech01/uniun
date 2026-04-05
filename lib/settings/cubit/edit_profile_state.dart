part of 'edit_profile_cubit.dart';

enum EditProfileStatus { initial, loading, saving, saved, error }

@immutable
class EditProfileState {
  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.name = '',
    this.username = '',
    this.about = '',
    this.avatarUrl = '',
    this.nip05 = '',
    this.pubkeyHex = '',
    this.error,
  });

  final EditProfileStatus status;
  final String name;
  final String username;
  final String about;
  final String avatarUrl;
  final String nip05;
  final String pubkeyHex;
  final String? error;

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? name,
    String? username,
    String? about,
    String? avatarUrl,
    String? nip05,
    String? pubkeyHex,
    String? error,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      name: name ?? this.name,
      username: username ?? this.username,
      about: about ?? this.about,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nip05: nip05 ?? this.nip05,
      pubkeyHex: pubkeyHex ?? this.pubkeyHex,
      error: error ?? this.error,
    );
  }
}
