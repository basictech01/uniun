import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/dm_message_repository.dart';
import 'package:uniun/domain/repositories/note_relation_repository.dart';
import 'package:uniun/domain/repositories/note_resolver_repository.dart';

@Injectable(as: DmMessageRepository)
class DmMessageRepositoryImpl extends DmMessageRepository {
  final Isar isar;
  final NoteResolverRepository _resolver;
  final NoteRelationRepository _relations;
  DmMessageRepositoryImpl({
    required this.isar,
    required NoteResolverRepository resolver,
    required NoteRelationRepository relations,
  })  : _resolver = resolver,
        _relations = relations;

  /// Attaches the live reply + reference counts from the edge table.
  Future<List<NoteEntity>> _withCounts(List<NoteEntity> notes) async => [
        for (final n in notes)
          n.copyWith(
            cachedReplyCount: await _relations.replyCount(n.id),
            referenceCount: await _relations.referenceCount(n.id),
          ),
      ];

  @override
  Future<Either<Failure, NoteEntity>> saveMessage(NoteEntity entity) async {
    try {
      final existing = await isar.noteModels
          .where()
          .eventIdEqualTo(entity.id)
          .findFirst();
      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = NoteModel(
        eventId: entity.id,
        sig: entity.sig,
        authorPubkey: entity.authorPubkey,
        conversationId: entity.conversationId,
        pTagRefs: List<String>.from(entity.pTagRefs),
        eTagRefs: List<String>.from(entity.eTagRefs),
        content: entity.content,
        subject: entity.subject,
        replyToEventId: entity.replyToEventId,
        rootEventId: entity.rootEventId,
        kind: entity.kind,
        type: entity.type,
        tTags: const [],
        created: entity.created,
        embeddedNoteJson: entity.embeddedNoteJson,
      );

      await isar.writeTxn(() async {
        await isar.noteModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getMessages(
    int conversationId, {
    DateTime? before,
    int limit = 30,
  }) async {
    try {
      final rows = await isar.noteModels
          .filter()
          .conversationIdEqualTo(conversationId)
          .findAll();

      rows.sort((a, b) => b.created.compareTo(a.created));
      final filtered = before == null
          ? rows
          : rows.where((m) => m.created.isBefore(before)).toList();

      final entities = filtered.take(limit).map((m) => m.toDomain()).toList();
      return Right(await _resolver.enrichWithQuotes(await _withCounts(entities)));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getMessageById(String eventId) async {
    try {
      final row = await isar.noteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (row == null) {
        return Left(
          Failure.notFoundFailure('DM message not found for eventId: $eventId'),
        );
      }
      final enriched = await _resolver.enrichWithQuotes(
        await _withCounts([row.toDomain()]),
      );
      return Right(enriched.first);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
