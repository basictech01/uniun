import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/note_relation_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/domain/repositories/followed_note_repository.dart';
import 'package:uniun/features/mesh/sync/bodies/followed_note_body.dart';
import 'package:uniun/features/mesh/sync/mesh_event_codec.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

@Injectable(as: FollowedNoteRepository)
class FollowedNoteRepositoryImpl extends FollowedNoteRepository {
  final Isar isar;
  final MeshEventSigner _signer;
  FollowedNoteRepositoryImpl({
    required this.isar,
    required MeshEventSigner signer,
  }) : _signer = signer;

  /// Badge count = unread notes anywhere below the followed note (replies of
  /// replies included). Reading one deletes its unread row → count drops.
  Future<int> _deriveUnreadRefCount(String rootEventId) async {
    final below = await descendantIdsOf(isar, rootEventId);
    if (below.isEmpty) return 0;
    return isar.unreadNoteModels
        .filter()
        .anyOf(below, (q, id) => q.eventIdEqualTo(id))
        .count();
  }

  Future<FollowedNoteEntity> _toEntity(FollowedNoteModel model) async {
    final unreadRefs = await _deriveUnreadRefCount(model.eventId);
    return FollowedNoteEntity(
      eventId: model.eventId,
      contentPreview: model.contentPreview,
      followedAt: model.followedAt,
      newReferenceCount: unreadRefs,
    );
  }

  @override
  Future<Either<Failure, List<FollowedNoteEntity>>> getAll() async {
    try {
      final models = await isar.followedNoteModels
          .filter()
          .removedAtIsNull()
          .sortByFollowedAtDesc()
          .findAll();
      final entities = <FollowedNoteEntity>[];
      for (final m in models) {
        entities.add(await _toEntity(m));
      }
      return Right(entities);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> followNote(
      String eventId, String contentPreview) async {
    try {
      // Reactivate an existing tombstone rather than short-circuit if the row
      // was previously unfollowed on this device — the user meant "follow again".
      final existing = await isar.followedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (existing != null && existing.removedAt == null) {
        return const Right(unit);
      }

      final model = (existing ?? FollowedNoteModel())
        ..eventId = eventId
        ..contentPreview = contentPreview
        ..followedAt = DateTime.now()
        ..removedAt = null;

      model.signedNostrEvent = await _signer.sign(
        kind: MeshEventKinds.followedNote,
        dTag: eventId,
        content: FollowedNoteBody.forActive(model),
      );

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
      final model = await isar.followedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (model == null || model.removedAt != null) return const Right(unit);

      // Undo semantics per plan §5a: keep the row, flip to tombstone state,
      // re-sign a fresh mesh event with a NEWER `created_at`.
      model.removedAt = DateTime.now();
      model.signedNostrEvent = await _signer.sign(
        kind: MeshEventKinds.followedNote,
        dTag: eventId,
        content: FollowedNoteBody.forRemoved(model),
      );

      await isar.writeTxn(() async {
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
          .filter()
          .eventIdEqualTo(eventId)
          .removedAtIsNull()
          .findFirst();
      return Right(model != null);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Stream<bool> watchIsFollowed(String eventId) {
    return isar.followedNoteModels
        .filter()
        .eventIdEqualTo(eventId)
        .removedAtIsNull()
        .watch(fireImmediately: true)
        .map((rows) => rows.isNotEmpty);
  }

  @override
  Stream<Map<String, ThreadUnreadMarker>> watchThreadUnreadMarkers(
    List<String> noteIds,
  ) => isar.unreadNoteModels
      .watchLazy(fireImmediately: true)
      .asyncMap((_) => _threadMarkers(noteIds));

  Future<Map<String, ThreadUnreadMarker>> _threadMarkers(
    List<String> noteIds,
  ) async {
    final followed = await isar.followedNoteModels
        .filter()
        .removedAtIsNull()
        .eventIdProperty()
        .findAll();
    if (followed.isEmpty || noteIds.isEmpty) return const {};

    final tracked = <String>{...followed};
    for (final f in followed) {
      tracked.addAll(await descendantIdsOf(isar, f));
    }
    final unread = (await isar.unreadNoteModels
            .where()
            .eventIdProperty()
            .findAll())
        .where(tracked.contains)
        .toSet();
    if (unread.isEmpty) return const {};

    final out = <String, ThreadUnreadMarker>{};
    for (final id in noteIds) {
      if (!tracked.contains(id)) continue;
      final below = await descendantIdsOf(isar, id);
      final marker = ThreadUnreadMarker(
        unread: unread.contains(id),
        unreadInside: below.any(unread.contains),
      );
      if (marker.unread || marker.unreadInside) out[id] = marker;
    }
    return out;
  }
}
