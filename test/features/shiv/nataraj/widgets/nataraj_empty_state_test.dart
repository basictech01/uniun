import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/features/shiv/nataraj/bloc/nataraj_bloc.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_empty_state.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: the call-to-action shows for needs-more-notes and exhausted and
/// calls back when tapped; other statuses draw nothing.
void main() {
  Widget host(NatarajStatus status, VoidCallback onAdd) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: NatarajEmptyState(status: status, onAddNotes: onAdd),
    ),
  );

  for (final s in [NatarajStatus.needsMoreNotes, NatarajStatus.exhausted]) {
    testWidgets('${s.name}: the button calls onAddNotes', (t) async {
      var taps = 0;
      await t.pumpWidget(host(s, () => taps++));

      await t.tap(find.byType(UniunButton));

      expect(taps, 1);
    });
  }

  testWidgets('ready draws no button', (t) async {
    await t.pumpWidget(host(NatarajStatus.ready, () {}));

    expect(find.byType(UniunButton), findsNothing);
  });
}
