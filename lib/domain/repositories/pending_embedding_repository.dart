/// Notes waiting for a vector. See `PendingEmbeddingModel`.
abstract class PendingEmbeddingRepository {
  /// Adds [eventId] to the queue. Idempotent: queueing a note twice keeps one
  /// row (the newest text, attempts reset).
  Future<void> enqueue(String eventId, String text);

  /// The next row to embed, newest first, or null when the queue is empty.
  /// Newest first so a note the user just saved never waits behind a backlog.
  Future<PendingEmbeddingItem?> next();

  /// Removes [eventId] once its vector is stored.
  Future<void> remove(String eventId);

  /// Counts one failed attempt and returns the new total (0 if the row is gone).
  Future<int> recordFailure(String eventId);

  Future<int> count();
}

class PendingEmbeddingItem {
  const PendingEmbeddingItem({required this.eventId, required this.text});
  final String eventId;
  final String text;
}
