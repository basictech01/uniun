import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/notes/reply_edge.dart';
import 'package:uniun/data/models/dm/encrypted_dm_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/domain/entities/dm/encrypted_dm_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/dm_conversation_repository.dart';
import 'package:uniun/domain/repositories/nip17_repository.dart';
import 'package:uniun/domain/repositories/note_relation_repository.dart';

@Injectable(as: Nip17Repository)
class Nip17RepositoryImpl extends Nip17Repository {
  final Isar isar;
  final NoteRelationRepository _relations;
  final DmConversationRepository _conversations;

  Nip17RepositoryImpl({
    required this.isar,
    required NoteRelationRepository relations,
    required DmConversationRepository conversations,
  })  : _relations = relations,
        _conversations = conversations;

  @override
  Stream<void> watchPendingGiftWraps() => isar.encryptedDmModels.watchLazy();

  @override
  Future<Either<Failure, List<EncryptedDmEntity>>> pendingGiftWraps() async {
    try {
      final rows = await isar.encryptedDmModels.where().findAll();
      return Right([
        for (final r in rows)
          EncryptedDmEntity(
            id: r.id,
            eventId: r.eventId,
            authorPubkey: r.authorPubkey,
            content: r.content,
          ),
      ]);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> discardGiftWrap(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.encryptedDmModels.delete(id);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveInbound({
    required int giftWrapId,
    required String otherPubkey,
    required NoteEntity message,
    String? ownPubkey,
  }) async {
    try {
      // The conversation is written before the note transaction: signing it
      // is async and cannot run inside `writeTxn`.
      final conv = await _conversations.ensureActive(otherPubkey);
      final conversationId = conv.fold<int?>((_) => null, (c) => c.id);
      if (conversationId == null) {
        return conv.map((_) => unit);
      }
      final model = message.toModel(conversationId: conversationId);

      await isar.writeTxn(() async {
        final existing = await isar.noteModels
            .where()
            .eventIdEqualTo(model.eventId)
            .findFirst();
        if (existing != null) {
          await isar.encryptedDmModels.delete(giftWrapId);
          return;
        }

        await isar.noteModels.put(model);
        if (model.authorPubkey != ownPubkey) {
          await putUnreadRowInTxn(isar, model);
        }
        final parents = replyEdgeParentIds(
          replyToEventId: model.replyToEventId,
          rootEventId: model.rootEventId,
          eTagRefs: model.eTagRefs,
        );
        await _relations.addEdgesInTxn(
          parents: parents,
          childId: model.eventId,
        );
        await isar.encryptedDmModels.delete(giftWrapId);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveOutgoing(NoteEntity message) async {
    try {
      final model = message.toModel();
      await isar.writeTxn(() async {
        await isar.noteModels.put(model);
        final parents = replyEdgeParentIds(
          replyToEventId: model.replyToEventId,
          rootEventId: model.rootEventId,
          eTagRefs: model.eTagRefs,
        );
        await _relations.addEdgesInTxn(
          parents: parents,
          childId: model.eventId,
        );
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
