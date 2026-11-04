import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockRelays extends Mock implements GetRelaysUseCase {}

/// Covers: opening the relay sheet from the field and closing it with Done.
void main() {
  setUp(() async {
    await GetIt.instance.reset();
    final relays = _MockRelays();
    when(() => relays.call()).thenAnswer((_) async => const Right([]));
    GetIt.instance.registerFactory<GetRelaysUseCase>(() => relays);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('Done closes the relay sheet', (t) async {
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

    await t.tap(find.byIcon(Icons.dns_rounded));
    await t.pumpAndSettle();
    expect(find.byType(UniunButton), findsOneWidget);

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();

    expect(find.byType(UniunButton), findsNothing);
  });
}
