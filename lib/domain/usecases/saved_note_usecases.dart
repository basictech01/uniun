import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';

// ── SaveNoteUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class SaveNoteUseCase extends UseCase<Either<Failure, SavedNoteEntity>, NoteEntity> {
  final SavedNoteRepository _repository;
  const SaveNoteUseCase(this._repository);

  @override
  Future<Either<Failure, SavedNoteEntity>> call(
    NoteEntity input, {
    bool cached = false,
  }) {
    return _repository.saveNote(input);
  }
}

// ── UnsaveNoteUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class UnsaveNoteUseCase extends UseCase<Either<Failure, Unit>, String> {
  final SavedNoteRepository _repository;
  const UnsaveNoteUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String eventId, {bool cached = false}) {
    return _repository.unsaveNote(eventId);
  }
}

// ── IsSavedNoteUseCase ────────────────────────────────────────────────────────

@lazySingleton
class IsSavedNoteUseCase extends UseCase<Either<Failure, bool>, String> {
  final SavedNoteRepository _repository;
  const IsSavedNoteUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(String eventId, {bool cached = false}) {
    return _repository.isSaved(eventId);
  }
}

// ── GetAllSavedNotesUseCase ───────────────────────────────────────────────────

@lazySingleton
class GetAllSavedNotesUseCase
    extends NoParamsUseCase<Either<Failure, List<SavedNoteEntity>>> {
  final SavedNoteRepository _repository;
  const GetAllSavedNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> call() {
    return _repository.getAll();
  }
}
