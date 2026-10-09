import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/models/encrypted_message_model.dart';
import 'package:uniun/data/models/private_group_model.dart';
import 'package:uniun/domain/repositories/note_relation_repository.dart';
import 'package:uniun/domain/services/marmot_mls_service.dart';
import 'package:uniun/domain/services/marmot_transport_service.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

import '../../_helpers/isar_test_harness.dart';

class _Mls extends Mock implements MarmotMlsService {}

class _Relations extends Mock implements NoteRelationRepository {}

class _Signer extends Mock implements MeshEventSigner {}

/// Logout waits for active Marmot message processing before clearing Isar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  setUp(() async => isar = await openTestIsar());
  tearDown(() async => isar.close(deleteFromDisk: true));

  test(
    'stop waits for an in-flight protocol message and is idempotent',
    () async {
      final mls = _Mls();
      final entered = Completer<void>();
      final release = Completer<void>();
      when(
        () => mls.processProtocolMessage(
          groupId: 'mls_g',
          base64Payload: 'encrypted',
          groupIdIsBase64: true,
        ),
      ).thenAnswer((_) async {
        entered.complete();
        await release.future;
      });
      await isar.writeTxn(() async {
        await isar.privateGroupModels.put(privateGroupSeed('g'));
        await isar.encryptedMessageModels.put(
          EncryptedMessageModel()
            ..eventId = 'event'
            ..groupId = 'g'
            ..senderPubkey = 'sender'
            ..kind = 9025
            ..encryptedPayload = 'encrypted'
            ..timestamp = DateTime(2026),
        );
      });

      final transport = MarmotTransportService(
        isar,
        mls,
        _Relations(),
        _Signer(),
      );
      transport.start();
      transport.start();
      await entered.future.timeout(const Duration(seconds: 5));
      await isar.writeTxn(
        () => isar.encryptedMessageModels.put(
          EncryptedMessageModel()
            ..eventId = 'queued-after-start'
            ..groupId = 'g'
            ..senderPubkey = 'sender'
            ..kind = 9025
            ..encryptedPayload = 'encrypted-second'
            ..timestamp = DateTime(2026),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      var stopped = false;
      final stopping = transport.stop().then((_) => stopped = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(stopped, isFalse);

      release.complete();
      await stopping;
      await transport.stop();
      expect(
        await isar.encryptedMessageModels.count(),
        1,
        reason: 'stop must not start processing another queued message',
      );
      verify(
        () => mls.processProtocolMessage(
          groupId: 'mls_g',
          base64Payload: 'encrypted',
          groupIdIsBase64: true,
        ),
      ).called(1);
    },
  );
}
