import 'package:dartz/dartz.dart';
import 'package:uniun/core/enum/outbound_status.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/outbound_event/outbound_event_entity.dart';

/// Contract for the durable outbound event queue.
///
/// The Flutter UI calls [enqueue] after signing a Nostr event, then signals
/// the EmbeddedServer via [EmbeddedServerBridge.notifyNewOutboundEvent()].
///
/// The EmbeddedServer opens its own Isar connection and uses the same
/// [OutboundEventModel] collection to read pending events and update statuses.
abstract class OutboundEventRepository {
  /// Add a signed event to the queue with [OutboundStatus.pending].
  /// Returns the Isar [id] of the new row on success.
  Future<Either<Failure, int>> enqueue(String serializedEvent);

  /// All events with [OutboundStatus.pending].
  Future<Either<Failure, List<OutboundEventEntity>>> getPending();

  /// Events with [OutboundStatus.failed] where [retryCount] < [maxRetries].
  Future<Either<Failure, List<OutboundEventEntity>>> getFailedForRetry({
    int maxRetries = 3,
  });

  /// Update the status of a single event (called by EmbeddedServer via its
  /// own Isar reference, or by the UI for local status tracking).
  Future<Either<Failure, Unit>> updateStatus(int id, OutboundStatus status);

  /// Increment [retryCount] on failure.
  Future<Either<Failure, Unit>> incrementRetry(int id);

  /// Delete [OutboundStatus.sent] events older than [age].
  Future<Either<Failure, Unit>> clearSent({
    Duration age = const Duration(days: 7),
  });
}
