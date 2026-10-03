import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/features/brahma/graph/painters/graph_painter.dart';

/// Covers: GraphPainter drawing solid nodes (links never show through them,
/// even faded), links of a visible, zoom-independent thickness, the selection's
/// links in the accent colour, and a label for every node.
void main() {
  setUpAll(() {
    registerFallbackValue(Paint());
    registerFallbackValue(Path());
    registerFallbackValue(Offset.zero);
  });

  PaintedNode node(Offset c, {double opacity = 1, bool selected = false}) =>
      PaintedNode(
        center: c,
        radius: 24,
        color: Colors.blue,
        label: 'note',
        opacity: opacity,
        isSelected: selected,
      );

  GraphPainter painter(
    List<PaintedNode> nodes, {
    double zoom = 1,
    bool hasSelection = false,
  }) => GraphPainter(
    nodes: nodes,
    links: const [(0, 1)],
    zoom: zoom,
    restColor: Colors.grey,
    highlightColor: Colors.red,
    labelColor: Colors.black,
    hasSelection: hasSelection,
    isSearching: false,
    backdrop: Colors.white,
  );

  test('a faded node is still opaque, so the link behind it is hidden', () {
    final canvas = _MockCanvas();

    painter([
      node(const Offset(0, 0), opacity: 0.2),
      node(const Offset(200, 0)),
    ]).paint(canvas, const Size(400, 400));

    final fills = verify(
      () => canvas.drawCircle(any(), 24, captureAny()),
    ).captured.cast<Paint>();
    expect(fills, isNotEmpty);
    expect(
      fills.every((p) => p.color.a == 1),
      isTrue,
      reason: 'blended onto the backdrop, not left translucent',
    );
  });

  test('links keep the same on-screen thickness whatever the zoom', () {
    for (final zoom in [0.25, 1.0, 4.0]) {
      final canvas = _MockCanvas();

      painter([
        node(Offset.zero),
        node(const Offset(100, 0)),
      ], zoom: zoom).paint(canvas, const Size(400, 400));

      final paints = verify(
        () => canvas.drawPath(any(), captureAny()),
      ).captured.cast<Paint>();
      expect(paints.first.strokeWidth, closeTo(kLinkWidth / zoom, 1e-4));
      expect(
        paints.first.strokeWidth * zoom,
        greaterThanOrEqualTo(1.5),
        reason: 'visible, not a hairline',
      );
    }
  });

  test('the selected node\'s links are drawn in the accent colour', () {
    final canvas = _MockCanvas();

    painter([
      node(Offset.zero, selected: true),
      node(const Offset(100, 0)),
    ], hasSelection: true).paint(canvas, const Size(400, 400));

    final paints = verify(
      () => canvas.drawPath(any(), captureAny()),
    ).captured.cast<Paint>();
    expect(paints.any((p) => p.color.r > 0.9 && p.color.g < 0.4), isTrue);
  });

  test('links off the selection fade right back', () {
    final canvas = _MockCanvas();

    painter([
      node(Offset.zero),
      node(const Offset(100, 0)),
    ], hasSelection: true).paint(canvas, const Size(400, 400));

    final rest = verify(
      () => canvas.drawPath(any(), captureAny()),
    ).captured.cast<Paint>().first;
    expect(rest.color.a, closeTo(0.25, 0.01));
  });
}

class _MockCanvas extends Mock implements Canvas {}
