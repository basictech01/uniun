import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/outbound_status.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/outbound_event_model.dart';
import 'package:uniun/domain/entities/outbound_event/outbound_event_entity.dart';
import 'package:uniun/domain/repositories/outbound_event_repository.dart';

@Injectable(as: OutboundEventRepository)
class OutboundEventRepositoryImpl extends OutboundEventRepository {
  final Isar isar;
  OutboundEventRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, int>> enqueue(String serializedEvent) async {
    try {
      final model = OutboundEventModel()
        ..serializedEvent = serializedEvent
        ..status = OutboundStatus.pending
        ..createdAt = DateTime.now()
        ..retryCount = 0;

      late int id;
      await isar.writeTxn(() async {
        id = await isar.outboundEventModels.put(model);
      });
      return Right(id);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OutboundEventEntity>>> getPending() async {
    try {
      final models = await isar.outboundEventModels
          .filter()
          .statusEqualTo(OutboundStatus.pending)
          .sortByCreatedAt()
          .findAll();
      return Right(models.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OutboundEventEntity>>> getFailedForRetry({
    int maxRetries = 3,
  }) async {
    try {
      final models = await isar.outboundEventModels
          .filter()
          .statusEqualTo(OutboundStatus.failed)
          .retryCountLessThan(maxRetries)
          .sortByCreatedAt()
          .findAll();
      return Right(models.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateStatus(
      int id, OutboundStatus status) async {
    try {
      final model = await isar.outboundEventModels.get(id);
      if (model == null) return const Right(unit);

      await isar.writeTxn(() async {
        model.status = status;
        await isar.outboundEventModels.put(model);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> incrementRetry(int id) async {
    try {
      final model = await isar.outboundEventModels.get(id);
      if (model == null) return const Right(unit);

      await isar.writeTxn(() async {
        model.retryCount += 1;
        await isar.outboundEventModels.put(model);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearSent({
    Duration age = const Duration(days: 7),
  }) async {
    try {
      final cutoff = DateTime.now().subtract(age);
      await isar.writeTxn(() async {
        await isar.outboundEventModels
            .filter()
            .statusEqualTo(OutboundStatus.sent)
            .createdAtLessThan(cutoff)
            .deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
