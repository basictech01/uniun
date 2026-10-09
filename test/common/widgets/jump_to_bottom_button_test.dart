import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/jump_to_bottom_button.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Behaviour guard for the shared jump-to-latest affordance used by the chat
/// surfaces (group feed, private group, DM): it must invoke its callback
/// when shown, and must NOT absorb taps when hidden (so it never blocks the
/// message list underneath).
void main() {
  Widget host({required bool visible, required VoidCallback onPressed}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: JumpToBottomButton(
            visible: visible,
            onPressed: onPressed,
            tooltip: 'Jump to latest',
          ),
        ),
      ),
    );
  }

  testWidgets('renders a down-chevron', (tester) async {
    await tester.pumpWidget(host(visible: true, onPressed: () {}));
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('invokes onPressed when visible and tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(visible: true, onPressed: () => taps++));
    await tester.tap(find.byType(JumpToBottomButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('ignores taps when hidden', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(visible: false, onPressed: () => taps++));
    // visible:false wraps the button in an IgnorePointer, so the tap should
    // fall through without firing the callback (warnIfMissed: the hit is
    // intentionally swallowed).
    await tester.tap(find.byType(JumpToBottomButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  group('unread count badge', () {
    Widget withCount(int n) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: JumpToBottomButton(
            visible: true,
            onPressed: () {},
            unreadCount: n,
          ),
        ),
      ),
    );

    testWidgets('shows nothing at 0', (tester) async {
      await tester.pumpWidget(withCount(0));
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows the number', (tester) async {
      await tester.pumpWidget(withCount(7));
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('caps at 99+', (tester) async {
      await tester.pumpWidget(withCount(150));
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('150'), findsNothing);
    });

    testWidgets('exactly 99 is shown as is', (tester) async {
      await tester.pumpWidget(withCount(99));
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('the badge does not block the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: JumpToBottomButton(
                visible: true,
                onPressed: () => taps++,
                unreadCount: 3,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });
  });
}
