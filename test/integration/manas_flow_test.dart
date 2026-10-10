import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/repositories/manas_repository_impl.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

import '../_helpers/isar_test_harness.dart';
import '../_helpers/isar_seeds.dart';
import '../_helpers/stub_user_repository.dart';

ManasEntity _manas(String id, {String? name, String? icon, DateTime? when}) =>
    ManasEntity(
      manasId: id,
      name: name ?? id,
      iconName: icon,
      createdAt: when ?? DateTime(2026, 1, 1),
      updatedAt: when ?? DateTime(2026, 1, 1),
    );

/// End-to-end scenarios for the Manas lifecycle, driving the real data
/// layer (Isar) through the real use cases. No mocks — every step is the
/// same code path the BLoC hits in production.
///
/// Covers the user-visible scenarios:
///   1. Create → add notes → list shows the new manas with noteCount
///   2. Edit (rename + change icon) — keeps memberships intact
///   3. Add + remove notes (membership churn)
///   4. Delete cascades: links to the deleted manas disappear, but
///      sibling manases keep their links to the same note
///   5. One note can belong to multiple manases simultaneously
///   6. Re-add same (manas, note) pair → idempotent (no duplicate row)
///   7. Notes from feed and both group kinds coexist in one Manas
void main() {
  late Isar isar;
  late ManasRepositoryImpl repo;
  late UpsertManasUseCase upsert;
  late GetManasListUseCase listManas;
  late GetManasByIdUseCase getById;
  late DeleteManasUseCase deleteManas;
  late AddNoteToManasUseCase addLink;
  late RemoveNoteFromManasUseCase removeLink;
  late GetNoteIdsForManasUseCase notesOf;
  late GetManasIdsForNoteUseCase manasesOf;

  setUp(() async {
    isar = await openTestIsar();
    // Logged-out stub — `sign()` returns null so rows are written with
    // `signedNostrEvent = null`. The integration test doesn't assert on
    // the wire form; that's covered by test/mesh/sync_integration_test.dart.
    final signer = MeshEventSigner(StubUserRepository()..keys = null);
    repo = ManasRepositoryImpl(isar: isar, signer: signer);
    upsert = UpsertManasUseCase(repo);
    listManas = GetManasListUseCase(repo);
    getById = GetManasByIdUseCase(repo);
    deleteManas = DeleteManasUseCase(repo);
    addLink = AddNoteToManasUseCase(repo);
    removeLink = RemoveNoteFromManasUseCase(repo);
    notesOf = GetNoteIdsForManasUseCase(repo);
    manasesOf = GetManasIdsForNoteUseCase(repo);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('Scenario 1: create → add 2 notes → list shows it with noteCount=2', () async {
    await upsert.call(_manas('work', name: 'Work', icon: 'work'));
    await addLink.call(const ManasNoteLink('work', 'note-1'));
    expect((await getById.call('work')).getOrElse(() => throw 'missing').noteCount, 1);
    expect((await manasesOf.call('note-1')).getOrElse(() => []), ['work']);
    expect((await manasesOf.call('note-2')).getOrElse(() => []), isEmpty);

    await addLink.call(const ManasNoteLink('work', 'note-2'));
    expect((await manasesOf.call('note-1')).getOrElse(() => []), ['work']);
    expect((await manasesOf.call('note-2')).getOrElse(() => []), ['work']);

    final list = (await listManas.call()).getOrElse(() => []);
    expect(list, hasLength(1));
    expect(list.single.manasId, 'work');
    expect(list.single.noteCount, 2);

    final ids = (await notesOf.call('work')).getOrElse(() => const <String>[]);
    expect(ids, ['note-1', 'note-2']);
  });

  test('Scenario 2: rename + icon change preserves memberships', () async {
    await upsert.call(_manas('m', name: 'Original', icon: 'work'));
    await addLink.call(const ManasNoteLink('m', 'n-1'));
    await addLink.call(const ManasNoteLink('m', 'n-2'));

    // Edit: same manasId, different name/icon, new updatedAt.
    await upsert.call(_manas(
      'm',
      name: 'Renamed',
      icon: 'lightbulb',
      when: DateTime(2026, 6, 1),
    ));

    final edited = (await getById.call('m')).getOrElse(() => throw 'left');
    expect(edited.name, 'Renamed');
    expect(edited.iconName, 'lightbulb');
    expect(edited.noteCount, 2, reason: 'links survive the upsert');
  });

  test('Scenario 3: add/remove notes — count tracks correctly', () async {
    await upsert.call(_manas('m'));
    await addLink.call(const ManasNoteLink('m', 'a'));
    await addLink.call(const ManasNoteLink('m', 'b'));
    await addLink.call(const ManasNoteLink('m', 'c'));
    expect((await getById.call('m')).getOrElse(() => throw 'left').noteCount, 3);

    await removeLink.call(const ManasNoteLink('m', 'b'));
    expect((await getById.call('m')).getOrElse(() => throw 'left').noteCount, 2);

    final remaining =
        (await notesOf.call('m')).getOrElse(() => const <String>[]);
    expect(remaining, ['a', 'c']);
  });

  test('Scenario 4: delete cascades links — siblings unaffected', () async {
    await upsert.call(_manas('doomed'));
    await upsert.call(_manas('survivor'));
    await addLink.call(const ManasNoteLink('doomed', 'shared'));
    await addLink.call(const ManasNoteLink('survivor', 'shared'));
    await addLink.call(const ManasNoteLink('doomed', 'only-doomed'));

    await deleteManas.call('doomed');

    // The note "shared" still belongs to "survivor".
    final survivorsOfShared =
        (await manasesOf.call('shared')).getOrElse(() => const <String>[]);
    expect(survivorsOfShared, ['survivor']);

    // "only-doomed" has no manases left.
    final survivorsOfOrphan =
        (await manasesOf.call('only-doomed')).getOrElse(() => const <String>[]);
    expect(survivorsOfOrphan, isEmpty);

    // Survivor still reads back fine.
    expect((await getById.call('survivor')).getOrElse(() => throw 'left').noteCount, 1);
  });

  test('Scenario 5: one note in multiple manases (many-to-many)', () async {
    await upsert.call(_manas('work'));
    await upsert.call(_manas('research'));
    await upsert.call(_manas('personal'));
    await addLink.call(const ManasNoteLink('work', 'cross-cutting'));
    await addLink.call(const ManasNoteLink('research', 'cross-cutting'));
    await addLink.call(const ManasNoteLink('personal', 'cross-cutting'));

    final mlist =
        (await manasesOf.call('cross-cutting')).getOrElse(() => const <String>[]);
    expect(mlist.toSet(), {'work', 'research', 'personal'});

    // Each manas has the note exactly once.
    for (final id in mlist) {
      final notes = (await notesOf.call(id)).getOrElse(() => const <String>[]);
      expect(notes.where((n) => n == 'cross-cutting'), hasLength(1));
    }
  });

  test('Scenario 6: re-adding (manas, note) → idempotent; no duplicate', () async {
    await upsert.call(_manas('m'));
    for (var i = 0; i < 5; i++) {
      await addLink.call(const ManasNoteLink('m', 'n'));
    }
    expect((await getById.call('m')).getOrElse(() => throw 'left').noteCount, 1);
  });

  test('Scenario 7: feed and group note kinds share one Manas', () async {
    await isar.writeTxn(() async {
      await isar.noteModels.putAll([
        noteRow('feed-note', kind: kNoteKind),
        noteRow('public-group-note',
            kind: kGroupMessageKind, groupId: 'public-group'),
        noteRow('private-group-note',
            kind: kPrivateGroupKind, privateGroupId: 'private-group'),
      ]);
    });
    await upsert.call(_manas('mixed-sources'));
    for (final id in ['feed-note', 'public-group-note', 'private-group-note']) {
      await addLink.call(ManasNoteLink('mixed-sources', id));
    }

    expect((await notesOf.call('mixed-sources')).getOrElse(() => []).toSet(),
        {'feed-note', 'public-group-note', 'private-group-note'});
    expect((await getById.call('mixed-sources'))
        .getOrElse(() => throw 'missing').noteCount, 3);
  });

  test('Property: a freshly-deleted manas reappearing via upsert starts clean', () async {
    // User deletes a manas and later re-creates one with the same name. The
    // re-created manas must NOT inherit the deleted one's old links.
    await upsert.call(_manas('reused'));
    await addLink.call(const ManasNoteLink('reused', 'a'));
    await addLink.call(const ManasNoteLink('reused', 'b'));

    await deleteManas.call('reused');

    await upsert.call(_manas('reused', name: 'Reused Fresh'));
    final fresh = (await getById.call('reused')).getOrElse(() => throw 'left');
    expect(fresh.noteCount, 0,
        reason: 'delete cascaded links, re-upsert starts clean');
  });
}
