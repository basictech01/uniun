import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@lazySingleton
class GetRepliesUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository repository;
  const GetRepliesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.getReplies(eventId);
  }
}
