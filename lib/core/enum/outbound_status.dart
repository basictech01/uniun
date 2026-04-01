/// Lifecycle of an event in the outbound Isar queue.
/// Both the Flutter UI isolate and the EmbeddedServer isolate read/write this.
enum OutboundStatus {
  /// Written by the Flutter UI — waiting to be picked up by EmbeddedServer.
  pending,

  /// EmbeddedServer is actively broadcasting to relays right now.
  broadcasting,

  /// At least one relay confirmed receipt.
  sent,

  /// All relay attempts failed — eligible for retry if retryCount < maxRetries.
  failed,
}
