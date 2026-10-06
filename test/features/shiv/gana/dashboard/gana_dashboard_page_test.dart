import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/features/shiv/gana/dashboard/pages/gana_dashboard_page.dart';
import 'package:uniun/features/shiv/gana/list/bloc/gana_list_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../../_helpers/fixtures.dart';

class _MockGanaListBloc extends MockBloc<GanaListEvent, GanaListState>
    implements GanaListBloc {}

/// GanaDashboardPage: the summary totals, the attention list, per-Gana rows,
/// the recent-activity list and the on/off switch, driven by a fake bloc.
void main() {
  late _MockGanaListBloc bloc;

  setUpAll(() => registerFallbackValue(const GanaListLoadEvent()));

  setUp(() async {
    bloc = _MockGanaListBloc();
    await GetIt.instance.reset();
    GetIt.instance.registerFactory<GanaListBloc>(() => bloc);
  });

  Future<void> show(WidgetTester t, GanaListState state) async {
    // Tall enough to build the whole lazy list.
    t.view.physicalSize = const Size(800, 8000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    when(() => bloc.state).thenReturn(state);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GanaDashboardPage(),
      ),
    );
    await t.pump();
  }

  GanaListState ready({
    required List<dynamic> ganas,
    Map<String, dynamic> last = const {},
    Map<String, dynamic> recent = const {},
  }) => GanaListState(
    status: GanaListStatus.ready,
    ganas: ganas.cast(),
    lastRuns: last.cast(),
    recentRuns: recent.cast(),
  );

  testWidgets('the header has the common back button and a New button', (
    t,
  ) async {
    await show(t, ready(ganas: [aGana(name: 'Alpha')]));

    expect(find.byType(UniunBackButton), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('each Gana shows how it triggers and what it reads', (t) async {
    await show(
      t,
      ready(
        ganas: [
          aGana(name: 'Alpha', triggerReactive: true),
          aGana(ganaId: 'b', name: 'Beta', manasIds: ['m1', 'm2']),
        ],
      ),
    );

    expect(find.text('Reactive'), findsOneWidget);
    expect(find.text('All notes'), findsOneWidget);
    expect(find.text('2 Manas'), findsOneWidget);
  });

  testWidgets('with no Ganas it explains how to start', (t) async {
    await show(t, ready(ganas: const []));

    expect(
      find.text(
        'Create an AI worker that watches a surface and publishes for you.',
      ),
      findsOneWidget,
    );
    expect(find.text('Done'), findsNothing);
    expect(find.text('New'), findsNWidgets(2));
  });

  testWidgets('sums lifetime counts across Ganas and counts the active ones', (
    t,
  ) async {
    await show(
      t,
      ready(
        ganas: [
          aGana(
            ganaId: 'a',
            name: 'Alpha',
            enabled: true,
            runsSucceeded: 5,
            runsFailed: 1,
            runsSkipped: 2,
          ),
          aGana(ganaId: 'b', name: 'Beta', runsSucceeded: 3),
        ],
      ),
    );

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('5 done · 1 failed · 2 skipped'), findsOneWidget);
    expect(find.text('83% succeeded'), findsOneWidget);
  });

  testWidgets('lists a Gana whose last run failed under needs attention', (
    t,
  ) async {
    final failed = aGanaRun(
      ganaId: 'a',
      status: GanaRunStatus.failed,
      error: 'model exploded',
    );
    await show(
      t,
      ready(
        ganas: [aGana(ganaId: 'a', name: 'Alpha', runsFailed: 1)],
        last: {'a': failed},
        recent: {
          'a': [failed],
        },
      ),
    );

    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(find.text('model exploded'), findsNWidgets(2));
  });

  testWidgets('hides needs attention when the last run succeeded', (t) async {
    final ok = aGanaRun(ganaId: 'a');
    await show(
      t,
      ready(
        ganas: [aGana(ganaId: 'a', name: 'Alpha', runsSucceeded: 1)],
        last: {'a': ok},
        recent: {
          'a': [ok],
        },
      ),
    );

    expect(find.text('NEEDS ATTENTION'), findsNothing);
  });

  testWidgets('recent activity shows the 10 newest runs across Ganas', (
    t,
  ) async {
    final runs = [
      for (var i = 0; i < 12; i++)
        aGanaRun(
          runId: 'r$i',
          ganaId: 'a',
          startedAt: tNow.subtract(Duration(minutes: i)),
        ),
    ];
    await show(
      t,
      ready(
        ganas: [aGana(ganaId: 'a', name: 'Alpha')],
        last: {'a': runs.first},
        recent: {'a': runs},
      ),
    );
    expect(find.text('Alpha · Succeeded'), findsNWidgets(10));
  });

  testWidgets('says so when nothing has run yet', (t) async {
    await show(t, ready(ganas: [aGana(name: 'Alpha')]));
    expect(find.text('No runs yet'), findsOneWidget);
  });

  testWidgets('the switch asks the bloc to toggle that Gana', (t) async {
    await show(
      t,
      ready(
        ganas: [aGana(ganaId: 'a', name: 'Alpha')],
      ),
    );
    await t.tap(find.byType(Switch));

    final event = verify(
      () => bloc.add(captureAny()),
    ).captured.whereType<GanaListToggleEnabledEvent>().single;
    expect((event.ganaId, event.enabled), ('a', true));
  });
}
