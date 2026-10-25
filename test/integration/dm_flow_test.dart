import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/datasources/feed_read_state_store.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/repositories/dm_conversation_repository_impl.dart';
import 'package:uniun/data/repositories/dm_message_repository_impl.dart';
import 'package:uniun/data/repositories/feed_repository_impl.dart';
import 'package:uniun/data/repositories/nip17_repository_impl.dart';
import 'package:uniun/data/repositories/note_attachments_enricher.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/data/repositories/note_resolver_repository_impl.dart';
import 'package:uniun/data/repositories/source_label_repository_impl.dart';
import 'package:uniun/data/repositories/unread_repository_impl.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

import '../_helpers/fixtures.dart';
import '../_helpers/isar_seeds.dart';
import '../_helpers/isar_test_harness.dart';
import '../_helpers/stub_followed_users.dart';
import '../_helpers/stub_user_repository.dart';

/// End-to-end DM scenarios — from "user scans a QR / pastes an npub" through
/// conversation creation, message exchange, unread tracking, chat pagination,
/// and the privacy invariant that DM content NEVER surfaces in the feed.
/// Real Isar + real conversation/message/unread/feed repositories; only
/// identity and the follow list are stubbed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late DmConversationRepositoryImpl conversations;
  late DmMessageRepositoryImpl messages;
  late Nip17RepositoryImpl nip17;
  late UnreadRepositoryImpl unread;
  late FeedRepositoryImpl feed;

  setUp(() async {
    isar = await openTestIsar();
    SharedPreferences.setMockInitialValues({});
    final relations = NoteRelationRepositoryImpl(isar: isar);
    final resolver = NoteResolverRepositoryImpl(
      isar: isar,
      relations: relations,
      attachments: NoteAttachmentsEnricher(isar: isar),
    );
    conversations = DmConversationRepositoryImpl(
      isar: isar,
      signer: MeshEventSigner(StubUserRepository()..keys = null),
    );
    messages = DmMessageRepositoryImpl(
      isar: isar,
      resolver: resolver,
      relations: relations,
    );
    nip17 = Nip17RepositoryImpl(
      isar: isar,
      relations: relations,
      conversations: conversations,
    );
    unread = UnreadRepositoryImpl(isar: isar);
    feed = FeedRepositoryImpl(
      isar: isar,
      relations: relations,
      sourceLabels: SourceLabelRepositoryImpl(isar: isar),
      follows: StubFollowedUsers()..pubkeys = [kAlicePub],
      users: StubUserRepository()
        ..keys = (privkeyHex: kTestPrivHex, pubkeyHex: kSelfPub),
      feedReadState: FeedReadStateStore(await SharedPreferences.getInstance()),
      resolver: resolver,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  List<String> idsOf(dynamic either) =>
      (either.getOrElse(() => const <NoteEntity>[]) as List<NoteEntity>)
          .map((n) => n.id)
          .toList();

  test(
      'SCENARIO: full conversation lifecycle — npub paste → get-or-create → '
      'messages exchanged → unread badge → open chat clears it', () async {
    // 1. User pastes the peer's npub; a conversation is created.
    final npub = Nip19.encodePubkey(kSampleTargetPubkeyHex);
    final created =
        await conversations.saveConversation(aDmConversation(
      otherPubkey: npub,
      relays: ['wss://relay.example'],
    ));
    final convo = created.getOrElse(() => throw 'unreachable');
    expect(convo.otherPubkey, kSampleTargetPubkeyHex);

    // 2. Scanning the same npub later resolves the SAME conversation.
    final again = await conversations
        .getConversationByOtherPubkey(kSampleTargetPubkeyHex.toUpperCase());
    expect(again.getOrElse(() => throw 'unreachable').id, convo.id);

    // 3. Messages flow in both directions.
    await messages.saveMessage(aDmText(
        conversationId: convo.id,
        id: 'dm-in',
        content: 'hey!',
        authorPubkey: kSampleTargetPubkeyHex,
        recipient: kSelfPub));
    await messages.saveMessage(aDmText(
        conversationId: convo.id,
        id: 'dm-out',
        content: 'hi back',
        authorPubkey: kSelfPub,
        recipient: kSampleTargetPubkeyHex));
    // Inbound message also lands an unread projection (Gateway behavior).
    await seedUnreadRow(isar, 'dm-in',
        kind: kDmTextKind,
        authorPubkey: kSampleTargetPubkeyHex,
        conversationId: convo.id);

    // 4. Drawer badge sees one unread row for this conversation.
    expect(await isar.unreadNoteModels.count(), 1);

    // 5. Opening the chat lists both messages and clears the badge.
    final chat = await messages.getMessages(convo.id);
    expect(idsOf(chat).toSet(), {'dm-in', 'dm-out'});
    expect((await unread.markConversationSeen(convo.id)).isRight(), isTrue);
    expect(await isar.unreadNoteModels.count(), 0);
  });

  test(
      'SCENARIO: privacy invariant — DM rows share the Note collection with '
      'the feed but NEVER surface in either feed bucket', () async {
    final convo = (await conversations.saveConversation(aDmConversation()))
        .getOrElse(() => throw 'unreachable');
    await messages.saveMessage(aDmText(
        conversationId: convo.id, id: 'secret-dm', content: 'private!'));
    await seedUnreadRow(isar, 'secret-dm',
        kind: kDmTextKind, conversationId: convo.id);
    // A normal feed note for contrast.
    await seedNoteRow(isar, 'public-note');
    await seedUnreadRow(isar, 'public-note');

    expect(idsOf(await feed.getUnread(limit: 10, excludeIds: {})),
        ['public-note']);
    await unread.markSeen('public-note');
    await unread.markConversationSeen(convo.id);
    expect(idsOf(await feed.getSeen(limit: 10)), ['public-note']);

    // The DM is still there — just invisible to the feed.
    expect((await messages.getMessageById('secret-dm')).isRight(), isTrue);
  });

  test(
      'SCENARIO: long chat history pages backwards seamlessly — 45 messages '
      'read in three exclusive-cursor pages', () async {
    final convo = (await conversations.saveConversation(aDmConversation()))
        .getOrElse(() => throw 'unreachable');
    for (var i = 0; i < 45; i++) {
      await messages.saveMessage(aDmText(
        conversationId: convo.id,
        id: 'm-$i',
        content: 'msg $i',
        authorPubkey: i.isEven ? kSelfPub : kSampleTargetPubkeyHex,
      ).copyWith(created: tNow.subtract(Duration(minutes: i))));
    }

    final all = <String>[];
    DateTime? cursor;
    while (true) {
      final page =
          await messages.getMessages(convo.id, before: cursor, limit: 20);
      final entities = page.getOrElse(() => const <NoteEntity>[]);
      if (entities.isEmpty) break;
      all.addAll(entities.map((e) => e.id));
      cursor = entities.last.created;
    }
    expect(all, hasLength(45));
    expect(all.toSet(), hasLength(45)); // no duplicates across pages
    expect(all.first, 'm-0'); // newest first
    expect(all.last, 'm-44'); // oldest last
  });

  test(
      'SCENARIO: mixed text + file messages — kind 15 attachment message '
      'lives in the same thread', () async {
    final convo = (await conversations.saveConversation(aDmConversation()))
        .getOrElse(() => throw 'unreachable');
    await messages.saveMessage(aDmText(
        conversationId: convo.id, id: 'text-msg', content: 'look at this'));
    await messages.saveMessage(aNote(
      id: 'file-msg',
      kind: kDmFileKind,
      conversationId: convo.id,
      content: 'https://blossom.example/sha256',
      created: tNow.add(const Duration(seconds: 1)),
    ));

    final chat = await messages.getMessages(convo.id);
    final entities = chat.getOrElse(() => const <NoteEntity>[]);
    expect(entities.map((e) => e.id).toList(), ['file-msg', 'text-msg']);
    expect(entities.first.kind, kDmFileKind);
  });

  test(
      'SCENARIO: relay redelivery of the same gift wrap is idempotent — '
      'no duplicate bubbles', () async {
    final convo = (await conversations.saveConversation(aDmConversation()))
        .getOrElse(() => throw 'unreachable');
    final msg = aDmText(conversationId: convo.id, id: 'dm-1', content: 'v1');
    await messages.saveMessage(msg);
    await messages.saveMessage(msg); // redelivery
    await messages
        .saveMessage(msg.copyWith(content: 'tampered')); // same id, new body

    final chat = await messages.getMessages(convo.id);
    final entities = chat.getOrElse(() => const <NoteEntity>[]);
    expect(entities, hasLength(1));
    expect(entities.single.content, 'v1'); // first write wins
  });

  test(
      'SCENARIO: deleting a conversation removes the drawer entry but chat '
      'history rows are untouched (notes are forever)', () async {
    final convo = (await conversations.saveConversation(aDmConversation()))
        .getOrElse(() => throw 'unreachable');
    await messages.saveMessage(
        aDmText(conversationId: convo.id, id: 'dm-1', content: 'hello'));

    await conversations.deleteConversation(kSampleTargetPubkeyHex);
    expect(
        (await conversations.getConversations()).getOrElse(() => const []),
        isEmpty);
    // The message row survives in the unified Note collection.
    expect((await messages.getMessageById('dm-1')).isRight(), isTrue);
  });

  test(
      'SCENARIO: a reply and a reference sent or received in a DM show up in '
      'the chat counts (issue #304)', () async {
    // The peer's first message arrives, then both sides reply to it.
    await nip17.saveInbound(
      giftWrapId: 0,
      otherPubkey: kSampleTargetPubkeyHex,
      message: aDmText(
        conversationId: 0,
        id: 'dm-parent',
        authorPubkey: kSampleTargetPubkeyHex,
      ),
      ownPubkey: kSelfPub,
    );
    final convoId = (await conversations
            .getConversationByOtherPubkey(kSampleTargetPubkeyHex))
        .getOrElse(() => throw 'unreachable')
        .id;
    await nip17.saveOutgoing(
      aDmText(conversationId: convoId, id: 'dm-reply', authorPubkey: kSelfPub)
          .copyWith(replyToEventId: 'dm-parent', eTagRefs: ['dm-parent']),
    );
    await nip17.saveOutgoing(
      aDmText(conversationId: convoId, id: 'dm-ref', authorPubkey: kSelfPub)
          .copyWith(eTagRefs: ['dm-parent']),
    );

    final chat = (await messages.getMessages(convoId))
        .getOrElse(() => throw 'unreachable');
    final byId = {for (final n in chat) n.id: n};

    expect(byId['dm-parent']!.cachedReplyCount, 2);
    expect(byId['dm-reply']!.referenceCount, 1);
    expect(byId['dm-ref']!.referenceCount, 1);
  });
}
