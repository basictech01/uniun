part of 'followed_notes_cubit.dart';

enum FollowedNotesStatus { initial, loading, loaded, error }

class FollowedNotesState {
  const FollowedNotesState({
    this.status = FollowedNotesStatus.initial,
    this.notes = const [],
    this.error,
  });

  final FollowedNotesStatus status;
  final List<FollowedNoteEntity> notes;
  final String? error;

  FollowedNotesState copyWith({
    FollowedNotesStatus? status,
    List<FollowedNoteEntity>? notes,
    String? error,
  }) {
    return FollowedNotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      error: error ?? this.error,
    );
  }
}
