import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/domain/usecases/gana_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/shiv/gana/detail/pages/gana_detail_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../../_helpers/fixtures.dart';

class _MockGetGana extends Mock implements GetGanaByIdUseCase {}

class _MockGetRuns extends Mock implements GetGanaRunsUseCase {}

class _MockResolve extends Mock implements ResolveNotesByIdsUseCase {}

/// GanaDetailPage: lifetime stats, the config summary and the drop-down run
/// list, loaded through use cases.
void main() {
  late _MockGetGana getGana;
  late _MockGetRuns getRuns;
  late _MockResolve resolve;

  setUp(() async {
    getGana = _MockGetGana();
    getRuns = _MockGetRuns();
    resolve = _MockResolve();
    await GetIt.instance.reset();
    GetIt.instance
      ..registerFactory<GetGanaByIdUseCase>(() => getGana)
      ..registerFactory<GetGanaRunsUseCase>(() => getRuns)
      ..registerFactory<ResolveNotesByIdsUseCase>(() => resolve);
    when(() => resolve.call(any())).thenAnswer((_) async => const Right([]));
  });

  Future<void> show(WidgetTester t) async {
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GanaDetailPage(ganaId: 'g1'),
      ),
    );
    await t.pumpAndSettle();
  }

  void givenGana({int ok = 0, int bad = 0, int skipped = 0}) =>
      when(() => getGana.call('g1')).thenAnswer(
        (_) async => Right(
          aGana(
            ganaId: 'g1',
            name: 'Alpha',
            runsSucceeded: ok,
            runsFailed: bad,
            runsSkipped: skipped,
          ),
        ),
      );

  testWidgets('shows the Gana name, lifetime counts and success rate', (
    t,
  ) async {
    givenGana(ok: 3, bad: 1, skipped: 4);
    when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));

    await show(t);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('75% succeeded'), findsOneWidget);
    expect(find.text('Brahma'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('with no runs it says the Gana has not run yet', (t) async {
    givenGana();
    when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));

    await show(t);

    expect(find.text("This Gana hasn't run yet."), findsOneWidget);
    expect(find.text('75% succeeded'), findsNothing);
  });

  testWidgets('a run that published a note opens to that note', (t) async {
    givenGana(ok: 1);
    when(() => getRuns.call('g1')).thenAnswer(
      (_) async =>
          Right([aGanaRun(ganaId: 'g1').copyWith(outputEventId: 'note-1')]),
    );
    when(() => resolve.call(['note-1'])).thenAnswer(
      (_) async => Right([aNote(id: 'note-1', content: 'Show up today')]),
    );

    await show(t);
    await t.tap(find.byType(ExpansionTile));
    await t.pumpAndSettle();

    expect(find.text('Show up today'), findsOneWidget);
  });

  testWidgets('only looks up notes for runs that published one', (t) async {
    givenGana(bad: 1);
    when(() => getRuns.call('g1')).thenAnswer(
      (_) async => Right([
        aGanaRun(ganaId: 'g1', status: GanaRunStatus.failed, error: 'boom'),
      ]),
    );

    await show(t);

    verify(() => resolve.call(const [])).called(1);
  });

  testWidgets('a failed run opens to the reason in words', (t) async {
    givenGana(bad: 1);
    when(() => getRuns.call('g1')).thenAnswer(
      (_) async => Right([
        aGanaRun(
          ganaId: 'g1',
          status: GanaRunStatus.failed,
          error: 'cloud: SocketException: Connection refused',
        ),
      ]),
    );

    await show(t);
    await t.tap(find.byType(ExpansionTile));
    await t.pumpAndSettle();

    expect(find.text('Network problem'), findsOneWidget);
    expect(
      find.text('cloud: SocketException: Connection refused'),
      findsOneWidget,
    );
  });

  testWidgets('a Gana that cannot be loaded shows the fallback title', (
    t,
  ) async {
    when(
      () => getGana.call('g1'),
    ).thenAnswer((_) async => Left(Failure.errorFailure('not found')));
    when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));

    await show(t);

    expect(find.text('Edit Gana'), findsWidgets);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('shows the interval, reactive flag, cap and last run when set', (
    t,
  ) async {
    when(() => getGana.call('g1')).thenAnswer(
      (_) async => Right(
        aGana(
          ganaId: 'g1',
          name: 'Alpha',
          triggerReactive: true,
          triggerIntervalMinutes: 15,
          maxOutputs: 5,
        ).copyWith(lastRunAt: DateTime(2026, 10, 6, 9, 30)),
      ),
    );
    when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));

    await show(t);

    expect(find.text('15m'), findsOneWidget);
    expect(find.text('on'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Last run'), findsOneWidget);
  });

  testWidgets('a one-shot hides the interval and the cap', (t) async {
    when(() => getGana.call('g1')).thenAnswer(
      (_) async => Right(
        aGana(
          ganaId: 'g1',
          name: 'Alpha',
          triggerMode: GanaTriggerMode.oneShot,
          triggerIntervalMinutes: 15,
          maxOutputs: 5,
        ),
      ),
    );
    when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));

    await show(t);

    expect(find.text('Interval'), findsNothing);
    expect(find.text('Max notes'), findsNothing);
    expect(find.text('one-shot'), findsOneWidget);
  });

  group('edit', () {
    Future<void> showWithRouter(WidgetTester t, {required bool saved}) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const GanaDetailPage(ganaId: 'g1'),
          ),
          GoRoute(
            name: AppRoutes.shivGanaForm,
            path: '/form',
            builder: (ctx, __) => Scaffold(
              body: TextButton(
                onPressed: () => ctx.pop(saved),
                child: const Text('CLOSE FORM'),
              ),
            ),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('reloads the Gana after a save', (t) async {
      givenGana();
      when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));
      await showWithRouter(t, saved: true);

      await t.tap(find.byIcon(Icons.edit_outlined));
      await t.pumpAndSettle();
      await t.tap(find.text('CLOSE FORM'));
      await t.pumpAndSettle();

      verify(() => getGana.call('g1')).called(2);
    });

    testWidgets('does not reload when the form was closed unsaved', (t) async {
      givenGana();
      when(() => getRuns.call('g1')).thenAnswer((_) async => const Right([]));
      await showWithRouter(t, saved: false);

      await t.tap(find.byIcon(Icons.edit_outlined));
      await t.pumpAndSettle();
      await t.tap(find.text('CLOSE FORM'));
      await t.pumpAndSettle();

      verify(() => getGana.call('g1')).called(1);
    });
  });
}
