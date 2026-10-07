import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_stat_tile.dart';

/// GanaStatTile: the number in the colour it is given, with its label.
void main() {
  Future<void> show(WidgetTester t, GanaStatTile tile, {double width = 160}) =>
      t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: tile),
            ),
          ),
        ),
      );

  testWidgets('shows the value in the given colour and the label', (t) async {
    await show(
      t,
      const GanaStatTile(value: '42', label: 'Done', color: Colors.green),
    );

    expect(find.text('Done'), findsOneWidget);
    expect(t.widget<Text>(find.text('42')).style?.color, Colors.green);
  });

  testWidgets('a very large number and a long label do not overflow', (
    t,
  ) async {
    await show(
      t,
      const GanaStatTile(
        value: '9999999999',
        label: 'A really quite long label here',
        color: Colors.red,
      ),
      width: 120,
    );

    expect(t.takeException(), isNull);
  });
}
