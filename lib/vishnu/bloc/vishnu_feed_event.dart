part of 'vishnu_feed_bloc.dart';

sealed class VishnuFeedEvent {
  const VishnuFeedEvent();
}

final class LoadFeedEvent extends VishnuFeedEvent {
  const LoadFeedEvent();
}

final class RefreshFeedEvent extends VishnuFeedEvent {
  const RefreshFeedEvent();
}

final class LoadMoreFeedEvent extends VishnuFeedEvent {
  const LoadMoreFeedEvent();
}

final class SaveFeedNoteEvent extends VishnuFeedEvent {
  const SaveFeedNoteEvent(this.note);
  final NoteEntity note;
}

final class UnsaveFeedNoteEvent extends VishnuFeedEvent {
  const UnsaveFeedNoteEvent(this.noteId);
  final String noteId;
}
