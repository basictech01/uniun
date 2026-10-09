/// The set of languages UNIUN knows about, and which ones currently ship
/// translations. This is the single source of truth for every language-picking
/// surface: the full [LanguageSelectionPage] and the Settings language row.
/// The welcome screen intentionally offers only English and Hindi quick buttons.
///
/// `supported == true` means there is an `app_<code>.arb` wired into
/// `MaterialApp.supportedLocales` — the row is selectable. `supported == false`
/// is a roadmap entry rendered as "Coming soon" (greyed, non-tappable).
///
/// Adding a real translation later is two steps: ship `app_<code>.arb`, then
/// flip the matching entry's `supported` to `true`. The generated localization
/// class supplies `MaterialApp.supportedLocales`. Language names are shown in
/// their own scripts (`nativeName`) and are intentionally not localized.
///
/// Pure Dart — no Flutter import — so it can be used from the cubit, pages, and
/// tests alike.
enum AppLanguage {
  english(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    supported: true,
  ),
  hindi(
    code: 'hi',
    englishName: 'Hindi',
    nativeName: 'हिन्दी',
    supported: true,
  ),
  bengali(
    code: 'bn',
    englishName: 'Bengali',
    nativeName: 'বাংলা',
    supported: false,
  ),
  tamil(
    code: 'ta',
    englishName: 'Tamil',
    nativeName: 'தமிழ்',
    supported: false,
  ),
  telugu(
    code: 'te',
    englishName: 'Telugu',
    nativeName: 'తెలుగు',
    supported: false,
  ),
  marathi(
    code: 'mr',
    englishName: 'Marathi',
    nativeName: 'मराठी',
    supported: false,
  ),
  gujarati(
    code: 'gu',
    englishName: 'Gujarati',
    nativeName: 'ગુજરાતી',
    supported: true,
  ),
  kannada(
    code: 'kn',
    englishName: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    supported: false,
  ),
  punjabi(
    code: 'pa',
    englishName: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
    supported: false,
  ),
  spanish(
    code: 'es',
    englishName: 'Spanish',
    nativeName: 'Español',
    supported: false,
  );

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.supported,
  });

  /// ISO-639 language code, matches the `app_<code>.arb` suffix and `Locale`.
  final String code;

  /// English exonym (e.g. "Hindi") — used as a muted subtitle in the picker.
  final String englishName;

  /// The language's name in its own script (e.g. "हिन्दी") — the primary label.
  final String nativeName;

  /// Whether a translation ships today. `false` ⇒ "Coming soon".
  final bool supported;

  /// The language whose [code] matches `code`, or `null` if unknown.
  static AppLanguage? fromCode(String? code) {
    if (code == null) return null;
    for (final lang in values) {
      if (lang.code == code) return lang;
    }
    return null;
  }

  /// Languages that ship translations today (selectable).
  static List<AppLanguage> get supportedLanguages =>
      values.where((l) => l.supported).toList(growable: false);
}
