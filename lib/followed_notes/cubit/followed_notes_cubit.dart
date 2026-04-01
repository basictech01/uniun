import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/repositories/followed_note_repository.dart';

part 'followed_notes_state.dart';

@injectable
class FollowedNotesCubit extends Cubit<FollowedNotesState> {
  final FollowedNoteRepository _repository;

  FollowedNotesCubit(this._repository) : super(const FollowedNotesState());

  Future<void> load() async {
    emit(state.copyWith(status: FollowedNotesStatus.loading));
    final result = await _repository.getAll();
    result.fold(
      (failure) => emit(state.copyWith(
        status: FollowedNotesStatus.error,
        error: failure.toString(),
      )),
      (notes) => emit(state.copyWith(
        status: FollowedNotesStatus.loaded,
        notes: notes,
      )),
    );
  }

  Future<void> followNote(String eventId, String contentPreview) async {
    final result = await _repository.followNote(eventId, contentPreview);
    result.fold(
      (failure) => emit(state.copyWith(
        status: FollowedNotesStatus.error,
        error: failure.toString(),
      )),
      (_) => load(),
    );
  }

  Future<void> unfollowNote(String eventId) async {
    final result = await _repository.unfollowNote(eventId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: FollowedNotesStatus.error,
        error: failure.toString(),
      )),
      (_) => load(),
    );
  }

  Future<void> clearNewReferences(String eventId) async {
    await _repository.clearNewReferences(eventId);
    // Refresh list so badge clears in the UI
    await load();
  }
}
