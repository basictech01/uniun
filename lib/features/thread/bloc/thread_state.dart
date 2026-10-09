part of 'thread_bloc.dart';

enum ThreadStatus { initial, loading, loaded, error }

enum ThreadPostStatus { idle, posting, error }

class ThreadState {
  const ThreadState({
    this.status = ThreadStatus.initial,
    this.root,
    this.parentNotes = const [],
    this.mentionedNotes = const [],
    this.replies = const [],
    this.profiles = const {},
    this.postStatus = ThreadPostStatus.idle,
    this.errorMessage,
    this.savedOnly = false,
    this.savedOnlyIds = const {},
    this.unreadMarkers = const {},
  });

  final ThreadStatus status;

  /// The resolved root note. Reply routing is derived from it on post
  /// (`NoteReplyRouting.replyTransport`).
  final NoteEntity? root;
  final List<NoteEntity> parentNotes;
  final List<NoteEntity> mentionedNotes;
  final List<NoteEntity> replies;
  final Map<String, ProfileEntity> profiles;
  final ThreadPostStatus postStatus;
  final String? errorMessage;
  final bool savedOnly;
  /// Event IDs of all saved notes. Populated in both modes: the visible
  /// universe in savedOnly mode, and the bookmark-marking set in normal mode.
  final Set<String> savedOnlyIds;

  /// Dots and "new reply inside" hints, only for notes inside a followed
  /// note's tree.
  final Map<String, ThreadUnreadMarker> unreadMarkers;

  NoteEntity? get rootNote => root;

  ThreadState copyWith({
    ThreadStatus? status,
    NoteEntity? root,
    List<NoteEntity>? parentNotes,
    List<NoteEntity>? mentionedNotes,
    List<NoteEntity>? replies,
    Map<String, ProfileEntity>? profiles,
    ThreadPostStatus? postStatus,
    String? errorMessage,
    bool? savedOnly,
    Set<String>? savedOnlyIds,
    Map<String, ThreadUnreadMarker>? unreadMarkers,
  }) {
    return ThreadState(
      status: status ?? this.status,
      root: root ?? this.root,
      parentNotes: parentNotes ?? this.parentNotes,
      mentionedNotes: mentionedNotes ?? this.mentionedNotes,
      replies: replies ?? this.replies,
      profiles: profiles ?? this.profiles,
      postStatus: postStatus ?? this.postStatus,
      errorMessage: errorMessage,
      savedOnly: savedOnly ?? this.savedOnly,
      savedOnlyIds: savedOnlyIds ?? this.savedOnlyIds,
      unreadMarkers: unreadMarkers ?? this.unreadMarkers,
    );
  }
}
