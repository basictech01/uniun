import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/features/settings/pages/language_selection_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockSetAppLocale extends Mock implements SetAppLocaleUseCase {}

void main() {
  testWidgets('Gujarati is available and selection persists', (tester) async {
    final setLocale = _MockSetAppLocale();
    when(
      () => setLocale.call(any()),
    ).thenAnswer((_) async => const Right(unit));
    final cubit = LocaleCubit(setLocale, initial: const Locale('en'));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LanguageSelectionPage(),
        ),
      ),
    );

    expect(find.text('ગુજરાતી'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('ગુજરાતી')).dy,
      lessThan(tester.getTopLeft(find.text('हिन्दी')).dy),
    );
    await tester.tap(find.text('ગુજરાતી'));
    await tester.pumpAndSettle();

    expect(cubit.state, const Locale('gu'));
    verify(() => setLocale.call('gu')).called(1);
  });
}
