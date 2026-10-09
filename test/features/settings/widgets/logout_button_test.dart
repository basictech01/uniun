import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/repositories/logout_session_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/settings/widgets/logout_button.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _UserRepository extends Mock implements UserRepository {}

class _SessionRepository extends Mock implements LogoutSessionRepository {}

/// The logout warning passes the model-file choice into session cleanup.
void main() {
  late _UserRepository users;
  late _SessionRepository session;
  late GoRouter router;

  setUp(() async {
    await getIt.reset();
    users = _UserRepository();
    session = _SessionRepository();
    when(() => users.logout()).thenAnswer((_) async => const Right(unit));
    when(
      () => session.clear(keepModelFiles: any(named: 'keepModelFiles')),
    ).thenAnswer((_) async => const Right(unit));
    getIt.registerSingleton<LogoutUseCase>(LogoutUseCase(users, session));
    router = GoRouter(
      routes: [
        GoRoute(
          name: 'testHome',
          path: '/',
          builder: (_, __) => const Scaffold(body: LogoutButton()),
        ),
        GoRoute(
          name: AppRoutes.welcome,
          path: '/welcome',
          builder: (_, __) => const Scaffold(body: Text('Welcome screen')),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await getIt.reset();
  });

  Widget host() => MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
  );

  testWidgets('checkbox is off by default and downloaded models are removed', (
    t,
  ) async {
    await t.pumpWidget(host());
    await t.tap(find.text('Log out'));
    await t.pumpAndSettle();

    expect(
      t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await t.tap(find.text('Log out').last);
    await t.pumpAndSettle();

    verify(() => session.clear(keepModelFiles: false)).called(1);
    expect(find.text('Welcome screen'), findsOneWidget);
  });

  testWidgets('checked option preserves downloaded models', (t) async {
    await t.pumpWidget(host());
    await t.tap(find.text('Log out'));
    await t.pumpAndSettle();

    await t.tap(find.text('Keep downloaded AI models for another login'));
    await t.pump();
    expect(
      t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    await t.tap(find.text('Log out').last);
    await t.pumpAndSettle();

    verify(() => session.clear(keepModelFiles: true)).called(1);
  });

  testWidgets('shows progress until account cleanup finishes', (t) async {
    final release = Completer<Either<Failure, Unit>>();
    when(
      () => session.clear(keepModelFiles: true),
    ).thenAnswer((_) => release.future);
    await t.pumpWidget(host());
    await t.tap(find.text('Log out'));
    await t.pumpAndSettle();
    await t.tap(find.text('Keep downloaded AI models for another login'));
    await t.pump();
    await t.tap(find.text('Log out').last);
    await t.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Logging out…'), findsOneWidget);
    release.complete(const Right(unit));
    await t.pumpAndSettle();
    expect(find.text('Welcome screen'), findsOneWidget);
  });

  testWidgets('cancel leaves the session active', (t) async {
    await t.pumpWidget(host());
    await t.tap(find.text('Log out'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();

    verifyNever(
      () => session.clear(keepModelFiles: any(named: 'keepModelFiles')),
    );
    verifyNever(() => users.logout());
  });

  testWidgets('cleanup failure closes progress and keeps the user signed in', (
    t,
  ) async {
    when(() => session.clear(keepModelFiles: false)).thenAnswer(
      (_) async => const Left(Failure.errorFailure('cleanup failed')),
    );
    await t.pumpWidget(host());
    await t.tap(find.text('Log out'));
    await t.pumpAndSettle();
    await t.tap(find.text('Log out').last);
    await t.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Welcome screen'), findsNothing);
    verifyNever(() => users.logout());
  });
}
