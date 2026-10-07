import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/features/shiv/gana/dashboard/pages/gana_dashboard_page.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_empty_state.dart';
import 'package:uniun/features/shiv/gana/list/bloc/gana_list_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../../_helpers/fixtures.dart';

class _MockGanaListBloc extends MockBloc<GanaListEvent, GanaListState>
    implements GanaListBloc {}

/// GanaDashboardPage navigation: New opens the form, a Gana opens its detail,
/// and the empty state offers the same New button.
void main() {
  late _MockGanaListBloc bloc;

  setUp(() async {
    bloc = _MockGanaListBloc();
    await GetIt.instance.reset();
    GetIt.instance.registerFactory<GanaListBloc>(() => bloc);
  });

  Future<List<String>> show(WidgetTester t, GanaListState state) async {
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    when(() => bloc.state).thenReturn(state);
    final opened = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const GanaDashboardPage()),
        GoRoute(
          name: AppRoutes.shivGanaForm,
          path: '/form',
          builder: (_, __) {
            opened.add('form');
            return const Scaffold(body: Text('FORM PAGE'));
          },
        ),
        GoRoute(
          name: AppRoutes.shivGanaDetail,
          path: '/detail/:ganaId',
          builder: (_, s) {
            opened.add('detail:${s.pathParameters['ganaId']}');
            return const Scaffold(body: Text('DETAIL PAGE'));
          },
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
    await t.pump();
    return opened;
  }

  testWidgets('New in the header opens the Gana form', (t) async {
    final opened = await show(
      t,
      GanaListState(
        status: GanaListStatus.ready,
        ganas: [aGana(name: 'Alpha')],
      ),
    );

    await t.tap(find.text('New'));
    await t.pumpAndSettle();

    expect(find.text('FORM PAGE'), findsOneWidget);
    expect(opened, ['form']);
  });

  testWidgets('tapping a Gana opens that Gana\'s detail', (t) async {
    final opened = await show(
      t,
      GanaListState(
        status: GanaListStatus.ready,
        ganas: [aGana(ganaId: 'a1', name: 'Alpha')],
      ),
    );

    await t.tap(find.text('Alpha'));
    await t.pumpAndSettle();

    expect(find.text('DETAIL PAGE'), findsOneWidget);
    expect(opened, ['detail:a1']);
  });

  testWidgets('the empty state has its own New button that opens the form', (
    t,
  ) async {
    final opened = await show(
      t,
      const GanaListState(status: GanaListStatus.ready),
    );

    await t.tap(
      find.descendant(
        of: find.byType(GanaEmptyState),
        matching: find.text('New'),
      ),
    );
    await t.pumpAndSettle();

    expect(opened, ['form']);
  });

  testWidgets('the loading state shows no numbers yet', (t) async {
    await show(t, const GanaListState(status: GanaListStatus.loading));

    expect(find.text('Done'), findsNothing);
    expect(find.text('New'), findsOneWidget);
  });
}
