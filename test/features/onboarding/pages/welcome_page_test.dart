import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/features/onboarding/pages/welcome_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockSetLocale extends Mock implements SetAppLocaleUseCase {}

/// Covers: both action buttons render, Create generates a keypair and opens
/// AboutYou with it, Restore opens ImportIdentity.
void main() {
  late LocaleCubit locale;
  late List<String> visited;
  Object? aboutYouExtra;

  Widget app() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const WelcomePage()),
        GoRoute(
          path: '/about',
          name: AppRoutes.aboutYou,
          builder: (_, s) {
            visited.add('about');
            aboutYouExtra = s.extra;
            return const SizedBox();
          },
        ),
        GoRoute(
          path: '/import',
          name: AppRoutes.importIdentity,
          builder: (_, _) {
            visited.add('import');
            return const SizedBox();
          },
        ),
        GoRoute(
          path: '/how',
          name: AppRoutes.howItWorks,
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    return BlocProvider<LocaleCubit>.value(
      value: locale,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  setUp(() {
    locale = LocaleCubit(_MockSetLocale(), initial: const Locale('en'));
    visited = [];
    aboutYouExtra = null;
  });

  testWidgets('shows the create and restore buttons', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();

    expect(find.text('Create Your Avatar'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
  });

  testWidgets('Create opens AboutYou with a fresh keypair', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();

    await t.tap(find.text('Create Your Avatar'));
    await t.pumpAndSettle();

    expect(visited, ['about']);
    final extra = aboutYouExtra! as Map;
    expect((extra['npub'] as String).startsWith('npub'), isTrue);
    expect((extra['nsec'] as String).startsWith('nsec'), isTrue);
    expect((extra['pubkeyHex'] as String).length, 64);
  });

  testWidgets('Restore opens ImportIdentity', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.vpn_key_outlined));
    await t.pumpAndSettle();

    expect(visited, ['import']);
  });
}
