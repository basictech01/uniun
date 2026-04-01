import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

abstract class NoteRepository {
  /// Fetch notes from local cache (feed — latest first)
  Future<Either<Failure, List<NoteEntity>>> getFeed({
    required int limit,
    DateTime? before,
  });

  /// Get a single note by Nostr event ID
  Future<Either<Failure, NoteEntity>> getNoteById(String eventId);

  /// Direct replies to a note — notes where replyToEventId == eventId.
  Future<Either<Failure, List<NoteEntity>>> getReplies(String eventId);

  /// Full thread — root note + all notes where rootEventId == rootEventId,
  /// sorted chronologically. Use this to render a Twitter-style thread view.
  Future<Either<Failure, List<NoteEntity>>> getThread(String rootEventId);

  /// Persist a note (from relay or created locally by the user).
  Future<Either<Failure, NoteEntity>> saveNote(NoteEntity note);

  /// Mark a note as seen (updates isSeen flag)
  Future<Either<Failure, Unit>> markAsSeen(String eventId);
}
