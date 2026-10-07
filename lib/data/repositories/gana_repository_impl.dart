import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/models/gana_run_model.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/repositories/gana_repository.dart';
import 'package:uniun/features/mesh/sync/bodies/gana_body.dart';
import 'package:uniun/features/mesh/sync/mesh_event_codec.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

@Injectable(as: GanaRepository)
class GanaRepositoryImpl extends GanaRepository {
  final Isar isar;
  final MeshEventSigner _signer;

  GanaRepositoryImpl({required this.isar, required MeshEventSigner signer})
      : _signer = signer;

  @override
  Future<Either<Failure, GanaEntity>> upsertGana(GanaEntity g) async {
    try {
      final existing =
          await isar.ganaModels.filter().ganaIdEqualTo(g.ganaId).findFirst();

      final model = GanaModel()
        ..ganaId = g.ganaId
        ..name = g.name
        ..manasIds = g.manasIds
        ..taskPrompt = g.taskPrompt
        ..inputType = g.inputType
        ..inputRefId = g.inputRefId
        ..outputType = g.outputType
        ..outputGroupId = g.outputGroupId
        ..outputPrivateGroupId = g.outputPrivateGroupId
        ..outputDmConversationId = g.outputDmConversationId
        ..desiredModelId = g.desiredModelId
        ..desiredBackend = g.desiredBackend
        ..triggerReactive = g.triggerReactive
        ..triggerIntervalMinutes = g.triggerIntervalMinutes
        ..triggerMode = g.triggerMode
        ..maxOutputs = g.maxOutputs
        ..enabled = g.enabled
        ..lastProcessedEventId = g.lastProcessedEventId
        ..lastProcessedCreated = g.lastProcessedCreated
        ..lastRunAt = g.lastRunAt
        ..createdAt = g.createdAt
        ..updatedAt = g.updatedAt
        // Resurrection: re-signing as active clears any prior tombstone.
        ..removedAt = null;
      if (existing != null) {
        model.id = existing.id;
        // Preserve cursor state on update — the entity doesn't carry it back
        // in every code path.
        model.lastProcessedEventId = g.lastProcessedEventId ??
            existing.lastProcessedEventId;
        model.lastProcessedCreated = g.lastProcessedCreated ??
            existing.lastProcessedCreated;
        model.lastRunAt = g.lastRunAt ?? existing.lastRunAt;
        // Counters are written only by the engine, never by an edit.
        model.runsSucceeded = existing.runsSucceeded;
        model.runsFailed = existing.runsFailed;
        model.runsSkipped = existing.runsSkipped;
      }

      model.signedNostrEvent = await _signer.sign(
        kind: MeshEventKinds.gana,
        dTag: g.ganaId,
        content: GanaBody.forActive(model),
      );

      await isar.writeTxn(() async {
        await isar.ganaModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GanaEntity>>> getGanas() async {
    try {
      final rows = await isar.ganaModels
          .filter()
          .removedAtIsNull()
          .sortByUpdatedAtDesc()
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GanaEntity>>> getEnabledGanas() async {
    try {
      final rows = await isar.ganaModels
          .filter()
          .removedAtIsNull()
          .and()
          .enabledEqualTo(true)
          .sortByUpdatedAtDesc()
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GanaEntity>> getGanaById(String ganaId) async {
    try {
      final row = await isar.ganaModels
          .filter()
          .ganaIdEqualTo(ganaId)
          .and()
          .removedAtIsNull()
          .findFirst();
      if (row == null) {
        return const Left(Failure.notFoundFailure('Gana not found'));
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGana(String ganaId) async {
    try {
      final row =
          await isar.ganaModels.filter().ganaIdEqualTo(ganaId).findFirst();
      if (row == null) return const Right(unit);

      row
        ..removedAt = DateTime.now()
        ..enabled = false
        ..updatedAt = DateTime.now();
      row.signedNostrEvent = await _signer.sign(
        kind: MeshEventKinds.gana,
        dTag: ganaId,
        content: GanaBody.forRemoved(row),
      );

      await isar.writeTxn(() async {
        await isar.ganaModels.put(row);
        // Run history is local telemetry — never syncs (plan §Phase 5).
        // Purge the local run rows so tombstoned Ganas don't leave orphans.
        await isar.ganaRunModels.filter().ganaIdEqualTo(ganaId).deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setEnabled(String ganaId, bool enabled) async {
    try {
      final row = await isar.ganaModels
          .filter()
          .ganaIdEqualTo(ganaId)
          .and()
          .removedAtIsNull()
          .findFirst();
      if (row == null) {
        return const Left(Failure.notFoundFailure('Gana not found'));
      }
      row
        ..enabled = enabled
        ..updatedAt = DateTime.now();
      row.signedNostrEvent = await _signer.sign(
        kind: MeshEventKinds.gana,
        dTag: ganaId,
        content: GanaBody.forActive(row),
      );
      await isar.writeTxn(() async {
        await isar.ganaModels.put(row);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> advanceCursor({
    required String ganaId,
    String? lastProcessedEventId,
    DateTime? lastProcessedCreated,
    required DateTime lastRunAt,
  }) async {
    try {
      final row = await isar.ganaModels
          .filter()
          .ganaIdEqualTo(ganaId)
          .and()
          .removedAtIsNull()
          .findFirst();
      if (row == null) {
        return const Left(Failure.notFoundFailure('Gana not found'));
      }
      // Cursor state is per-device local — do NOT re-sign; leave
      // `signedNostrEvent` untouched so peers keep their own cursors.
      if (lastProcessedEventId != null) {
        row.lastProcessedEventId = lastProcessedEventId;
      }
      if (lastProcessedCreated != null) {
        row.lastProcessedCreated = lastProcessedCreated;
      }
      row.lastRunAt = lastRunAt;
      await isar.writeTxn(() async {
        await isar.ganaModels.put(row);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
