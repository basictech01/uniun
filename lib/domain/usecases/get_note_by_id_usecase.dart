import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@lazySingleton
class GetNoteByIdUseCase
    extends UseCase<Either<Failure, NoteEntity>, String> {
  final NoteRepository repository;
  const GetNoteByIdUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.getNoteById(eventId);
  }
}
