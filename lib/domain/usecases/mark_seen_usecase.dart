import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@lazySingleton
class MarkSeenUseCase extends UseCase<Either<Failure, Unit>, String> {
  final NoteRepository repository;
  const MarkSeenUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.markAsSeen(eventId);
  }
}
