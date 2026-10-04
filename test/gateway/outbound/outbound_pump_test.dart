import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/gateway/outbound/outbound_pump.dart';
import 'package:uniun/gateway/session/relay_session.dart';
import 'package:uniun/gateway/transport/relay_connection.dart';

import '../../_helpers/isar_test_harness.dart';

/// Covers: rejected relay OKs release the in-flight slot and advance the queue,
/// and an accepted OK persisting the row's sentCount.
/// Polls [done] until it holds, failing after [timeout] — a condition to wait
/// for, instead of a fixed sleep that races the work it waits on.
Future<void> _until(
  FutureOr<bool> Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await done()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _CapturingConnection extends RelayConnection {
  _CapturingConnection() : super(url: 'wss://test.relay');

  final List<String> sent = [];
  final _frames = StreamController<String>.broadcast();
  final _states = StreamController<ConnectionState>.broadcast();

  @override
  bool get isConnected => true;

  @override
  Stream<String> get frames => _frames.stream;

  @override
  Stream<ConnectionState> get states => _states.stream;

  @override
  void send(String frame) => sent.add(frame);

  void ok(String eventId, bool accepted) {
    _frames.add(jsonEncode(['OK', eventId, accepted]));
  }

  @override
  Future<void> disconnect() async {
    await _frames.close();
    await _states.close();
  }
}

void main() {
  late Isar isar;

  setUp(() async {
    isar = await openTestIsar();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('rejected OK advances to the next queued event', () async {
    final first = _queueRow('evt-1', 1);
    final second = _queueRow('evt-2', 2);
    await isar.writeTxn(() async {
      await isar.eventQueueModels.putAll([first, second]);
    });

    final connection = _CapturingConnection();
    final session = RelaySession(
      connection: connection,
      read: true,
      write: true,
    );
    final pump = OutboundPump(
      isar: isar,
      session: session,
      startFromQueueId: 0,
      shouldSendToThisSession: (_) async => true,
    );

    pump.onTick();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(connection.sent, hasLength(1));
    expect(connection.sent.single, contains('evt-1'));

    connection.ok('evt-1', false);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connection.sent, hasLength(2));
    expect(connection.sent.last, contains('evt-2'));

    final rows = await isar.eventQueueModels.where().findAll();
    expect(rows.map((row) => row.sentCount), [0, 0]);

    await pump.dispose();
    await session.disconnect();
  });

  test('an item the router rejects (shouldSendToThisSession=false) is '
      'skipped without sending, advancing straight to the next item',
      () async {
    final skip = _queueRow('evt-skip', 1);
    final send = _queueRow('evt-send', 2);
    await isar.writeTxn(() async {
      await isar.eventQueueModels.putAll([skip, send]);
    });

    final connection = _CapturingConnection();
    final session = RelaySession(connection: connection, read: true, write: true);
    final pump = OutboundPump(
      isar: isar,
      session: session,
      startFromQueueId: 0,
      shouldSendToThisSession: (event) async => event.eventId != 'evt-skip',
    );

    pump.onTick();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connection.sent, hasLength(1));
    expect(connection.sent.single, contains('evt-send'));

    await pump.dispose();
    await session.disconnect();
  });

  test('an accepted OK increments the queue row\'s sentCount', () async {
    final row = _queueRow('evt-1', 1);
    await isar.writeTxn(() async {
      await isar.eventQueueModels.put(row);
    });

    final connection = _CapturingConnection();
    final session = RelaySession(connection: connection, read: true, write: true);
    final pump = OutboundPump(
      isar: isar,
      session: session,
      startFromQueueId: 0,
      shouldSendToThisSession: (_) async => true,
    );

    pump.onTick();
    // The OK is only counted once the event is in flight. A fixed sleep here
    // lost that race on a slow CI runner (the OK arrived before the send and
    // was ignored), so wait for the send itself.
    await _until(() => connection.sent.isNotEmpty);

    connection.ok('evt-1', true);
    await _until(() async {
      final row = await isar.eventQueueModels
          .where()
          .eventIdEqualTo('evt-1')
          .findFirst();
      return row?.sentCount == 1;
    });

    final updated = await isar.eventQueueModels
        .where()
        .eventIdEqualTo('evt-1')
        .findFirst();
    expect(updated!.sentCount, 1);

    await pump.dispose();
    await session.disconnect();
  });

  test('an OK for an eventId with no pending slot (not ours) is ignored',
      () async {
    final connection = _CapturingConnection();
    final session = RelaySession(connection: connection, read: true, write: true);
    final pump = OutboundPump(
      isar: isar,
      session: session,
      startFromQueueId: 0,
      shouldSendToThisSession: (_) async => true,
    );

    // No item ever armed — an unsolicited OK must not throw or advance.
    connection.ok('not-ours', true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connection.sent, isEmpty);

    await pump.dispose();
    await session.disconnect();
  });
}

EventQueueModel _queueRow(String eventId, int seconds) {
  return EventQueueModel()
    ..eventId = eventId
    ..authorPubkey = 'pubkey'
    ..sig = 'sig'
    ..content = 'content'
    ..kind = 1
    ..eTagRefs = const []
    ..pTagRefs = const []
    ..tTags = const []
    ..created = DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
    ..sentCount = 0
    ..enqueuedAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
