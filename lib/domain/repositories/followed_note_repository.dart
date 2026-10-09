import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';

abstract class FollowedNoteRepository {
  Future<Either<Failure, List<FollowedNoteEntity>>> getAll();
  Future<Either<Failure, Unit>> followNote(String eventId, String contentPreview);
  Future<Either<Failure, Unit>> unfollowNote(String eventId);
  Future<Either<Failure, bool>> isFollowed(String eventId);
  Stream<bool> watchIsFollowed(String eventId);

  /// Live unread markers for [noteIds], only for notes inside a followed
  /// note's tree (the followed note, its replies, replies of replies, ...).
  /// Notes with nothing unread on or below them are left out.
  Stream<Map<String, ThreadUnreadMarker>> watchThreadUnreadMarkers(
    List<String> noteIds,
  );
}
