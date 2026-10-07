import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/pending_embedding_model.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';

@Injectable(as: PendingEmbeddingRepository)
class PendingEmbeddingRepositoryImpl extends PendingEmbeddingRepository {
  final Isar isar;
  PendingEmbeddingRepositoryImpl({required this.isar});

  @override
  Future<void> enqueue(String eventId, String text) async {
    await isar.writeTxn(() async {
      await isar.pendingEmbeddingModels.put(
        PendingEmbeddingModel()
          ..eventId = eventId
          ..text = text
          ..createdAt = DateTime.now(),
      );
    });
  }

  @override
  Future<PendingEmbeddingItem?> next() async {
    final row =
        await isar.pendingEmbeddingModels.where().sortByCreatedAtDesc().findFirst();
    return row == null
        ? null
        : PendingEmbeddingItem(eventId: row.eventId, text: row.text);
  }

  @override
  Future<void> remove(String eventId) async {
    await isar.writeTxn(() async {
      await isar.pendingEmbeddingModels
          .filter()
          .eventIdEqualTo(eventId)
          .deleteAll();
    });
  }

  @override
  Future<int> recordFailure(String eventId) {
    return isar.writeTxn(() async {
      final row = await isar.pendingEmbeddingModels
          .filter()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (row == null) return 0;
      row.attempts++;
      await isar.pendingEmbeddingModels.put(row);
      return row.attempts;
    });
  }

  @override
  Future<int> count() => isar.pendingEmbeddingModels.count();
}
