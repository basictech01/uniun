import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart'
    as app_drawer;
import 'package:uniun/features/vishnu/pages/vishnu_feed_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockFeed extends MockBloc<VishnuFeedEvent, VishnuFeedState>
    implements VishnuFeedBloc {}

class _MockDrawer
    extends MockBloc<app_drawer.DrawerEvent, app_drawer.DrawerState>
    implements app_drawer.DrawerBloc {}

/// Covers: the empty feed's Refresh button re-reads the feed and its scan
/// button opens the QR scanner.
void main() {
  late _MockFeed feed;
  late _MockDrawer drawer;
  late List<String> visited;

  setUpAll(() {
    registerFallbackValue(const RefreshFeedEvent());
    registerFallbackValue(app_drawer.DrawerLoadEvent());
  });

  setUp(() async {
    await GetIt.instance.reset();
    feed = _MockFeed();
    drawer = _MockDrawer();
    visited = [];
    when(() => feed.state).thenReturn(
      const VishnuFeedState(status: VishnuFeedStatus.loaded),
    );
    when(() => drawer.state).thenReturn(app_drawer.DrawerInitial());
    GetIt.instance.registerFactory<app_drawer.DrawerBloc>(() => drawer);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<VishnuFeedBloc>.value(
            value: feed,
            child: VishnuFeedPage(currentIndex: 1, onSwitchTab: (_) async {}),
          ),
        ),
        GoRoute(
          path: '/scan',
          name: AppRoutes.scanQr,
          builder: (_, _) {
            visited.add('scan');
            return const SizedBox();
          },
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await t.pump();
  }

  testWidgets('Refresh re-reads the feed', (t) async {
    await pump(t);

    await t.tap(find.byType(UniunButton).first);

    verify(() => feed.add(any(that: isA<RefreshFeedEvent>()))).called(1);
  });

  testWidgets('the scan button opens the QR scanner', (t) async {
    await pump(t);

    await t.tap(find.byType(UniunButton).last);
    await t.pumpAndSettle();

    expect(visited, ['scan']);
  });
}
