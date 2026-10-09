import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/domain/repositories/unread_repository.dart';

@Injectable(as: UnreadRepository)
class UnreadRepositoryImpl extends UnreadRepository {
  final Isar isar;
  UnreadRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, Unit>> markSeen(String eventId) async {
    try {
      await isar.writeTxn(() async {
        await isar.unreadNoteModels
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
  Future<Either<Failure, Unit>> markGroupSeen(String groupId) async {
    try {
      await isar.writeTxn(() async {
        await isar.unreadNoteModels
            .filter()
            .groupIdEqualTo(groupId)
            .deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markPrivateGroupSeen(
    String privateGroupId,
  ) async {
    try {
      await isar.writeTxn(() async {
        await isar.unreadNoteModels
            .filter()
            .privateGroupIdEqualTo(privateGroupId)
            .deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markConversationSeen(int conversationId) async {
    try {
      await isar.writeTxn(() async {
        await isar.unreadNoteModels
            .filter()
            .conversationIdEqualTo(conversationId)
            .deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> oldestUnreadTimeForGroup(
    String groupId,
  ) async {
    try {
      final row = await isar.unreadNoteModels
          .filter()
          .groupIdEqualTo(groupId)
          .sortByCreated()
          .findFirst();
      return Right(row?.created);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> oldestUnreadTimeForPrivateGroup(
    String groupId,
  ) async {
    try {
      final row = await isar.unreadNoteModels
          .filter()
          .privateGroupIdEqualTo(groupId)
          .sortByCreated()
          .findFirst();
      return Right(row?.created);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> oldestUnreadTimeForDm(
    String otherPubkey,
  ) async {
    try {
      final conv = await isar.dmConversationModels
          .where()
          .otherPubkeyEqualTo(otherPubkey)
          .findFirst();
      if (conv == null) return const Right(null);
      final row = await isar.unreadNoteModels
          .filter()
          .conversationIdEqualTo(conv.id)
          .sortByCreated()
          .findFirst();
      return Right(row?.created);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Stream<int> watchGroupUnreadCount(String groupId) => _count(
    () => isar.unreadNoteModels.filter().groupIdEqualTo(groupId).count(),
  );

  @override
  Stream<int> watchPrivateGroupUnreadCount(String groupId) => _count(
    () => isar.unreadNoteModels.filter().privateGroupIdEqualTo(groupId).count(),
  );

  @override
  Stream<int> watchDmUnreadCount(String otherPubkey) => _count(() async {
    final conv = await isar.dmConversationModels
        .where()
        .otherPubkeyEqualTo(otherPubkey)
        .findFirst();
    if (conv == null) return 0;
    return isar.unreadNoteModels
        .filter()
        .conversationIdEqualTo(conv.id)
        .count();
  });

  /// Emits the count now and again every time the unread table changes.
  Stream<int> _count(Future<int> Function() read) => isar.unreadNoteModels
      .watchLazy(fireImmediately: true)
      .asyncMap((_) => read())
      .distinct();
}
