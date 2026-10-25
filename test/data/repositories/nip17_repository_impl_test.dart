import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/dm/encrypted_dm_model.dart';
import 'package:uniun/data/models/note_relation_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/repositories/dm_conversation_repository_impl.dart';
import 'package:uniun/data/repositories/nip17_repository_impl.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/domain/entities/media/media_dim.dart';
import 'package:uniun/domain/repositories/note_relation_repository.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_test_harness.dart';

EncryptedDmModel _wrap(String eventId) => EncryptedDmModel(
      eventId: eventId,
      sig: 'sig',
      authorPubkey: 'ephemeral',
      pTagRef: kSelfPub,
      content: 'ciphertext',
      kind: 1059,
      created: DateTime(2026),
    );

class _Relations extends Mock implements NoteRelationRepository {}

/// Covers: Nip17RepositoryImpl gift-wrap queue reads, the atomic inbound save
/// (conversation, note, unread, reply edge, wrap consumed), duplicate
/// delivery, own-vs-peer unread, and the outgoing save.
void main() {
  late Isar isar;
  late Nip17RepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    repo = Nip17RepositoryImpl(
      isar: isar,
      relations: NoteRelationRepositoryImpl(isar: isar),
      conversations: DmConversationRepositoryImpl(
        isar: isar,
        signer: MeshEventSigner.fixed(
          privkeyHex: kTestPrivHex,
          pubkeyHex: kTestPubHex,
        ),
      ),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Future<int> seedWrap(String eventId) =>
      isar.writeTxn(() => isar.encryptedDmModels.put(_wrap(eventId)));

  group('gift-wrap queue', () {
    test('pendingGiftWraps maps every queued row', () async {
      await seedWrap('w1');
      await seedWrap('w2');

      final wraps = (await repo.pendingGiftWraps()).getOrElse(() => []);

      expect(wraps.map((w) => w.eventId), unorderedEquals(['w1', 'w2']));
      expect(wraps.first.authorPubkey, 'ephemeral');
      expect(wraps.first.content, 'ciphertext');
    });

    test('pendingGiftWraps is empty for an empty queue', () async {
      expect((await repo.pendingGiftWraps()).getOrElse(() => throw 'unreachable'), isEmpty);
    });

    test('watchPendingGiftWraps fires when a wrap is queued', () async {
      final fired = repo.watchPendingGiftWraps().first;
      await seedWrap('w1');
      await fired.timeout(const Duration(seconds: 5));
    });

    test('discardGiftWrap removes only that row; unknown id is a no-op',
        () async {
      final keep = await seedWrap('keep');
      final drop = await seedWrap('drop');

      expect((await repo.discardGiftWrap(drop)).isRight(), isTrue);
      expect((await repo.discardGiftWrap(9999)).isRight(), isTrue);

      final left = await isar.encryptedDmModels.where().findAll();
      expect(left.map((r) => r.id), [keep]);
    });
  });

  group('saveInbound', () {
    test('creates the conversation, stores the note, marks it unread and '
        'consumes the wrap in one go', () async {
      final wrapId = await seedWrap('w1');

      final r = await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0, id: 'dm-1', authorPubkey: kAlicePub),
        ownPubkey: kSelfPub,
      );

      expect(r.isRight(), isTrue);
      final conv = await isar.dmConversationModels.where().findFirst();
      expect(conv!.otherPubkey, kAlicePub);
      final note = await isar.noteModels.where().findFirst();
      expect(note!.eventId, 'dm-1');
      expect(note.kind, kDmTextKind);
      expect(note.conversationId, conv.id);
      expect(await isar.unreadNoteModels.count(), 1);
      expect(await isar.encryptedDmModels.count(), 0);
    });

    test('a reply and a mention each add an edge; the thread root adds none',
        () async {
      final wrapId = await seedWrap('w1');

      await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0, id: 'dm-r', authorPubkey: kAlicePub)
            .copyWith(
          rootEventId: 'root',
          replyToEventId: 'parent',
          eTagRefs: ['root', 'parent', 'mentioned'],
        ),
        ownPubkey: kSelfPub,
      );

      final edges = await isar.noteRelationModels.where().findAll();
      expect(
        edges.map((e) => e.parentId).toSet(),
        {'parent', 'mentioned'},
      );
    });

    test('a message from ourselves is stored read', () async {
      final wrapId = await seedWrap('w1');

      await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0, authorPubkey: kSelfPub),
        ownPubkey: kSelfPub,
      );

      expect(await isar.noteModels.count(), 1);
      expect(await isar.unreadNoteModels.count(), 0);
    });

    test('with no own pubkey every message counts as unread', () async {
      final wrapId = await seedWrap('w1');

      await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0, authorPubkey: kSelfPub),
      );

      expect(await isar.unreadNoteModels.count(), 1);
    });

    test('a reply records its edge to the parent', () async {
      final wrapId = await seedWrap('w1');

      await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0, id: 'child')
            .copyWith(replyToEventId: 'parent', eTagRefs: ['parent']),
        ownPubkey: kSelfPub,
      );

      final edges = await isar.noteRelationModels.where().findAll();
      expect(edges.map((e) => (e.parentId, e.childId)), [('parent', 'child')]);
    });

    test('duplicate delivery keeps one note and one unread row, but still '
        'consumes the second wrap', () async {
      final w1 = await seedWrap('w1');
      final w2 = await seedWrap('w2');
      final msg = aDmText(conversationId: 0, id: 'dm-1');

      await repo.saveInbound(
          giftWrapId: w1, otherPubkey: kAlicePub, message: msg, ownPubkey: kSelfPub);
      await repo.saveInbound(
          giftWrapId: w2, otherPubkey: kAlicePub, message: msg, ownPubkey: kSelfPub);

      expect(await isar.noteModels.count(), 1);
      expect(await isar.unreadNoteModels.count(), 1);
      expect(await isar.encryptedDmModels.count(), 0);
      expect(await isar.dmConversationModels.count(), 1);
    });

    test('attachments, subject, embed and unicode content survive the round '
        'trip', () async {
      final wrapId = await seedWrap('w1');

      await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0, id: 'dm-1', content: 'नमस्ते 🌍 مرحبا')
            .copyWith(
          subject: 'subj',
          embeddedNoteJson: '{"id":"x"}',
          attachments: [
            aMediaBlob(dim: const MediaDim(width: 4, height: 3), filename: 'a.png'),
          ],
        ),
        ownPubkey: kSelfPub,
      );

      final note = (await isar.noteModels.where().findFirst())!;
      expect(note.content, 'नमस्ते 🌍 مرحبا');
      expect(note.subject, 'subj');
      expect(note.embeddedNoteJson, '{"id":"x"}');
      expect(note.hasMedia, isTrue);
      expect(note.attachments.single.width, 4);
      expect(note.attachments.single.filename, 'a.png');
    });

    test('a removed conversation is revived by a new message', () async {
      final wrapId = await seedWrap('w1');
      await isar.writeTxn(() => isar.dmConversationModels.put(
          DmConversationModel()
            ..otherPubkey = kAlicePub
            ..removedAt = DateTime(2026)));

      await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0),
        ownPubkey: kSelfPub,
      );

      final conv = (await isar.dmConversationModels.where().findFirst())!;
      expect(conv.removedAt, isNull);
      expect(await isar.dmConversationModels.count(), 1);
    });

    test('a failure mid-transaction rolls the note, unread row and wrap '
        'consumption back; only the conversation stays', () async {
      final wrapId = await seedWrap('w1');
      final relations = _Relations();
      when(() => relations.addEdgesInTxn(
            parents: any(named: 'parents'),
            childId: any(named: 'childId'),
          )).thenThrow(StateError('edge write failed'));
      final failing = Nip17RepositoryImpl(
        isar: isar,
        relations: relations,
        conversations: DmConversationRepositoryImpl(
          isar: isar,
          signer: MeshEventSigner.fixed(
            privkeyHex: kTestPrivHex,
            pubkeyHex: kTestPubHex,
          ),
        ),
      );

      final r = await failing.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0),
        ownPubkey: kSelfPub,
      );

      expect(r.isLeft(), isTrue);
      expect(await isar.noteModels.count(), 0);
      expect(await isar.unreadNoteModels.count(), 0);
      expect(await isar.encryptedDmModels.count(), 1);
      expect(await isar.dmConversationModels.count(), 1);
    });

    test('a failing conversation step is returned and writes no note',
        () async {
      final wrapId = await seedWrap('w1');
      await isar.close();

      final r = await repo.saveInbound(
        giftWrapId: wrapId,
        otherPubkey: kAlicePub,
        message: aDmText(conversationId: 0),
        ownPubkey: kSelfPub,
      );

      expect(r.isLeft(), isTrue);
      isar = await openTestIsar();
      expect(await isar.noteModels.count(), 0);
    });
  });

  group('saveOutgoing', () {
    test('stores the note unread-free with its attachments and reply edge',
        () async {
      final r = await repo.saveOutgoing(
        aDmText(conversationId: 7, id: 'out-1', authorPubkey: kSelfPub)
            .copyWith(
          replyToEventId: 'parent',
          eTagRefs: ['parent'],
          attachments: [aMediaBlob()],
        ),
      );

      expect(r.isRight(), isTrue);
      final note = (await isar.noteModels.where().findFirst())!;
      expect(note.eventId, 'out-1');
      expect(note.conversationId, 7);
      expect(note.attachments, hasLength(1));
      expect(await isar.unreadNoteModels.count(), 0);
      expect(await isar.noteRelationModels.count(), 1);
    });

    test('a mention adds an edge next to the reply edge', () async {
      await repo.saveOutgoing(
        aDmText(conversationId: 7, id: 'out-2', authorPubkey: kSelfPub)
            .copyWith(
          replyToEventId: 'parent',
          eTagRefs: ['parent', 'mentioned'],
        ),
      );

      final edges = await isar.noteRelationModels.where().findAll();
      expect(edges.map((e) => e.parentId).toSet(), {'parent', 'mentioned'});
    });

    test('sending the same id twice is refused and keeps the first row',
        () async {
      await repo.saveOutgoing(aDmText(conversationId: 7, id: 'out-1', content: 'v1'));
      final again = await repo.saveOutgoing(
          aDmText(conversationId: 7, id: 'out-1', content: 'v2'));

      expect(again.isLeft(), isTrue);
      final notes = await isar.noteModels.where().findAll();
      expect(notes.single.content, 'v1');
    });

    test('a closed database surfaces as Left', () async {
      await isar.close();

      final r = await repo.saveOutgoing(aDmText(conversationId: 7));

      expect(r.isLeft(), isTrue);
      isar = await openTestIsar();
    });
  });

  test('a closed database fails every queue call with Left', () async {
    await isar.close();

    expect((await repo.pendingGiftWraps()).isLeft(), isTrue);
    expect((await repo.discardGiftWrap(1)).isLeft(), isTrue);
    isar = await openTestIsar();
  });
}
