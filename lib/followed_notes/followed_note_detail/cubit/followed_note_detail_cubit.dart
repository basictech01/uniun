import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';

part 'followed_note_detail_state.dart';

@injectable
class FollowedNoteDetailCubit extends Cubit<FollowedNoteDetailState> {
  final GetNoteByIdUseCase _getNoteById;
  final GetRepliesUseCase _getReplies;
  final GetProfileUseCase _getProfile;

  FollowedNoteDetailCubit(
    this._getNoteById,
    this._getReplies,
    this._getProfile,
  ) : super(const FollowedNoteDetailState());

  Future<void> load(String noteId) async {
    emit(state.copyWith(status: FollowedNoteDetailStatus.loading));

    final noteResult = await _getNoteById.call(noteId);
    final note = noteResult.fold((_) => null, (n) => n);
    if (note == null) {
      emit(state.copyWith(
        status: FollowedNoteDetailStatus.error,
        errorMessage: 'Note not found',
      ));
      return;
    }

    // Load author profile
    final profileResult = await _getProfile.call(note.authorPubkey);
    final profile = profileResult.fold((_) => null, (p) => p);

    // Load direct replies
    final repliesResult = await _getReplies.call(noteId);
    final replies =
        repliesResult.fold((_) => <NoteEntity>[], (list) => list);

    // Load reply author profiles
    final replyProfiles = <String, ProfileEntity>{};
    final seenPubkeys = <String>{note.authorPubkey};
    for (final reply in replies) {
      if (!seenPubkeys.contains(reply.authorPubkey)) {
        seenPubkeys.add(reply.authorPubkey);
        final r = await _getProfile.call(reply.authorPubkey);
        r.fold((_) {}, (p) => replyProfiles[p.pubkey] = p);
      }
    }

    // Load referenced notes (eTagRefs) — best-effort, up to 5
    final referencedNotes = <NoteEntity>[];
    for (final refId in note.eTagRefs.take(5)) {
      final r = await _getNoteById.call(refId);
      r.fold((_) {}, (n) => referencedNotes.add(n));
    }

    emit(FollowedNoteDetailState(
      status: FollowedNoteDetailStatus.loaded,
      note: note,
      profile: profile,
      replies: replies,
      replyProfiles: replyProfiles,
      referencedNotes: referencedNotes,
    ));
  }
}
