import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/inputs/note_input.dart';
import 'package:uniun/domain/usecases/note_usecases.dart' hide SaveNoteUseCase;
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';

part 'vishnu_feed_event.dart';
part 'vishnu_feed_state.dart';

const _pageSize = 20;

@injectable
class VishnuFeedBloc extends Bloc<VishnuFeedEvent, VishnuFeedState> {
  final GetFeedUseCase _getFeed;
  final GetProfileUseCase _getProfile;
  final GetThreadReplyCountUseCase _getThreadReplyCount;
  final GetAllSavedNotesUseCase _getAllSavedNotes;
  final SaveNoteUseCase _saveNote;
  final UnsaveNoteUseCase _unsaveNote;

  VishnuFeedBloc(
    this._getFeed,
    this._getProfile,
    this._getThreadReplyCount,
    this._getAllSavedNotes,
    this._saveNote,
    this._unsaveNote,
  ) : super(const VishnuFeedState()) {
    on<LoadFeedEvent>(_onLoad, transformer: droppable());
    on<RefreshFeedEvent>(_onRefresh, transformer: droppable());
    on<LoadMoreFeedEvent>(_onLoadMore, transformer: droppable());
    on<SaveFeedNoteEvent>(_onSave, transformer: sequential());
    on<UnsaveFeedNoteEvent>(_onUnsave, transformer: sequential());
  }

  Future<void> _onLoad(
    LoadFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    if (state.status != VishnuFeedStatus.initial) return;
    emit(state.copyWith(status: VishnuFeedStatus.loading));
    await _fetchPage(emit, before: null, append: false);
  }

  Future<void> _onRefresh(
    RefreshFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    emit(state.copyWith(status: VishnuFeedStatus.loading));
    await _fetchPage(emit, before: null, append: false);
  }

  Future<void> _onLoadMore(
    LoadMoreFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    if (!state.hasMore) return;
    if (state.status == VishnuFeedStatus.loadingMore) return;
    if (state.notes.isEmpty) return;

    emit(state.copyWith(status: VishnuFeedStatus.loadingMore));
    final cursor = state.notes.last.created;
    await _fetchPage(emit, before: cursor, append: true);
  }

  Future<void> _onSave(
    SaveFeedNoteEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    // Optimistic
    emit(state.copyWith(savedIds: {...state.savedIds, event.note.id}));

    final result = await _saveNote.call(event.note);
    result.fold(
      (_) {
        // Rollback
        final rollback = Set<String>.from(state.savedIds)..remove(event.note.id);
        emit(state.copyWith(savedIds: rollback));
      },
      (_) {},
    );
  }

  Future<void> _onUnsave(
    UnsaveFeedNoteEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    // Optimistic
    final optimistic = Set<String>.from(state.savedIds)..remove(event.noteId);
    emit(state.copyWith(savedIds: optimistic));

    final result = await _unsaveNote.call(event.noteId);
    result.fold(
      (_) {
        // Rollback
        emit(state.copyWith(savedIds: {...state.savedIds, event.noteId}));
      },
      (_) {},
    );
  }

  Future<void> _fetchPage(
    Emitter<VishnuFeedState> emit, {
    required DateTime? before,
    required bool append,
  }) async {
    final result = await _getFeed.call(
      GetFeedInput(limit: _pageSize, before: before),
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: VishnuFeedStatus.error,
        errorMessage: failure.toMessage(),
      )),
      (newNotes) async {
        final combined = append ? [...state.notes, ...newNotes] : newNotes;

        // Profiles
        final profiles = Map<String, ProfileEntity>.from(state.profiles);
        final newPubkeys = combined
            .map((n) => n.authorPubkey)
            .toSet()
            .where((k) => !profiles.containsKey(k));
        for (final pubkey in newPubkeys) {
          final r = await _getProfile.call(pubkey);
          r.fold((_) {}, (p) => profiles[pubkey] = p);
        }

        // Reply counts
        final counts = Map<String, int>.from(state.replyCounts);
        for (final note in newNotes) {
          if (!counts.containsKey(note.id)) {
            final r = await _getThreadReplyCount.call(note.id);
            r.fold((_) {}, (c) => counts[note.id] = c);
          }
        }

        // Saved IDs
        final savedResult = await _getAllSavedNotes.call();
        final savedIds = savedResult.fold(
          (_) => state.savedIds,
          (list) => list.map((e) => e.eventId).toSet(),
        );

        emit(state.copyWith(
          notes: combined,
          profiles: profiles,
          replyCounts: counts,
          savedIds: savedIds,
          status: VishnuFeedStatus.loaded,
          hasMore: newNotes.length >= _pageSize,
        ));
      },
    );
  }
}
