import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/inputs/note_input.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@lazySingleton
class GetFeedUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, GetFeedInput> {
  final NoteRepository repository;
  const GetFeedUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    GetFeedInput input, {
    bool cached = false,
  }) {
    return repository.getFeed(limit: input.limit, before: input.before);
  }
}
