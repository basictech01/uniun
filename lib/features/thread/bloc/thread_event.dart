part of 'thread_bloc.dart';

sealed class ThreadEvent {
  const ThreadEvent();
}

/// Loads (or reloads) the thread for [noteId], resolving it from whichever
/// collection holds it. [savedOnly] filters replies to saved notes (feed only).
final class LoadThreadEvent extends ThreadEvent {
  const LoadThreadEvent(this.noteId, {this.savedOnly = false});
  final String noteId;
  final bool savedOnly;
}

/// Posts a reply to the current root, routed by source via [PostReplyUseCase].
final class PostReplyEvent extends ThreadEvent {
  const PostReplyEvent(
    this.content, {
    this.mentionRefs = const [],
    this.attachments = const [],
  });
  final String content;
  final List<String> mentionRefs;
  final List<MediaBlobEntity> attachments;
}

final class _ThreadMarkersUpdated extends ThreadEvent {
  const _ThreadMarkersUpdated(this.markers);
  final Map<String, ThreadUnreadMarker> markers;
}
