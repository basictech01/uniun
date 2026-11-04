import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/atoms/uniun_button.dart';

/// Covers: every variant renders its label, taps, disabled and loading states,
/// icon/trailing slots, expand vs wrap, long and unicode labels.
void main() {
  Widget host(Widget child, {double width = 400}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: Center(child: child),
        ),
      ),
    ),
  );

  BoxDecoration decorationOf(WidgetTester t) {
    final box = t.widget<Container>(
      find
          .descendant(
            of: find.byType(UniunButton),
            matching: find.byType(Container),
          )
          .first,
    );
    return box.decoration! as BoxDecoration;
  }

  for (final v in UniunButtonVariant.values) {
    testWidgets('${v.name}: shows its label and fires onPressed', (t) async {
      var taps = 0;
      await t.pumpWidget(
        host(UniunButton(label: 'Go', variant: v, onPressed: () => taps++)),
      );

      expect(find.text('Go'), findsOneWidget);
      await t.tap(find.byType(UniunButton));
      expect(taps, 1);
    });

    testWidgets('${v.name}: onPressed null ignores taps', (t) async {
      await t.pumpWidget(
        host(UniunButton(label: 'Go', variant: v, onPressed: null)),
      );

      await t.tap(find.byType(UniunButton));
      expect(
        t.getSemantics(find.byType(UniunButton)),
        isNot(matchesSemantics(isEnabled: true)),
      );
    });
  }

  testWidgets('loading shows a spinner, hides the label, ignores taps', (
    t,
  ) async {
    var taps = 0;
    await t.pumpWidget(
      host(UniunButton(label: 'Go', loading: true, onPressed: () => taps++)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Go'), findsNothing);
    await t.tap(find.byType(UniunButton));
    expect(taps, 0);
  });

  testWidgets(
    'primary: disabled uses the outline colour, enabled the primary',
    (t) async {
      await t.pumpWidget(host(UniunButton(label: 'Go', onPressed: () {})));
      final scheme = Theme.of(t.element(find.byType(UniunButton))).colorScheme;
      expect(decorationOf(t).color, scheme.primary);

      await t.pumpWidget(host(const UniunButton(label: 'Go', onPressed: null)));
      expect(decorationOf(t).color, scheme.outlineVariant);
    },
  );

  testWidgets('hero: gradient, 58 px tall, radius 16', (t) async {
    await t.pumpWidget(
      host(
        UniunButton(
          label: 'Go',
          variant: UniunButtonVariant.hero,
          onPressed: () {},
        ),
      ),
    );

    expect(decorationOf(t).gradient, isNotNull);
    expect(t.getSize(find.byType(UniunButton)).height, 58);
    expect(decorationOf(t).borderRadius, BorderRadius.circular(16));
  });

  testWidgets('primary is 48 px tall; tonal wraps its text (12 + 12 padding)', (
    t,
  ) async {
    await t.pumpWidget(host(UniunButton(label: 'Go', onPressed: () {})));
    expect(t.getSize(find.byType(UniunButton)).height, 48);

    await t.pumpWidget(
      host(
        UniunButton(
          label: 'Go',
          variant: UniunButtonVariant.tonal,
          onPressed: () {},
        ),
      ),
    );
    expect(t.getSize(find.byType(UniunButton)).height, lessThan(48));
  });

  testWidgets('destructive uses the error container', (t) async {
    await t.pumpWidget(
      host(
        UniunButton(
          label: 'Go',
          variant: UniunButtonVariant.destructive,
          onPressed: () {},
        ),
      ),
    );
    final scheme = Theme.of(t.element(find.byType(UniunButton))).colorScheme;

    expect(decorationOf(t).color, scheme.errorContainer);
  });

  testWidgets('icon and trailing show beside the label', (t) async {
    await t.pumpWidget(
      host(
        UniunButton(
          label: 'Go',
          onPressed: () {},
          icon: const Icon(Icons.add),
          trailing: const Icon(Icons.arrow_forward),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('expand false wraps the content; true fills the width', (
    t,
  ) async {
    await t.pumpWidget(
      host(UniunButton(label: 'Go', onPressed: () {}, expand: false)),
    );
    expect(t.getSize(find.byType(UniunButton)).width, lessThan(200));

    await t.pumpWidget(host(UniunButton(label: 'Go', onPressed: () {})));
    expect(t.getSize(find.byType(UniunButton)).width, 400);
  });

  testWidgets('a long label ellipsizes instead of overflowing', (t) async {
    await t.pumpWidget(
      host(UniunButton(label: 'x' * 300, onPressed: () {}), width: 160),
    );

    expect(t.takeException(), isNull);
  });

  testWidgets('unicode, RTL and emoji labels render', (t) async {
    for (final s in ['जारी रखें', 'متابعة', 'Go 🚀']) {
      await t.pumpWidget(host(UniunButton(label: s, onPressed: () {})));
      expect(find.text(s), findsOneWidget);
    }
  });
}
