import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/i18n/translation_language.dart';

/// Covers: TranslationLanguage.fromCode's normalisation (region/script
/// suffixes, case, separators), its English fallback for null/unknown codes,
/// and the catalogue's own invariants (unique codes, no blank names).
void main() {
  group('fromCode', () {
    test('resolves an exact primary subtag', () {
      expect(TranslationLanguage.fromCode('hi').englishName, 'Hindi');
    });

    test('strips a region suffix with either separator', () {
      expect(TranslationLanguage.fromCode('pt-BR').code, 'pt');
      expect(TranslationLanguage.fromCode('zh_Hant').code, 'zh');
    });

    test('is case-insensitive', () {
      expect(TranslationLanguage.fromCode('JA').code, 'ja');
      expect(TranslationLanguage.fromCode('Es-mx').code, 'es');
    });

    test('null falls back to English rather than throwing', () {
      expect(TranslationLanguage.fromCode(null).code, 'en');
    });

    test('an unknown or malformed code falls back to English', () {
      for (final bad in ['xx', '', '-', '   ', '123', 'klingon']) {
        expect(TranslationLanguage.fromCode(bad).code, 'en', reason: bad);
      }
    });
  });

  group('catalogue', () {
    test('codes are unique', () {
      final codes = TranslationLanguage.all.map((l) => l.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
    });

    test('every entry has a non-empty English name and endonym', () {
      for (final l in TranslationLanguage.all) {
        expect(l.englishName.trim(), isNotEmpty, reason: l.code);
        expect(l.nativeName.trim(), isNotEmpty, reason: l.code);
      }
    });

    test('English is first so it is the fallback fromCode returns', () {
      expect(TranslationLanguage.all.first.code, 'en');
    });

    test('every app-supported UI locale has a translation target', () {
      // The picker seeds from the app locale; a UI language with no matching
      // entry would silently seed to English instead.
      for (final uiLocale in ['en', 'hi', 'gu']) {
        expect(TranslationLanguage.fromCode(uiLocale).code, uiLocale);
      }
    });
  });
}
