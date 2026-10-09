import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/l10n/app_language.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';

class _MockSetAppLocale extends Mock implements SetAppLocaleUseCase {}

void main() {
  group('LocaleCubit.resolveInitial', () {
    test('uses a saved supported code over the system locale', () {
      final locale = LocaleCubit.resolveInitial(
        savedCode: 'hi',
        systemLocales: const [Locale('en')],
      );
      expect(locale, const Locale('hi'));
    });

    test('restores Gujarati over the system locale', () {
      final locale = LocaleCubit.resolveInitial(
        savedCode: 'gu',
        systemLocales: const [Locale('en')],
      );
      expect(locale, const Locale('gu'));
    });

    test('ignores a saved code that is not a supported language', () {
      // 'bn' (Bengali) exists in the registry but ships no translation yet.
      final locale = LocaleCubit.resolveInitial(
        savedCode: 'bn',
        systemLocales: const [Locale('hi')],
      );
      expect(locale, const Locale('hi'));
    });

    test('falls back to the first supported system locale when none saved', () {
      final locale = LocaleCubit.resolveInitial(
        savedCode: null,
        systemLocales: const [Locale('fr'), Locale('hi'), Locale('en')],
      );
      expect(locale, const Locale('hi'));
    });

    test('selects Gujarati from the system locales', () {
      final locale = LocaleCubit.resolveInitial(
        savedCode: null,
        systemLocales: const [Locale('fr'), Locale('gu', 'IN')],
      );
      expect(locale, const Locale('gu'));
    });

    test('falls back to English when nothing matches', () {
      final locale = LocaleCubit.resolveInitial(
        savedCode: null,
        systemLocales: const [Locale('fr'), Locale('de')],
      );
      expect(locale, const Locale('en'));
    });
  });

  group('LocaleCubit.setLanguage', () {
    late _MockSetAppLocale setLocale;

    setUp(() {
      setLocale = _MockSetAppLocale();
      when(
        () => setLocale.call(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    blocTest<LocaleCubit, Locale>(
      'emits the new locale and persists it',
      build: () => LocaleCubit(setLocale, initial: const Locale('en')),
      act: (cubit) => cubit.setLanguage(AppLanguage.hindi),
      expect: () => const [Locale('hi')],
      verify: (_) => verify(() => setLocale.call('hi')).called(1),
    );

    blocTest<LocaleCubit, Locale>(
      'persists Gujarati when selected',
      build: () => LocaleCubit(setLocale, initial: const Locale('en')),
      act: (cubit) => cubit.setLanguage(AppLanguage.gujarati),
      expect: () => const [Locale('gu')],
      verify: (_) => verify(() => setLocale.call('gu')).called(1),
    );

    blocTest<LocaleCubit, Locale>(
      'no-ops when the language is already active',
      build: () => LocaleCubit(setLocale, initial: const Locale('hi')),
      act: (cubit) => cubit.setLanguage(AppLanguage.hindi),
      expect: () => const <Locale>[],
      verify: (_) => verifyNever(() => setLocale.call(any())),
    );

    blocTest<LocaleCubit, Locale>(
      'no-ops for a not-yet-supported language',
      build: () => LocaleCubit(setLocale, initial: const Locale('en')),
      act: (cubit) => cubit.setLanguage(AppLanguage.tamil),
      expect: () => const <Locale>[],
      verify: (_) => verifyNever(() => setLocale.call(any())),
    );
  });
}
