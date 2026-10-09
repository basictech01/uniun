import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/features/onboarding/pages/welcome_page.dart';
import 'package:uniun/features/settings/pages/language_selection_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockSetAppLocale extends Mock implements SetAppLocaleUseCase {}

void main() {
  Widget host(LocaleCubit cubit, Widget page) => BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  );

  LocaleCubit newCubit() {
    final setLocale = _MockSetAppLocale();
    when(
      () => setLocale.call(any()),
    ).thenAnswer((_) async => const Right(unit));
    final cubit = LocaleCubit(setLocale, initial: const Locale('en'));
    addTearDown(cubit.close);
    return cubit;
  }

  testWidgets('Gujarati is first in the picker and can be selected', (
    tester,
  ) async {
    final cubit = newCubit();
    await tester.pumpWidget(host(cubit, const LanguageSelectionPage()));

    expect(find.text('ગુજરાતી'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('ગુજરાતી')).dy,
      lessThan(tester.getTopLeft(find.text('日本語')).dy),
    );
    await tester.tap(find.text('ગુજરાતી'));
    await tester.pumpAndSettle();

    expect(cubit.state, const Locale('gu'));
  });

  testWidgets('Japanese is second in the picker and can be selected', (
    tester,
  ) async {
    final cubit = newCubit();
    await tester.pumpWidget(host(cubit, const LanguageSelectionPage()));

    expect(find.text('日本語'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('日本語')).dy,
      lessThan(tester.getTopLeft(find.text('हिन्दी')).dy),
    );
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();

    expect(cubit.state, const Locale('ja'));
  });

  testWidgets('welcome page keeps the English and Hindi quick choices', (
    tester,
  ) async {
    final cubit = newCubit();
    await tester.pumpWidget(host(cubit, const WelcomePage()));

    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('ગુજરાતી'), findsNothing);
    expect(find.text('日本語'), findsNothing);
  });
}
