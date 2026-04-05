part of 'thread_bloc.dart';

sealed class ThreadEvent {
  const ThreadEvent();
}

final class LoadThreadEvent extends ThreadEvent {
  const LoadThreadEvent(this.noteId);
  final String noteId;
}

final class UpdateReplyTextEvent extends ThreadEvent {
  const UpdateReplyTextEvent(this.text);
  final String text;
}

/// null replyToId = replying to the root note
final class SetReplyTargetEvent extends ThreadEvent {
  const SetReplyTargetEvent({this.replyToId, this.replyToName});
  final String? replyToId;
  final String? replyToName;
}

final class PostReplyEvent extends ThreadEvent {
  const PostReplyEvent();
}

final class SwitchTabEvent extends ThreadEvent {
  const SwitchTabEvent(this.index);
  final int index;
}

/// Fired when the user taps the reply-count badge on a reply.
/// Fetches that reply's direct children lazily.
final class ExpandReplyEvent extends ThreadEvent {
  const ExpandReplyEvent(this.replyId);
  final String replyId;
}
