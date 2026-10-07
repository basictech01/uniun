import 'package:isar_community/isar.dart';

part 'pending_embedding_model.g.dart';

/// A note that has been saved or published but has no vector yet.
///
/// One row is written when the note becomes embeddable and deleted only after
/// its vector is stored, so a crash, a kill or a failed embed leaves the row
/// behind for the next pass. An empty table means every note is embedded —
/// that is what lets the worker do nothing in the steady state.
///
/// [text] is the text to embed (media URLs already stripped), kept on the row
/// so the worker needs no lookup in either note table.
@Collection(ignore: {'copyWith'})
@Name('PendingEmbedding')
class PendingEmbeddingModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String eventId;

  late String text;

  @Index()
  late DateTime createdAt;

  /// Failed embed attempts so far. A row that keeps throwing is dropped after
  /// a few so one bad note cannot hold up the rest.
  int attempts = 0;
}
