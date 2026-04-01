import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

/// Returns the full thread for a given root note event ID.
///
/// Result: [root note, ...all replies sorted chronologically]
/// Use this to render a Twitter-style thread view.
///
/// Input: the Nostr event ID of the root (top-level) note.
@lazySingleton
class GetThreadUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository repository;
  const GetThreadUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String rootEventId, {
    bool cached = false,
  }) {
    return repository.getThread(rootEventId);
  }
}
