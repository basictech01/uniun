import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/repositories/gana_repository_impl.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_test_harness.dart';
import '../../_helpers/stub_user_repository.dart';

/// [GanaRepositoryImpl.upsertGana] against real Isar.
void main() {
  late Isar isar;
  late GanaRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    repo = GanaRepositoryImpl(
      isar: isar,
      signer: MeshEventSigner(StubUserRepository()..keys = null),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('an edit keeps the engine-written lifetime counters', () async {
    await repo.upsertGana(aGana(name: 'Before'));
    await isar.writeTxn(() async {
      final row = (await isar.ganaModels.where().findFirst())!;
      row
        ..runsSucceeded = 7
        ..runsFailed = 2
        ..runsSkipped = 3;
      await isar.ganaModels.put(row);
    });

    final saved = await repo.upsertGana(aGana(name: 'After', enabled: true));

    final g = saved.getOrElse(() => throw StateError('save failed'));
    expect((g.runsSucceeded, g.runsFailed, g.runsSkipped), (7, 2, 3));
    expect(g.name, 'After');
  });

  test('a new Gana starts at zero', () async {
    final saved = await repo.upsertGana(aGana());

    final g = saved.getOrElse(() => throw StateError('save failed'));
    expect((g.runsSucceeded, g.runsFailed, g.runsSkipped), (0, 0, 0));
  });
}
