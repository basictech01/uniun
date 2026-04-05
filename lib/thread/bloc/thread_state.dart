part of 'thread_bloc.dart';

enum ThreadStatus { initial, loading, loaded, error }

enum ThreadPostStatus { idle, posting, posted, error }

class ThreadState {
  const ThreadState({
    this.rootNote,
    this.profiles = const {},
    this.replies = const [],
    this.replyCounts = const {},
    this.nestedReplies = const {},
    this.replyText = '',
    this.replyingToId,
    this.replyingToName,
    this.activeTab = 0,
    this.status = ThreadStatus.initial,
    this.postStatus = ThreadPostStatus.idle,
    this.errorMessage,
  });

  final NoteEntity? rootNote;
  /// pubkey → ProfileEntity for every author visible in this thread
  final Map<String, ProfileEntity> profiles;
  /// Direct replies to the root note (replyToEventId == rootNote.id)
  final List<NoteEntity> replies;
  /// noteId → reply count (used on reply items themselves)
  final Map<String, int> replyCounts;
  /// replyId → its direct replies (one level of nesting)
  final Map<String, List<NoteEntity>> nestedReplies;

  final String replyText;
  /// null = composing a reply to the root note
  final String? replyingToId;
  final String? replyingToName;

  final int activeTab; // 0 = Replies, 1 = References
  final ThreadStatus status;
  final ThreadPostStatus postStatus;
  final String? errorMessage;

  ProfileEntity? profileFor(String pubkey) => profiles[pubkey];

  bool get canPost => replyText.trim().isNotEmpty &&
      postStatus != ThreadPostStatus.posting;

  ThreadState copyWith({
    NoteEntity? rootNote,
    Map<String, ProfileEntity>? profiles,
    List<NoteEntity>? replies,
    Map<String, int>? replyCounts,
    Map<String, List<NoteEntity>>? nestedReplies,
    String? replyText,
    Object? replyingToId = _sentinel,
    Object? replyingToName = _sentinel,
    int? activeTab,
    ThreadStatus? status,
    ThreadPostStatus? postStatus,
    String? errorMessage,
  }) {
    return ThreadState(
      rootNote: rootNote ?? this.rootNote,
      profiles: profiles ?? this.profiles,
      replies: replies ?? this.replies,
      replyCounts: replyCounts ?? this.replyCounts,
      nestedReplies: nestedReplies ?? this.nestedReplies,
      replyText: replyText ?? this.replyText,
      replyingToId: replyingToId == _sentinel
          ? this.replyingToId
          : replyingToId as String?,
      replyingToName: replyingToName == _sentinel
          ? this.replyingToName
          : replyingToName as String?,
      activeTab: activeTab ?? this.activeTab,
      status: status ?? this.status,
      postStatus: postStatus ?? this.postStatus,
      errorMessage: errorMessage,
    );
  }
}

const _sentinel = Object();
