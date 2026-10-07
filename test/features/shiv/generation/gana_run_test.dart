import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/models/gana_run_model.dart';
import 'package:uniun/features/shiv/generation/gana_run.dart';

import '../../../_helpers/fixtures.dart';
import '../../../_helpers/isar_test_harness.dart';

/// [writeGanaRun] against real Isar: the run row and the lifetime counters.
void main() {
  late Isar isar;

  setUp(() async {
    isar = await openTestIsar();
    await isar.writeTxn(() async {
      await isar.ganaModels.put(
        GanaModel()
          ..ganaId = 'g1'
          ..name = 'G'
          ..manasIds = const []
          ..taskPrompt = 't'
          ..outputType = aGana().outputType
          ..triggerMode = aGana().triggerMode
          ..createdAt = tT0
          ..updatedAt = tT0,
      );
    });
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Future<void> write(String runId, GanaRunStatus status,
          {String ganaId = 'g1'}) =>
      writeGanaRun(
        isar: isar,
        runId: runId,
        ganaId: ganaId,
        startedAt: tT0,
        status: status,
      );

  Future<GanaModel> gana() async =>
      (await isar.ganaModels.filter().ganaIdEqualTo('g1').findFirst())!;

  test('a legacy Gana with no counters reads zero entities', () async {
    expect((await gana()).toDomain().runsSucceeded, 0);
    expect((await gana()).toDomain().runsFailed, 0);
    expect((await gana()).toDomain().runsSkipped, 0);
  });

  test('each finished status bumps only its own counter', () async {
    await write('r1', GanaRunStatus.succeeded);
    await write('r2', GanaRunStatus.succeeded);
    await write('r3', GanaRunStatus.failed);
    await write('r4', GanaRunStatus.skipped);

    final g = (await gana()).toDomain();
    expect((g.runsSucceeded, g.runsFailed, g.runsSkipped), (2, 1, 1));
  });

  test('a running row is logged but not counted', () async {
    await write('r1', GanaRunStatus.running);

    final g = (await gana()).toDomain();
    expect((g.runsSucceeded, g.runsFailed, g.runsSkipped), (0, 0, 0));
    expect(await isar.ganaRunModels.count(), 1);
  });

  test('running then finished under one runId counts once', () async {
    await write('r1', GanaRunStatus.running);
    await write('r1', GanaRunStatus.failed);

    expect((await gana()).runsFailed, 1);
    expect(await isar.ganaRunModels.count(), 1);
  });

  test('re-writing a finished runId does not count it again', () async {
    await write('r1', GanaRunStatus.succeeded);
    await write('r1', GanaRunStatus.succeeded);

    expect((await gana()).runsSucceeded, 1);
    expect(await isar.ganaRunModels.count(), 1);
  });

  test('a run for an unknown Gana is logged without throwing', () async {
    await write('r1', GanaRunStatus.succeeded, ganaId: 'ghost');

    expect(await isar.ganaRunModels.count(), 1);
    expect((await gana()).runsSucceeded, isNull);
  });

  test('pruning the run log leaves the lifetime counters alone', () async {
    for (var i = 0; i < 12; i++) {
      await write('r$i', GanaRunStatus.succeeded);
    }
    await isar.writeTxn(() => isar.ganaRunModels.clear());

    expect((await gana()).runsSucceeded, 12);
  });
}
