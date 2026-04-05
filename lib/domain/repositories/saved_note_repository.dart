import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';

abstract class SavedNoteRepository {
  /// Save a note (bookmark). Idempotent — second call is a no-op.
  Future<Either<Failure, SavedNoteEntity>> saveNote(NoteEntity note);

  /// Unsave a note.
  Future<Either<Failure, Unit>> unsaveNote(String eventId);

  /// Whether a note is currently saved by the user.
  Future<Either<Failure, bool>> isSaved(String eventId);

  /// All saved notes, newest-saved first.
  Future<Either<Failure, List<SavedNoteEntity>>> getAll();
}
