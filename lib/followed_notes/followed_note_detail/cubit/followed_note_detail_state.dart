part of 'followed_note_detail_cubit.dart';

enum FollowedNoteDetailStatus { initial, loading, loaded, error }

class FollowedNoteDetailState {
  const FollowedNoteDetailState({
    this.status = FollowedNoteDetailStatus.initial,
    this.note,
    this.profile,
    this.replies = const [],
    this.replyProfiles = const {},
    this.referencedNotes = const [],
    this.errorMessage,
  });

  final FollowedNoteDetailStatus status;
  final NoteEntity? note;
  final ProfileEntity? profile;
  final List<NoteEntity> replies;
  final Map<String, ProfileEntity> replyProfiles;
  final List<NoteEntity> referencedNotes;
  final String? errorMessage;

  FollowedNoteDetailState copyWith({
    FollowedNoteDetailStatus? status,
    NoteEntity? note,
    ProfileEntity? profile,
    List<NoteEntity>? replies,
    Map<String, ProfileEntity>? replyProfiles,
    List<NoteEntity>? referencedNotes,
    String? errorMessage,
  }) {
    return FollowedNoteDetailState(
      status: status ?? this.status,
      note: note ?? this.note,
      profile: profile ?? this.profile,
      replies: replies ?? this.replies,
      replyProfiles: replyProfiles ?? this.replyProfiles,
      referencedNotes: referencedNotes ?? this.referencedNotes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
