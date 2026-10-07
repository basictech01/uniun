import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/pending_embedding_model.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';

@Injectable(as: PendingEmbeddingRepository)
class PendingEmbeddingRepositoryImpl extends PendingEmbeddingRepository {
  final Isar isar;
  PendingEmbeddingRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, Unit>> enqueue(String eventId, String text) async {
    try {
      await isar.writeTxn(() async {
        await isar.pendingEmbeddingModels.put(
          PendingEmbeddingModel()
            ..eventId = eventId
            ..text = text
            ..createdAt = DateTime.now(),
        );
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PendingEmbeddingItem?>> next() async {
    try {
      final row = await isar.pendingEmbeddingModels
          .where()
          .sortByCreatedAtDesc()
          .findFirst();
      return Right(
        row == null
            ? null
            : PendingEmbeddingItem(eventId: row.eventId, text: row.text),
      );
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> remove(String eventId) async {
    try {
      await isar.writeTxn(() async {
        await isar.pendingEmbeddingModels
            .filter()
            .eventIdEqualTo(eventId)
            .deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> recordFailure(String eventId) async {
    try {
      final attempts = await isar.writeTxn(() async {
        final row = await isar.pendingEmbeddingModels
            .filter()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (row == null) return 0;
        row.attempts++;
        await isar.pendingEmbeddingModels.put(row);
        return row.attempts;
      });
      return Right(attempts);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> count() async {
    try {
      return Right(await isar.pendingEmbeddingModels.count());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
