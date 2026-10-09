import 'package:freezed_annotation/freezed_annotation.dart';

part 'thread_unread_marker.freezed.dart';

/// What a note in a followed note's tree shows in a thread: a dot when it is
/// itself unread, and a trail hint when something unread sits below it.
@freezed
abstract class ThreadUnreadMarker with _$ThreadUnreadMarker {
  const factory ThreadUnreadMarker({
    required bool unread,
    required bool unreadInside,
  }) = _ThreadUnreadMarker;
}
