import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/onboarding/pages/how_it_works_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: Next walks the six slides with an arrow, the last slide says Get
/// started without an arrow and closes, Skip closes, closing a root route
/// goes to Welcome.
void main() {
  Widget app({required bool pushed}) {
    final router = GoRouter(
      initialLocation: pushed ? '/' : '/how',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/how'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/how', builder: (_, _) => const HowItWorksPage()),
        GoRoute(
          path: '/welcome',
          name: AppRoutes.welcome,
          builder: (_, _) => const Scaffold(body: Text('welcome-page')),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(app(pushed: true));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> toLastSlide(WidgetTester t) async {
    while (find.text('Next').evaluate().isNotEmpty) {
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
    }
  }

  testWidgets('Next shows an arrow and moves on; last slide has none', (
    t,
  ) async {
    await open(t);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await toLastSlide(t);

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });

  testWidgets('Get started closes the carousel', (t) async {
    await open(t);
    await toLastSlide(t);

    await t.tap(find.text('Get started'));
    await t.pumpAndSettle();

    expect(find.byType(HowItWorksPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Skip closes the carousel', (t) async {
    await open(t);

    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();

    expect(find.byType(HowItWorksPage), findsNothing);
  });

  testWidgets('with nothing to pop, Skip goes to Welcome', (t) async {
    await t.pumpWidget(app(pushed: false));
    await t.pumpAndSettle();

    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();

    expect(find.text('welcome-page'), findsOneWidget);
  });
}
