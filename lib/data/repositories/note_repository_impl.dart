import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@Injectable(as: NoteRepository)
class NoteRepositoryImpl extends NoteRepository {
  final Isar isar;

  NoteRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, List<NoteEntity>>> getFeed({
    required int limit,
    DateTime? before,
  }) async {
    try {
      // Only top-level notes (rootEventId == null) appear in the feed.
      // Replies live inside thread views — never in the main feed.
      final query = isar.noteModels
          .filter()
          .rootEventIdIsNull();

      final notes = await (before != null
              ? query.createdLessThan(before)
              : query)
          .sortByCreatedDesc()
          .limit(limit)
          .findAll();

      return Right(notes.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(String eventId) async {
    try {
      final note = await isar.noteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (note == null) {
        return const Left(Failure.errorFailure('Note not found'));
      }
      return Right(note.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getReplies(String eventId) async {
    try {
      // Direct replies only — notes where this event is the immediate parent.
      // Using replyToEventId (indexed) is precise; eTagRefs would also match
      // mentions which are not replies.
      final replies = await isar.noteModels
          .filter()
          .replyToEventIdEqualTo(eventId)
          .sortByCreated()
          .findAll();
      return Right(replies.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getThread(
      String rootEventId) async {
    try {
      // Root note
      final root = await isar.noteModels
          .where()
          .eventIdEqualTo(rootEventId)
          .findFirst();

      // All notes in the thread (rootEventId == rootEventId), chronological
      final replies = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(rootEventId)
          .sortByCreated()
          .findAll();

      final all = [
        if (root != null) root,
        ...replies,
      ];

      return Right(all.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> saveNote(NoteEntity note) async {
    try {
      final existing = await isar.noteModels
          .where()
          .eventIdEqualTo(note.id)
          .findFirst();

      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = NoteModel(
        eventId: note.id,
        sig: note.sig,
        authorPubkey: note.authorPubkey,
        content: note.content,
        type: note.type,
        eTagRefs: note.eTagRefs,
        rootEventId: note.rootEventId,
        replyToEventId: note.replyToEventId,
        pTagRefs: note.pTagRefs,
        tTags: note.tTags,
        created: note.created,
        isSeen: note.isSeen,
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
  Future<Either<Failure, int>> getReplyCount(String eventId) async {
    try {
      final count = await isar.noteModels
          .filter()
          .replyToEventIdEqualTo(eventId)
          .count();
      return Right(count);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getThreadReplyCount(String rootEventId) async {
    try {
      final count = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(rootEventId)
          .count();
      return Right(count);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsSeen(String eventId) async {
    try {
      await isar.writeTxn(() async {
        final note = await isar.noteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (note != null) {
          note.isSeen = true;
          await isar.noteModels.put(note);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

}
