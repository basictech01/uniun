import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'dart:async';

import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/domain/entities/media/media_blob_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/note_resolver_repository.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/post_reply_usecase.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';

part 'thread_event.dart';
part 'thread_state.dart';

/// Resolver-backed thread bloc. Reads a note from *any* collection by id and
/// posts replies routed by source — one bloc for feed/group/private/DM.
/// In `savedOnly` mode (entry from Saved Notes), root/replies/refs come from
/// the saved-note edge table so group messages whose live row was evicted
/// still render.
@injectable
class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final NoteResolverRepository _resolver;
  final PostReplyUseCase _postReply;
  final GetProfileUseCase _getProfile;
  final GetAllSavedNotesUseCase _getAllSavedNotes;
  final GetSavedRepliesUseCase _getSavedReplies;
  final GetSavedReferencesUseCase _getSavedReferences;
  final MarkUnreadSeenUseCase _markSeen;
  final WatchThreadUnreadMarkersUseCase _watchMarkers;
  StreamSubscription<Map<String, ThreadUnreadMarker>>? _markersSub;

  ThreadBloc(
    this._resolver,
    this._postReply,
    this._getProfile,
    this._getAllSavedNotes,
    this._getSavedReplies,
    this._getSavedReferences,
    this._markSeen,
    this._watchMarkers,
  ) : super(const ThreadState()) {
    on<LoadThreadEvent>(_onLoad, transformer: droppable());
    on<PostReplyEvent>(_onPost, transformer: droppable());
    on<_ThreadMarkersUpdated>(
      (event, emit) => emit(state.copyWith(unreadMarkers: event.markers)),
    );
  }

  @override
  Future<void> close() async {
    await _markersSub?.cancel();
    return super.close();
  }

  Future<void> _onLoad(LoadThreadEvent event, Emitter<ThreadState> emit) async {
    // Show the full-screen spinner only on the first load. A reload (e.g. after
    // posting a reply) keeps the current thread visible to avoid a jarring
    // full-page refresh.
    if (state.status != ThreadStatus.loaded) {
      emit(state.copyWith(status: ThreadStatus.loading));
    }

    // Saved-note ids are loaded in BOTH modes: in saved mode they are the
    // visible universe; in normal mode they drive the bookmark marking on
    // reply cards (parity with the feed).
    final savedResult = await _getAllSavedNotes.call();
    final allSaved = savedResult.fold((_) => <SavedNoteEntity>[], (n) => n);
    final savedOnlyIds = {for (final s in allSaved) s.eventId};

    // ── Root note ──────────────────────────────────────────────────────────
    // In saved mode the note may live only in savedNoteModels (a saved public
    // group message is never in noteModels), so resolve it from there.
    final NoteEntity? root;
    if (event.savedOnly) {
      SavedNoteEntity? rootSaved;
      for (final s in allSaved) {
        if (s.eventId == event.noteId) {
          rootSaved = s;
          break;
        }
      }
      if (rootSaved == null) {
        emit(state.copyWith(
          status: ThreadStatus.error,
          errorMessage:
              const Failure.errorFailure('Note not found').toMessage(),
        ));
        return;
      }
      root = rootSaved.toNoteEntity(savedEventIds: savedOnlyIds);
    } else {
      final rootResult = await _resolver.resolveById(event.noteId);
      if (rootResult.isLeft()) {
        emit(state.copyWith(
          status: ThreadStatus.error,
          errorMessage: rootResult.fold((f) => f.toMessage(), (_) => ''),
        ));
        return;
      }
      root = rootResult.getOrElse(() => throw StateError('unreachable'));
    }
    final rootNote = root;

    // Opening a note is what reads it: its own page clears its unread dot (a
    // parent's trail hint stays until the new note below it is opened).
    if (!event.savedOnly) await _markSeen.call(rootNote.id);

    // ── Parent chain (NIP-10 reply marker) ─────────────────────────────────
    final parentNotes = <NoteEntity>[];
    if (!event.savedOnly && rootNote.replyToEventId != null) {
      final p = await _resolver.resolveNoteById(rootNote.replyToEventId!);
      p.fold((_) {}, (note) {
        if (note != null) parentNotes.add(note);
      });
    }

    // ── Mentions / references rendered above the root ──────────────────────
    final mentionedNotes = <NoteEntity>[];
    if (event.savedOnly) {
      // Resolve refs from the edge table + saved set, so group-sourced
      // parents (with stripped eTagRefs) still render.
      final refResult = await _getSavedReferences.call(event.noteId);
      final refs = refResult.fold((_) => <SavedNoteEntity>[], (r) => r);
      mentionedNotes.addAll(
        refs.map((s) => s.toNoteEntity(savedEventIds: savedOnlyIds)),
      );
    } else {
      final mentionIds = rootNote.eTagRefs
          .where((id) =>
              id != rootNote.rootEventId && id != rootNote.replyToEventId)
          .toList();
      if (mentionIds.isNotEmpty) {
        final r = await _resolver.resolveMany(mentionIds);
        mentionedNotes.addAll(r.fold((_) => <NoteEntity>[], (n) => n));
      }
    }

    // ── Replies ────────────────────────────────────────────────────────────
    final List<NoteEntity> replies;
    if (event.savedOnly) {
      final repliesResult = await _getSavedReplies.call(event.noteId);
      final savedReplies =
          repliesResult.fold((_) => <SavedNoteEntity>[], (r) => r);
      replies = savedReplies
          .map((s) => s.toNoteEntity(savedEventIds: savedOnlyIds))
          .toList()
        ..sort((a, b) => a.created.compareTo(b.created));
    } else {
      final repliesResult = await _resolver.resolveReplies(rootNote.id);
      replies = repliesResult.fold((_) => <NoteEntity>[], (r) => r);
    }

    // ── Profiles for every visible author ──────────────────────────────────
    final profiles = <String, ProfileEntity>{};
    final pubkeys = {
      rootNote.authorPubkey,
      for (final n in parentNotes) n.authorPubkey,
      for (final n in mentionedNotes) n.authorPubkey,
      for (final n in replies) n.authorPubkey,
    };
    await Future.wait(pubkeys.map((pk) async {
      final pr = await _getProfile.call(pk);
      pr.fold((_) {}, (p) => profiles[p.pubkey] = p);
    }));

    emit(state.copyWith(
      status: ThreadStatus.loaded,
      root: root,
      parentNotes: parentNotes,
      mentionedNotes: mentionedNotes,
      replies: replies,
      profiles: profiles,
      savedOnly: event.savedOnly,
      savedOnlyIds: savedOnlyIds,
    ));

    await _markersSub?.cancel();
    _markersSub = _watchMarkers
        .call([rootNote.id, for (final r in replies) r.id])
        .listen((markers) {
      if (!isClosed) add(_ThreadMarkersUpdated(markers));
    });
  }

  Future<void> _onPost(PostReplyEvent event, Emitter<ThreadState> emit) async {
    final root = state.root;
    if (root == null ||
        (event.content.trim().isEmpty && event.attachments.isEmpty)) {
      return;
    }

    emit(state.copyWith(postStatus: ThreadPostStatus.posting));

    final result = await _postReply.call(PostReplyParams(
      root: root,
      content: event.content.trim(),
      mentionRefs: event.mentionRefs,
      attachments: event.attachments,
      // Saved-only threads always reply as feed notes (parity with prior
      // behavior — the saved root may be from a group/group the user can't post to).
      sourceOverride: state.savedOnly ? NoteSource.feed : null,
    ));

    await result.fold(
      (f) async => emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: f.toMessage(),
      )),
      (_) async {
        // Clear the sending state (so the send button stops spinning) and
        // reload so the new reply appears under the root. The reload keeps the
        // existing thread visible (see _onLoad).
        emit(state.copyWith(postStatus: ThreadPostStatus.idle));
        add(LoadThreadEvent(root.id, savedOnly: state.savedOnly));
      },
    );
  }
}
