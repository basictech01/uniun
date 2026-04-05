import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';

part 'followed_notes_state.dart';

@injectable
class FollowedNotesCubit extends Cubit<FollowedNotesState> {
  final GetAllFollowedNotesUseCase _getAll;
  final FollowNoteUseCase _follow;
  final UnfollowNoteUseCase _unfollow;
  final ClearNewReferencesUseCase _clearNewReferences;

  FollowedNotesCubit(
    this._getAll,
    this._follow,
    this._unfollow,
    this._clearNewReferences,
  ) : super(const FollowedNotesState());

  Future<void> load() async {
    emit(state.copyWith(status: FollowedNotesStatus.loading));
    final result = await _getAll.call();
    result.fold(
      (failure) => emit(state.copyWith(
        status: FollowedNotesStatus.error,
        error: failure.toMessage(),
      )),
      (notes) => emit(state.copyWith(
        status: FollowedNotesStatus.loaded,
        notes: notes,
      )),
    );
  }

  Future<void> followNote(String eventId, String contentPreview) async {
    final result = await _follow.call(
      FollowNoteInput(eventId: eventId, contentPreview: contentPreview),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: FollowedNotesStatus.error,
        error: failure.toMessage(),
      )),
      (_) => load(),
    );
  }

  Future<void> unfollowNote(String eventId) async {
    final result = await _unfollow.call(eventId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: FollowedNotesStatus.error,
        error: failure.toMessage(),
      )),
      (_) => load(),
    );
  }

  Future<void> clearNewReferences(String eventId) async {
    await _clearNewReferences.call(eventId);
    await load();
  }
}
