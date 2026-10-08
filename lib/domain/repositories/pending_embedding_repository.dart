import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';

/// Notes waiting for a vector. See `PendingEmbeddingModel`.
abstract class PendingEmbeddingRepository {
  /// Queues [eventId]. Queueing a note twice keeps one row (newest text,
  /// attempts reset).
  Future<Either<Failure, Unit>> enqueue(String eventId, String text);

  /// The newest queued note, or null when the queue is empty.
  Future<Either<Failure, PendingEmbeddingItem?>> next();

  Future<Either<Failure, Unit>> remove(String eventId);

  /// Counts one failed attempt and returns the new total (0 if the row is gone).
  Future<Either<Failure, int>> recordFailure(String eventId);

  Future<Either<Failure, int>> count();
}

class PendingEmbeddingItem {
  const PendingEmbeddingItem({required this.eventId, required this.text});
  final String eventId;
  final String text;
}
