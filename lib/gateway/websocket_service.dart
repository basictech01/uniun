import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/enum/relay_status.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/note_model.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages a single WebSocket connection to one Nostr relay.
///
/// Responsibilities:
///  - Maintain a persistent connection with exponential-backoff reconnect.
///  - Maintain an [_lastSentQueueId] cursor into [EventQueueModel]; query the
///    next unsent item, send it, then wait for the relay's ["OK"] response
///    before advancing the cursor.
///  - Receive incoming Nostr events and write them directly to [NoteModel].
///  - Update [RelayModel.status] on every connection state change.
class WebSocketService {
  final String url;
  final bool read;
  final bool write;
  final Isar _isar;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _socketSub;

  /// Isar autoincrement id of the last successfully ACK'd queue item.
  /// The service sends items with id > [_lastSentQueueId].
  int _lastSentQueueId;

  int _reconnectAttempt = 0;
  bool _isConnected = false;
  bool _disposed = false;
  Timer? _reconnectTimer;

  /// eventId of the event currently in-flight (sent, waiting for OK).
  String? _pendingEventId;

  /// EventQueueModel.id of the event currently in-flight.
  int? _pendingQueueId;

  WebSocketService({
    required this.url,
    required this.read,
    required this.write,
    required Isar isar,
    required int startFromQueueId,
  })  : _isar = isar,
        _lastSentQueueId = startFromQueueId;

  bool get isConnected => _isConnected;

  // ── Connection lifecycle ───────────────────────────────────────────────────

  void connect() {
    if (_disposed) return;
    _updateStatus(RelayStatus.reconnecting);
    try {
      _socket = WebSocketChannel.connect(Uri.parse(url));
      _socketSub = _socket!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      // Mark connected — relay handshake is implicit in WebSocket
      _isConnected = true;
      _reconnectAttempt = 0;
      _updateStatus(RelayStatus.connected);
      _processSendQueue();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _socketSub?.cancel();
    _socket?.sink.close();
    _isConnected = false;
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _isConnected = false;
    _pendingEventId = null;
    _pendingQueueId = null;
    _updateStatus(RelayStatus.disconnected);
    _socketSub?.cancel();
    _socket?.sink.close();

    final delaySec = min(pow(2, _reconnectAttempt).toInt(), 60);
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySec), connect);
  }

  // ── Outbound — send queue ──────────────────────────────────────────────────

  /// Called by [CentralRelayManager] when a new item is enqueued.
  void onNewQueueItem() => _processSendQueue();

  Future<void> _processSendQueue() async {
    // Guard: only send if this relay is a write relay, connected, and idle.
    if (!write || !_isConnected || _pendingEventId != null) return;

    final next = await _isar.eventQueueModels
        .where()
        .idGreaterThan(_lastSentQueueId)
        .findFirst();

    if (next == null) return;

    _pendingEventId = next.eventId;
    _pendingQueueId = next.id;
    _socket!.sink.add(next.serializedRelayMessage);
  }

  // ── Inbound — relay messages ───────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    List<dynamic> data;
    try {
      data = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }
    if (data.isEmpty) return;

    final type = data[0] as String;
    switch (type) {
      case 'OK':
        _handleOk(data);
      case 'EVENT':
        if (read && data.length >= 3) {
          _storeIncomingEvent(data[2] as Map<String, dynamic>);
        }
      case 'EOSE':
        // End of stored events — no action needed in v1.
        break;
      case 'NOTICE':
        // Relay notice — silently ignored in v1.
        break;
    }
  }

  Future<void> _handleOk(List<dynamic> data) async {
    if (data.length < 3) return;
    final eventId = data[1] as String?;
    final accepted = data[2] as bool?;
    if (eventId == null || accepted == null) return;
    if (eventId != _pendingEventId) return;

    if (accepted) {
      // Increment sentCount so CentralRelayManager can dequeue when threshold met.
      await _isar.writeTxn(() async {
        final item = await _isar.eventQueueModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (item != null) {
          item.sentCount++;
          await _isar.eventQueueModels.put(item);
        }
      });
      _lastSentQueueId = _pendingQueueId!;
    }

    // Whether accepted or rejected, release the pending slot and move on.
    _pendingEventId = null;
    _pendingQueueId = null;
    _processSendQueue();
  }

  /// Parses an incoming Nostr event map and persists it to [NoteModel].
  ///
  /// Idempotent — skips if [eventId] already exists.
  /// Only handles Kind 1 (short text notes) in v1.
  Future<void> _storeIncomingEvent(Map<String, dynamic> event) async {
    final kind = event['kind'] as int?;
    if (kind != 1) return; // Kind 0, 42, Blossom → future

    final eventId = event['id'] as String?;
    if (eventId == null) return;

    final existing = await _isar.noteModels
        .where()
        .eventIdEqualTo(eventId)
        .findFirst();
    if (existing != null) return;

    final model = _parseNoteModel(event);
    await _isar.writeTxn(() async {
      await _isar.noteModels.put(model);
    });
    // Isar watcher in Isolate 1 fires automatically — Flutter UI updates.
  }

  NoteModel _parseNoteModel(Map<String, dynamic> event) {
    final rawTags = (event['tags'] as List<dynamic>? ?? []);

    String? rootEventId;
    String? replyToEventId;
    final eTagRefs = <String>[];
    final pTagRefs = <String>[];
    final tTags = <String>[];

    for (final rawTag in rawTags) {
      if (rawTag is! List || rawTag.isEmpty) continue;
      final tagName = rawTag[0] as String?;
      if (tagName == null || rawTag.length < 2) continue;

      switch (tagName) {
        case 'e':
          final tagId = rawTag[1] as String;
          eTagRefs.add(tagId);
          if (rawTag.length > 3) {
            final marker = rawTag[3] as String?;
            if (marker == 'root') rootEventId = tagId;
            if (marker == 'reply') replyToEventId = tagId;
          }
        case 'p':
          pTagRefs.add(rawTag[1] as String);
        case 't':
          tTags.add(rawTag[1] as String);
      }
    }

    final content = event['content'] as String? ?? '';
    final createdAtSec = event['created_at'] as int? ?? 0;

    return NoteModel(
      eventId: event['id'] as String,
      sig: event['sig'] as String? ?? '',
      authorPubkey: event['pubkey'] as String? ?? '',
      content: content,
      type: NoteType.text,
      eTagRefs: eTagRefs,
      rootEventId: rootEventId,
      replyToEventId: replyToEventId,
      pTagRefs: pTagRefs,
      tTags: tTags,
      cachedReactionCount: 0,
      created: DateTime.fromMillisecondsSinceEpoch(createdAtSec * 1000),
      isSeen: false,
    );
  }

  // ── Status tracking ────────────────────────────────────────────────────────

  void _updateStatus(RelayStatus status) {
    _isar.writeTxn(() async {
      final relay = await _isar.relayModels
          .where()
          .urlEqualTo(url)
          .findFirst();
      if (relay == null) return;
      relay.status = status;
      if (status == RelayStatus.connected) {
        relay.lastConnectedAt = DateTime.now();
      }
      await _isar.relayModels.put(relay);
    });
    // Flutter UI (Isolate 1) has a watcher on RelayModel — it reacts automatically.
  }
}
