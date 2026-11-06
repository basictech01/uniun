import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/note_card/translate_language_sheet.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: the sheet pinning the current language to the top, the ordering
/// staying stable while the user picks, the app-locale hint showing only on
/// first run, and what the sheet returns on confirm vs dismiss.
void main() {
  Widget host(TranslationLanguage initial, {bool seeded = false}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TranslateLanguageSheet(
          initial: initial,
          seededFromAppLocale: seeded,
        ),
      ),
    );
  }

  /// Language rows currently BUILT, in render order, by endonym. The list is
  /// lazy, so this is the visible window — not the whole catalogue.
  List<String> rowsInOrder(WidgetTester t) => t
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => (tile.title! as Text).data!)
      .toList();

  /// Every row, gathered by scrolling the lazy list to the end.
  Future<List<String>> allRows(WidgetTester t) async {
    final seen = <String>[];
    for (var i = 0; i < 40; i++) {
      for (final r in rowsInOrder(t)) {
        if (seen.isEmpty || !seen.contains(r)) seen.add(r);
      }
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pump();
      if (seen.length >= TranslationLanguage.all.length) break;
    }
    return seen;
  }

  testWidgets('the current language is pinned first, ahead of catalogue order',
      (t) async {
    final gujarati = TranslationLanguage.fromCode('gu');
    await t.pumpWidget(host(gujarati));
    await t.pump();

    final rows = rowsInOrder(t);
    expect(rows.first, gujarati.nativeName);
    // English leads the catalogue but must not lead the list here.
    expect(rows[1], isNot(gujarati.nativeName));
  });

  testWidgets('the pinned language appears exactly once — not duplicated '
      'in the catalogue below it', (t) async {
    final gujarati = TranslationLanguage.fromCode('gu');
    await t.pumpWidget(host(gujarati));
    await t.pump();

    final rows = await allRows(t);
    expect(rows.where((r) => r == gujarati.nativeName), hasLength(1));
    expect(rows, hasLength(TranslationLanguage.all.length));
  });

  testWidgets('order stays put when a different language is tapped — the '
      'list must not jump under the finger', (t) async {
    final gujarati = TranslationLanguage.fromCode('gu');
    await t.pumpWidget(host(gujarati));
    await t.pump();
    final before = rowsInOrder(t);

    await t.tap(find.text(TranslationLanguage.fromCode('hi').nativeName));
    await t.pump();

    expect(rowsInOrder(t), before);
  });

  testWidgets('the app-locale hint shows on first run only', (t) async {
    final hindi = TranslationLanguage.fromCode('hi');

    await t.pumpWidget(host(hindi, seeded: true));
    await t.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.textContaining(l10n.translateSheetSettingsHint), findsOneWidget);

    // Once the user has chosen, calling it "your app language" is a lie.
    await t.pumpWidget(host(hindi));
    await t.pump();
    expect(find.textContaining(l10n.translateSheetSettingsHint), findsNothing);
  });

  testWidgets('confirming returns the tapped language, not the initial one',
      (t) async {
    TranslationLanguage? result;
    final hindi = TranslationLanguage.fromCode('hi');
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              result = await TranslateLanguageSheet.show(
                ctx,
                initial: TranslationLanguage.fromCode('gu'),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    await t.tap(find.text(hindi.nativeName));
    await t.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await t.tap(find.widgetWithText(UniunButton, l10n.translateSheetAction));
    await t.pumpAndSettle();

    expect(result?.code, 'hi');
  });
}
