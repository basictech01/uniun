import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/usecases/gana_usecases.dart';
import 'package:uniun/features/shiv/gana/list/bloc/gana_list_bloc.dart';

import '../../../../../_helpers/fixtures.dart';
import '../../../../../_helpers/isar_test_harness.dart';

class _MockGetGanas extends Mock implements GetGanasUseCase {}

class _MockGetRuns extends Mock implements GetGanaRunsUseCase {}

class _MockSetEnabled extends Mock implements SetGanaEnabledUseCase {}

class _MockDelete extends Mock implements DeleteGanaUseCase {}

/// GanaListBloc: a load fills each Gana's newest-first run list and last run.
void main() {
  late Isar isar;
  late _MockGetGanas getGanas;
  late _MockGetRuns getRuns;

  setUp(() async {
    isar = await openTestIsar();
    getGanas = _MockGetGanas();
    getRuns = _MockGetRuns();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  GanaListBloc build() =>
      GanaListBloc(getGanas, getRuns, _MockSetEnabled(), _MockDelete(), isar);

  test('load keeps every recent run and the newest as the last run', () async {
    final newest = aGanaRun(runId: 'r2', ganaId: 'a');
    final older = aGanaRun(
      runId: 'r1',
      ganaId: 'a',
      status: GanaRunStatus.failed,
    );
    when(
      () => getGanas.call(),
    ).thenAnswer((_) async => Right([aGana(ganaId: 'a'), aGana(ganaId: 'b')]));
    when(
      () => getRuns.call('a'),
    ).thenAnswer((_) async => Right([newest, older]));
    when(() => getRuns.call('b')).thenAnswer((_) async => const Right([]));

    final bloc = build()..add(const GanaListLoadEvent());
    final state = await bloc.stream.firstWhere(
      (s) => s.status == GanaListStatus.ready,
    );
    await bloc.close();

    expect(state.recentRuns['a'], [newest, older]);
    expect(state.lastRuns['a'], newest);
    expect(state.recentRuns['b'], isEmpty);
    expect(state.lastRuns['b'], isNull);
  });

  test(
    'a failed run lookup leaves that Gana with no runs, not an error',
    () async {
      when(
        () => getGanas.call(),
      ).thenAnswer((_) async => Right([aGana(ganaId: 'a')]));
      when(
        () => getRuns.call('a'),
      ).thenAnswer((_) async => Left(Failure.errorFailure('db closed')));

      final bloc = build()..add(const GanaListLoadEvent());
      final state = await bloc.stream.firstWhere(
        (s) => s.status == GanaListStatus.ready,
      );
      await bloc.close();

      expect(state.recentRuns['a'], isEmpty);
    },
  );
}
