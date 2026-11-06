import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/usecases/delete_relay_usecase.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/domain/usecases/save_relay_usecase.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/settings/cubit/settings_cubit.dart';
import 'package:uniun/features/settings/widgets/identity_card.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fixtures.dart';

class _MockActiveUser extends Mock implements GetActiveUserUseCase {}

class _MockGetRelays extends Mock implements GetRelaysUseCase {}

class _MockSaveRelay extends Mock implements SaveRelayUseCase {}

class _MockDeleteRelay extends Mock implements DeleteRelayUseCase {}

/// Covers: the keys sheet's reveal button (loads the private key, hides it
/// again) and the relays sheet's add button (saves the typed relay, shows the
/// error when saving fails).
void main() {
  late _MockActiveUser activeUser;
  late _MockGetRelays getRelays;
  late _MockSaveRelay saveRelay;

  setUp(() async {
    await GetIt.instance.reset();
    activeUser = _MockActiveUser();
    getRelays = _MockGetRelays();
    saveRelay = _MockSaveRelay();
    when(() => getRelays.call()).thenAnswer((_) async => const Right([]));
    GetIt.instance
      ..registerFactory<GetActiveUserUseCase>(() => activeUser)
      ..registerFactory<GetRelaysUseCase>(() => getRelays)
      ..registerFactory<SaveRelayUseCase>(() => saveRelay)
      ..registerFactory<DeleteRelayUseCase>(() => _MockDeleteRelay());
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IdentityCard(state: SettingsState(npub: 'npub1abc')),
        ),
      ),
    );
  }

  Future<void> openRow(WidgetTester t, IconData icon) async {
    await t.tap(find.byIcon(icon));
    await t.pumpAndSettle();
  }

  testWidgets('Reveal loads the private key, and again hides it', (t) async {
    when(() => activeUser.call()).thenAnswer(
      (_) async => Right(aUserKey(nsec: 'nsec1secretvalue')),
    );
    await pump(t);
    await openRow(t, Icons.key_rounded);
    expect(find.text('nsec1secretvalue'), findsNothing);

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();
    expect(find.textContaining('nsec1secretvalue'), findsOneWidget);

    await t.tap(find.byIcon(Icons.visibility_off_rounded));
    await t.pumpAndSettle();
    expect(find.textContaining('nsec1secretvalue'), findsNothing);
    expect(find.byType(UniunButton), findsOneWidget);
  });

  testWidgets('Reveal shows a loader on the button while the key loads',
      (t) async {
    final pending = Completer<Either<Failure, UserKeyEntity>>();
    when(() => activeUser.call()).thenAnswer((_) => pending.future);
    await pump(t);
    await openRow(t, Icons.key_rounded);

    await t.tap(find.byType(UniunButton));
    await t.pump();

    expect(
      find.descendant(
        of: find.byType(UniunButton),
        matching: find.byType(DropLoadingIndicator),
      ),
      findsWidgets,
    );
    pending.complete(Right(aUserKey(nsec: 'nsec1secretvalue')));
    await t.pumpAndSettle();
  });

  testWidgets('a failing key lookup leaves the key hidden', (t) async {
    when(() => activeUser.call()).thenThrow(StateError('locked'));
    await pump(t);
    await openRow(t, Icons.key_rounded);

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();

    expect(find.byType(UniunButton), findsOneWidget);
  });

  testWidgets('Add saves the typed relay and closes the field', (t) async {
    when(() => saveRelay.call(any())).thenAnswer((_) async => Right(aRelay()));
    await pump(t);
    await openRow(t, Icons.cell_tower_rounded);
    await t.tap(find.byTooltip('Add relay'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'wss://relay.example');

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();

    verify(() => saveRelay.call('wss://relay.example')).called(1);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a failed save keeps the field and shows the error', (t) async {
    when(() => saveRelay.call(any())).thenAnswer(
      (_) async => const Left(Failure.errorFailure('boom')),
    );
    await pump(t);
    await openRow(t, Icons.cell_tower_rounded);
    await t.tap(find.byTooltip('Add relay'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'wss://bad');

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
