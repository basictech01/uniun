import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@lazySingleton
class SaveNoteUseCase
    extends UseCase<Either<Failure, NoteEntity>, NoteEntity> {
  final NoteRepository repository;
  const SaveNoteUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(
    NoteEntity note, {
    bool cached = false,
  }) {
    return repository.saveNote(note);
  }
}
