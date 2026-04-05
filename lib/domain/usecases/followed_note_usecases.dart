import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/repositories/followed_note_repository.dart';

// ── FollowNoteInput ───────────────────────────────────────────────────────────

class FollowNoteInput {
  const FollowNoteInput({
    required this.eventId,
    required this.contentPreview,
  });
  final String eventId;
  final String contentPreview;
}

// ── GetAllFollowedNotesUseCase ────────────────────────────────────────────────

@lazySingleton
class GetAllFollowedNotesUseCase
    extends NoParamsUseCase<Either<Failure, List<FollowedNoteEntity>>> {
  final FollowedNoteRepository _repository;
  const GetAllFollowedNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<FollowedNoteEntity>>> call() {
    return _repository.getAll();
  }
}

// ── FollowNoteUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class FollowNoteUseCase
    extends UseCase<Either<Failure, Unit>, FollowNoteInput> {
  final FollowedNoteRepository _repository;
  const FollowNoteUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(
    FollowNoteInput input, {
    bool cached = false,
  }) {
    return _repository.followNote(input.eventId, input.contentPreview);
  }
}

// ── UnfollowNoteUseCase ───────────────────────────────────────────────────────

@lazySingleton
class UnfollowNoteUseCase extends UseCase<Either<Failure, Unit>, String> {
  final FollowedNoteRepository _repository;
  const UnfollowNoteUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String eventId, {bool cached = false}) {
    return _repository.unfollowNote(eventId);
  }
}

// ── ClearNewReferencesUseCase ─────────────────────────────────────────────────

@lazySingleton
class ClearNewReferencesUseCase
    extends UseCase<Either<Failure, Unit>, String> {
  final FollowedNoteRepository _repository;
  const ClearNewReferencesUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(
    String eventId, {
    bool cached = false,
  }) {
    return _repository.clearNewReferences(eventId);
  }
}
