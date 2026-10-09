import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/repositories/unread_repository.dart';

// ── Mark-seen use cases ───────────────────────────────────────────────────────

@lazySingleton
class MarkUnreadSeenUseCase extends UseCase<Either<Failure, Unit>, String> {
  final UnreadRepository _repository;
  const MarkUnreadSeenUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String eventId, {bool cached = false}) =>
      _repository.markSeen(eventId);
}

@lazySingleton
class MarkGroupSeenUseCase extends UseCase<Either<Failure, Unit>, String> {
  final UnreadRepository _repository;
  const MarkGroupSeenUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String groupId, {bool cached = false}) =>
      _repository.markGroupSeen(groupId);
}

@lazySingleton
class MarkPrivateGroupSeenUseCase
    extends UseCase<Either<Failure, Unit>, String> {
  final UnreadRepository _repository;
  const MarkPrivateGroupSeenUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String groupId, {bool cached = false}) =>
      _repository.markPrivateGroupSeen(groupId);
}

@lazySingleton
class MarkConversationSeenUseCase extends UseCase<Either<Failure, Unit>, int> {
  final UnreadRepository _repository;
  const MarkConversationSeenUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(
    int conversationId, {
    bool cached = false,
  }) => _repository.markConversationSeen(conversationId);
}

// ── Read→unread boundary ──────────────────────────────────────────────────────

@lazySingleton
class GetGroupOldestUnreadTimeUseCase
    extends UseCase<Either<Failure, DateTime?>, String> {
  final UnreadRepository _repository;
  const GetGroupOldestUnreadTimeUseCase(this._repository);

  @override
  Future<Either<Failure, DateTime?>> call(
    String groupId, {
    bool cached = false,
  }) => _repository.oldestUnreadTimeForGroup(groupId);
}

@lazySingleton
class GetPrivateGroupOldestUnreadTimeUseCase
    extends UseCase<Either<Failure, DateTime?>, String> {
  final UnreadRepository _repository;
  const GetPrivateGroupOldestUnreadTimeUseCase(this._repository);

  @override
  Future<Either<Failure, DateTime?>> call(
    String groupId, {
    bool cached = false,
  }) => _repository.oldestUnreadTimeForPrivateGroup(groupId);
}

@lazySingleton
class GetDmOldestUnreadTimeUseCase
    extends UseCase<Either<Failure, DateTime?>, String> {
  final UnreadRepository _repository;
  const GetDmOldestUnreadTimeUseCase(this._repository);

  @override
  Future<Either<Failure, DateTime?>> call(
    String otherPubkey, {
    bool cached = false,
  }) => _repository.oldestUnreadTimeForDm(otherPubkey);
}

// ── Live unread counts ────────────────────────────────────────────────────────

@lazySingleton
class WatchGroupUnreadCountUseCase extends StreamUseCase<int, String> {
  final UnreadRepository _repository;
  const WatchGroupUnreadCountUseCase(this._repository);

  @override
  Stream<int> call(String groupId) =>
      _repository.watchGroupUnreadCount(groupId);
}

@lazySingleton
class WatchPrivateGroupUnreadCountUseCase extends StreamUseCase<int, String> {
  final UnreadRepository _repository;
  const WatchPrivateGroupUnreadCountUseCase(this._repository);

  @override
  Stream<int> call(String groupId) =>
      _repository.watchPrivateGroupUnreadCount(groupId);
}

@lazySingleton
class WatchDmUnreadCountUseCase extends StreamUseCase<int, String> {
  final UnreadRepository _repository;
  const WatchDmUnreadCountUseCase(this._repository);

  @override
  Stream<int> call(String otherPubkey) =>
      _repository.watchDmUnreadCount(otherPubkey);
}
