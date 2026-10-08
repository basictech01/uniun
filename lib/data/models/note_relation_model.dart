import 'package:isar_community/isar.dart';

part 'note_relation_model.g.dart';

/// A directed reference edge between two events, keyed by Nostr event ID.
///
/// One row per (referenced note → referencing note). Kind-agnostic: works for
/// Kind 1 notes and Kind 42 group messages alike, since event IDs are
/// globally unique. Reply/reference count of a note X = number of rows where
/// [parentId] == X. The unique (parentId, childId) index makes edge inserts
/// idempotent, so relay re-delivery can never double-count.
@Collection(ignore: {'copyWith'})
@Name('NoteRelation')
class NoteRelationModel {
  Id id = Isar.autoIncrement;

  /// The referenced (parent) event — the one whose count goes up.
  @Index(composite: [CompositeIndex('childId')], unique: true, replace: true)
  late String parentId;

  /// The referencing (child) event — the reply/reference.
  @Index()
  late String childId;

  late DateTime createdAt;
}

/// Every event below [rootId] in the reference graph (replies of replies
/// included), [rootId] itself excluded. Safe on cycles.
Future<Set<String>> descendantIdsOf(Isar isar, String rootId) async {
  final seen = <String>{rootId};
  final found = <String>{};
  var frontier = <String>[rootId];
  while (frontier.isNotEmpty) {
    final edges = await isar.noteRelationModels
        .filter()
        .anyOf(frontier, (q, id) => q.parentIdEqualTo(id))
        .findAll();
    final next = <String>[];
    for (final e in edges) {
      if (seen.add(e.childId)) {
        found.add(e.childId);
        next.add(e.childId);
      }
    }
    frontier = next;
  }
  return found;
}
