import 'dart:async';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:uniun/core/isolate/isolate_signal.dart';

/// Entry point signature the EmbeddedServer isolate must conform to.
///
/// The EmbeddedServer receives [mainSendPort] as its first argument.
/// It must immediately send back its own [SendPort] as the handshake,
/// then use [mainSendPort] to forward [IsolateSignal]s to the UI.
///
/// Example (EmbeddedServer team's code):
/// ```dart
/// void embeddedServerMain(SendPort mainSendPort) {
///   final serverReceivePort = ReceivePort();
///   mainSendPort.send(serverReceivePort.sendPort); // handshake
///   serverReceivePort.listen((signal) {
///     if (signal is SignalNewOutboundEvent) { /* flush queue */ }
///   });
/// }
/// ```
typedef EmbeddedServerEntryPoint = void Function(SendPort mainSendPort);

/// Owns the bidirectional signal channel between the Flutter UI isolate
/// and the EmbeddedServer isolate.
///
/// Lifecycle:
///   1. [SplashPage] calls [start(embeddedServerMain)] after DI is ready.
///   2. BLoCs call [notifyNewOutboundEvent()] after writing to the Isar queue.
///   3. [relayStatus] stream surfaces connection state to the UI.
///   4. [dispose()] is called on app shutdown.
///
/// Data flow (read path):
///   BLoCs use [Isar.collection.watchLazy()] directly — no signal needed.
///   The EmbeddedServer writes incoming notes to Isar; Isar notifies watchers.
@singleton
class EmbeddedServerBridge {
  final _relayStatusController =
      StreamController<SignalRelayStatus>.broadcast();

  SendPort? _serverSendPort;
  ReceivePort? _uiReceivePort;
  Isolate? _serverIsolate;

  bool _started = false;

  /// Stream of relay connection status changes from EmbeddedServer.
  Stream<SignalRelayStatus> get relayStatus => _relayStatusController.stream;

  /// Whether the bridge has been started and the handshake completed.
  bool get isRunning => _started && _serverSendPort != null;

  /// Spawn the EmbeddedServer isolate and complete the port handshake.
  ///
  /// Call once from [SplashPage] after [initGetIt()] resolves.
  /// Safe to call again after a crash — kills existing isolate first.
  Future<void> start(EmbeddedServerEntryPoint entryPoint) async {
    if (_started) await _teardown();

    _uiReceivePort = ReceivePort();

    _serverIsolate =
        await Isolate.spawn(entryPoint, _uiReceivePort!.sendPort);

    final handshakeCompleter = Completer<SendPort>();

    _uiReceivePort!.listen((message) {
      if (!handshakeCompleter.isCompleted) {
        // First message from EmbeddedServer is its SendPort — the handshake.
        handshakeCompleter.complete(message as SendPort);
      } else {
        // All subsequent messages are IsolateSignals.
        _onSignal(message);
      }
    });

    _serverSendPort = await handshakeCompleter.future;
    _started = true;
  }

  // ── UI → EmbeddedServer signals ────────────────────────────────────────────

  /// Notify the EmbeddedServer that a new event is in the outbound Isar queue.
  ///
  /// Call this immediately after [OutboundEventRepository.enqueue()] succeeds.
  /// The EmbeddedServer will query Isar for pending events and broadcast them.
  void notifyNewOutboundEvent() {
    _serverSendPort?.send(const SignalNewOutboundEvent());
  }

  // ── EmbeddedServer → UI signals ────────────────────────────────────────────

  void _onSignal(dynamic message) {
    if (message is SignalRelayStatus) {
      _relayStatusController.add(message);
    }
    // Expand here as new signal types are agreed on with the EmbeddedServer team.
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> _teardown() async {
    _uiReceivePort?.close();
    _serverIsolate?.kill(priority: Isolate.immediate);
    _uiReceivePort = null;
    _serverSendPort = null;
    _serverIsolate = null;
    _started = false;
  }

  /// Release all resources. Call on app shutdown.
  Future<void> dispose() async {
    await _teardown();
    await _relayStatusController.close();
  }
}
