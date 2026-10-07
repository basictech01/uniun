import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_outcome_bar.dart';

/// GanaOutcomeBar: each outcome gets a visible, proportional segment.
void main() {
  Future<void> show(WidgetTester t, GanaOutcomeBar bar) => t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 300, child: bar)),
    ),
  );

  Iterable<Size> segments(WidgetTester t) => t
      .widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(GanaOutcomeBar),
          matching: find.byType(ColoredBox),
        ),
      )
      .map((w) => t.getSize(find.byWidget(w)));

  testWidgets('draws one 6px-high segment per outcome, sized by count', (
    t,
  ) async {
    await show(t, const GanaOutcomeBar(succeeded: 3, failed: 1, skipped: 0));

    final sizes = segments(t).toList();
    expect(sizes, hasLength(2));
    expect(sizes.map((s) => s.height), everyElement(6));
    expect(sizes[0].width, closeTo(225, 0.5));
    expect(sizes[1].width, closeTo(75, 0.5));
  });

  testWidgets('a Gana that has not run shows one empty track', (t) async {
    await show(t, const GanaOutcomeBar(succeeded: 0, failed: 0, skipped: 0));

    final sizes = segments(t).toList();
    expect(sizes, hasLength(1));
    expect((sizes.single.width, sizes.single.height), (300, 6));
  });
}
