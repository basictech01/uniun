import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/repositories/dm_message_repository_impl.dart';
import 'package:uniun/data/repositories/note_attachments_enricher.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/data/repositories/note_resolver_repository_impl.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: DmMessageRepositoryImpl saveMessage (unified Note collection,
/// idempotency), getMessages (conversation scoping, exclusive before cursor,
/// limit, newest-first), getMessageById.
void main() {
  late Isar isar;
  late DmMessageRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    final relations = NoteRelationRepositoryImpl(isar: isar);
    repo = DmMessageRepositoryImpl(
      isar: isar,
      resolver: NoteResolverRepositoryImpl(
        isar: isar,
        relations: relations,
        attachments: NoteAttachmentsEnricher(isar: isar),
      ),
      relations: relations,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  List<String> idsOf(dynamic either) =>
      (either.getOrElse(() => const <NoteEntity>[]) as List<NoteEntity>)
          .map((n) => n.id)
          .toList();

  group('saveMessage', () {
    test('persists a kind-14 rumor into the unified Note collection',
        () async {
      final r = await repo.saveMessage(aDmText(
        conversationId: 7,
        id: 'dm-1',
        content: 'hi',
        recipient: kBobPub,
      ));
      expect(r.isRight(), isTrue);

      final row = (await isar.noteModels.where().findAll()).single;
      expect(row.eventId, 'dm-1');
      expect(row.kind, kDmTextKind);
      expect(row.conversationId, 7);
      expect(row.pTagRefs, [kBobPub]);
      expect(row.content, 'hi');
      // DMs live in the same collection as feed notes, discriminated by kind.
      expect(row.groupId, isNull);
      expect(row.privateGroupId, isNull);
    });

    test('idempotent: re-save of the same eventId returns the stored row '
        'unchanged', () async {
      await repo.saveMessage(
          aDmText(conversationId: 7, id: 'dm-1', content: 'original'));
      final second = await repo.saveMessage(
          aDmText(conversationId: 7, id: 'dm-1', content: 'changed'));

      expect(second.getOrElse(() => throw 'unreachable').content, 'original');
      expect(await isar.noteModels.count(), 1);
    });

    test('kind-15 file message round-trips', () async {
      final r = await repo.saveMessage(aNote(
        id: 'dm-file',
        kind: kDmFileKind,
        conversationId: 3,
        content: 'https://blossom/x',
      ));
      expect(r.getOrElse(() => throw 'unreachable').kind, kDmFileKind);
    });

    test('unicode + emoji + RTL content persists verbatim', () async {
      const payload = '${Content.unicode} ${Content.emoji} ${Content.rtl}';
      await repo.saveMessage(
          aDmText(conversationId: 1, id: 'dm-u', content: payload));
      final row = (await isar.noteModels.where().findAll()).single;
      expect(row.content, payload);
    });
  });

  group('getMessages', () {
    Future<void> seedConversation(int conversationId, int n) async {
      for (var i = 0; i < n; i++) {
        await seedNoteRow(isar, 'c$conversationId-m$i',
            kind: kDmTextKind,
            conversationId: conversationId,
            created: tNow.subtract(Duration(minutes: i)));
      }
    }

    test('returns only the requested conversation, newest-first', () async {
      await seedConversation(1, 3);
      await seedConversation(2, 2);

      final r = await repo.getMessages(1);
      expect(idsOf(r), ['c1-m0', 'c1-m1', 'c1-m2']);
    });

    test('before cursor is EXCLUSIVE (unlike the feed cursor)', () async {
      await seedConversation(1, 5);
      final r = await repo.getMessages(1,
          before: tNow.subtract(const Duration(minutes: 2)));
      // The message AT the cursor timestamp (m2) is excluded.
      expect(idsOf(r), ['c1-m3', 'c1-m4']);
    });

    test('limit truncates after cursor filtering', () async {
      await seedConversation(1, 10);
      final r = await repo.getMessages(1, limit: 4);
      expect(idsOf(r), ['c1-m0', 'c1-m1', 'c1-m2', 'c1-m3']);
    });

    test('unknown conversation → Right(empty)', () async {
      final r = await repo.getMessages(999);
      expect(r.isRight(), isTrue);
      expect(idsOf(r), isEmpty);
    });

    test('carries the live reply and reference counts (issue #304)', () async {
      await seedNoteRow(isar, 'parent', kind: kDmTextKind, conversationId: 1);
      await seedNoteRow(isar, 'child', kind: kDmTextKind, conversationId: 1);
      await seedNoteRow(isar, 'ref', kind: kDmTextKind, conversationId: 1);
      final relations = NoteRelationRepositoryImpl(isar: isar);
      await isar.writeTxn(() async {
        await relations.addEdgesInTxn(parents: {'parent'}, childId: 'child');
        await relations.addEdgesInTxn(
          parents: {'parent', 'child'},
          childId: 'ref',
        );
      });

      final notes = (await repo.getMessages(1)).getOrElse(() => const []);
      final byId = {for (final n in notes) n.id: n};

      expect(byId['parent']!.cachedReplyCount, 2);
      expect(byId['child']!.cachedReplyCount, 1);
      expect(byId['child']!.referenceCount, 1);
      expect(byId['ref']!.referenceCount, 2);
      expect(byId['parent']!.referenceCount, 0);
    });

    test('kind-1 feed notes (null conversationId) never leak in', () async {
      await seedNoteRow(isar, 'feed-note');
      await seedConversation(1, 1);
      final r = await repo.getMessages(1);
      expect(idsOf(r), ['c1-m0']);
    });
  });

  group('getMessageById', () {
    test('resolves a stored message', () async {
      await seedNoteRow(isar, 'dm-x', kind: kDmTextKind, conversationId: 5);
      final r = await repo.getMessageById('dm-x');
      expect(r.getOrElse(() => throw 'unreachable').id, 'dm-x');
    });

    test('carries the live reply count', () async {
      await seedNoteRow(isar, 'dm-p', kind: kDmTextKind, conversationId: 5);
      await seedNoteRow(isar, 'dm-c', kind: kDmTextKind, conversationId: 5);
      await isar.writeTxn(
        () => NoteRelationRepositoryImpl(isar: isar)
            .addEdgesInTxn(parents: {'dm-p'}, childId: 'dm-c'),
      );

      final n = (await repo.getMessageById('dm-p')).getOrElse(() => throw 'x');
      expect(n.cachedReplyCount, 1);
    });

    test('unknown eventId → Left(notFoundFailure)', () async {
      final r = await repo.getMessageById('ghost');
      expect(r.isLeft(), isTrue);
    });
  });
}
