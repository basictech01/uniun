import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/domain/usecases/save_relay_usecase.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockRelays extends Mock implements GetRelaysUseCase {}

class _MockSaveRelay extends Mock implements SaveRelayUseCase {}

/// Covers: opening the relay sheet from the field, closing it with Done, and
/// a failed add showing the plain failure message.
void main() {
  late _MockSaveRelay saveRelay;

  setUp(() async {
    await GetIt.instance.reset();
    final relays = _MockRelays();
    saveRelay = _MockSaveRelay();
    when(() => relays.call()).thenAnswer((_) async => const Right([]));
    GetIt.instance
      ..registerFactory<GetRelaysUseCase>(() => relays)
      ..registerFactory<SaveRelayUseCase>(() => saveRelay);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RelaySelectorField(selected: const [], onChanged: (_) {}),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('Done closes the relay sheet', (t) async {
    await pump(t);

    await t.tap(find.byIcon(Icons.dns_rounded));
    await t.pumpAndSettle();
    expect(find.byType(UniunButton), findsOneWidget);

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();

    expect(find.byType(UniunButton), findsNothing);
  });

  testWidgets('a failed add shows only the failure message', (t) async {
    when(
      () => saveRelay.call(any()),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    await pump(t);
    await t.tap(find.byIcon(Icons.dns_rounded));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField), 'wss://bad');
    await t.tap(find.widgetWithText(TextButton, 'Add'));
    await t.pumpAndSettle();

    expect(find.text('Could not add relay: boom'), findsOneWidget);
    expect(find.textContaining('Failure.'), findsNothing);
  });
}
