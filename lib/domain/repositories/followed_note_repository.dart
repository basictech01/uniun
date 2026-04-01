import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';

abstract class FollowedNoteRepository {
  Future<Either<Failure, List<FollowedNoteEntity>>> getAll();
  Future<Either<Failure, Unit>> followNote(String eventId, String contentPreview);
  Future<Either<Failure, Unit>> unfollowNote(String eventId);
  Future<Either<Failure, Unit>> clearNewReferences(String eventId);
  Future<Either<Failure, bool>> isFollowed(String eventId);
}
