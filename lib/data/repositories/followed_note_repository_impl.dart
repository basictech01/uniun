import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/repositories/followed_note_repository.dart';

@Injectable(as: FollowedNoteRepository)
class FollowedNoteRepositoryImpl extends FollowedNoteRepository {
  final Isar isar;
  FollowedNoteRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, List<FollowedNoteEntity>>> getAll() async {
    try {
      final models = await isar.followedNoteModels
          .where()
          .sortByFollowedAtDesc()
          .findAll();
      return Right(models.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> followNote(
      String eventId, String contentPreview) async {
    try {
      final existing = await isar.followedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (existing != null) return const Right(unit);

      final model = FollowedNoteModel()
        ..eventId = eventId
        ..contentPreview = contentPreview
        ..followedAt = DateTime.now()
        ..newReferenceCount = 0;

      await isar.writeTxn(() async {
        await isar.followedNoteModels.put(model);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unfollowNote(String eventId) async {
    try {
      await isar.writeTxn(() async {
        await isar.followedNoteModels
            .where()
            .eventIdEqualTo(eventId)
            .deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearNewReferences(String eventId) async {
    try {
      final model = await isar.followedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (model == null) return const Right(unit);

      await isar.writeTxn(() async {
        model.newReferenceCount = 0;
        await isar.followedNoteModels.put(model);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFollowed(String eventId) async {
    try {
      final model = await isar.followedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      return Right(model != null);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
