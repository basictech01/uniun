/// Lightweight signals passed between the Flutter UI isolate and the
/// EmbeddedServer isolate via [SendPort] / [ReceivePort].
///
///   Ports carry ZERO payload data — only signal type.
///     All actual event data lives in Isar (OutboundEventModel, NoteModel…).
///     This keeps the IPC surface minimal and the system offline-safe.
///
/// Direction legend:
///   UI → Server : sent by [EmbeddedServerBridge.notify*] methods
///   Server → UI : received in [EmbeddedServerBridge._onSignal]
sealed class IsolateSignal {
  const IsolateSignal();
}

// ── UI → EmbeddedServer ──────────────────────────────────────────────────────

/// Flutter UI wrote a new [OutboundEventModel] with status `pending` to Isar.
/// EmbeddedServer should wake up and flush the outbound queue.
final class SignalNewOutboundEvent extends IsolateSignal {
  const SignalNewOutboundEvent();
}

// ── EmbeddedServer → UI ──────────────────────────────────────────────────────

/// A relay's WebSocket connection state changed.
/// UI may reflect this in a connection status indicator.
///
/// Note: new notes arriving from relays are NOT signalled here.
/// BLoCs use [Isar.collection.watchLazy()] for reactive data updates —
/// no IPC overhead needed on the read path.
final class SignalRelayStatus extends IsolateSignal {
  const SignalRelayStatus({required this.relayUrl, required this.connected});

  final String relayUrl;
  final bool connected;
}
