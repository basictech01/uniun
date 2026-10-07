import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_activity_tile.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../../_helpers/fixtures.dart';

/// GanaActivityTile: the run line, the failure text, and the tap to the Gana.
void main() {
  Future<List<String>> show(WidgetTester t, GanaActivityTile tile) async {
    final opened = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(body: tile),
        ),
        GoRoute(
          name: AppRoutes.shivGanaDetail,
          path: '/detail/:ganaId',
          builder: (_, s) {
            opened.add(s.pathParameters['ganaId']!);
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

  testWidgets('shows the Gana name, the status and the error of a failure', (
    t,
  ) async {
    await show(
      t,
      GanaActivityTile(
        ganaName: 'Alpha',
        run: aGanaRun(status: GanaRunStatus.failed, error: 'boom'),
      ),
    );

    expect(find.text('Alpha · Failed'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('a succeeded run shows no error line', (t) async {
    await show(
      t,
      GanaActivityTile(
        ganaName: 'Alpha',
        run: aGanaRun(error: 'ignored'),
      ),
    );

    expect(find.text('ignored'), findsNothing);
  });

  testWidgets('tapping it opens that run\'s Gana', (t) async {
    final opened = await show(
      t,
      GanaActivityTile(
        ganaName: 'Alpha',
        run: aGanaRun(ganaId: 'g7'),
      ),
    );

    await t.tap(find.text('Alpha · Succeeded'));
    await t.pumpAndSettle();

    expect(find.text('DETAIL PAGE'), findsOneWidget);
    expect(opened, ['g7']);
  });
}
