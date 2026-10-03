import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How one node looks this frame.
class PaintedNode {
  const PaintedNode({
    required this.center,
    required this.radius,
    required this.color,
    required this.label,
    this.opacity = 1,
    this.isSelected = false,
    this.isConnected = false,
    this.isMatch = false,
  });

  final Offset center;
  final double radius;
  final Color color;
  final String label;
  final double opacity;
  final bool isSelected;
  final bool isConnected;
  final bool isMatch;
}

/// How far into the zoom range a label has faded in: 0 hidden, 1 fully shown.
///
/// Obsidian hides every label until the view is zoomed past a threshold. Here a
/// node's size counts too — a hub is worth naming sooner than a leaf — and a
/// graph small enough not to clutter shows every label at once.
double labelOpacity({
  required double zoom,
  required double radius,
  required int nodeCount,
  bool emphasised = false,
}) {
  if (emphasised || nodeCount <= kAlwaysLabelledNodes) return 1;
  return ((zoom * radius - 9) / 12).clamp(0.0, 1.0);
}

/// Link thickness in screen pixels: thick enough to see at a glance, thin enough
/// that a crowd of them does not blot out the nodes. Constant at any zoom.
const double kLinkWidth = 1.8;
const double kLitLinkWidth = 3.0;

/// Graphs up to this many nodes show every label whatever the zoom.
const int kAlwaysLabelledNodes = 25;

/// Draws the whole graph — links, nodes, labels — in one pass.
///
/// One painter instead of a widget per node: a frame is a handful of canvas
/// calls however many nodes there are, and links are batched into two paths.
/// Links keep one on-screen thickness at any zoom ([kLinkWidth]); the selected
/// node's links light up thicker and the rest fade, as in Obsidian's hover.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.nodes,
    required this.links,
    required this.zoom,
    required this.restColor,
    required this.highlightColor,
    required this.labelColor,
    required this.hasSelection,
    required this.isSearching,
    required this.backdrop,
    this.fadeLabels = false,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final List<PaintedNode> nodes;

  /// Link ends as indexes into [nodes].
  final List<(int, int)> links;
  final double zoom;
  final Color restColor;
  final Color highlightColor;
  final Color labelColor;
  final bool hasSelection;
  final bool isSearching;

  /// The canvas colour. A node is blended onto it so its fill is solid — a
  /// translucent circle would show the links running behind it.
  final Color backdrop;

  /// When true, labels fade in with zoom (see [labelOpacity]); otherwise every
  /// node is always named.
  final bool fadeLabels;

  static final Map<String, TextPainter> _labels = {};

  @override
  void paint(Canvas canvas, Size size) {
    _paintLinks(canvas);
    for (final n in nodes) {
      _paintNode(canvas, n);
    }
    for (final n in nodes) {
      _paintLabel(canvas, n);
    }
  }

  void _paintLinks(Canvas canvas) {
    final rest = Path();
    final lit = Path();
    var anyRest = false, anyLit = false;
    for (final (a, b) in links) {
      final from = nodes[a], to = nodes[b];
      final onSelection =
          (from.isSelected || to.isSelected) ||
          (from.isConnected && to.isSelected) ||
          (to.isConnected && from.isSelected);
      final path = onSelection ? lit : rest;
      if (onSelection) {
        anyLit = true;
      } else {
        anyRest = true;
      }
      path
        ..moveTo(from.center.dx, from.center.dy)
        ..lineTo(to.center.dx, to.center.dy);
    }
    final width = kLinkWidth / zoom;
    final faded = isSearching ? 0.2 : (hasSelection ? 0.25 : 0.8);
    if (anyRest) {
      canvas.drawPath(
        rest,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = restColor.withValues(alpha: faded),
      );
    }
    if (anyLit) {
      canvas.drawPath(
        lit,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kLitLinkWidth / zoom
          ..color = highlightColor.withValues(alpha: 0.9),
      );
    }
  }

  void _paintNode(Canvas canvas, PaintedNode n) {
    final fill = Paint()
      ..color = Color.alphaBlend(
        n.color.withValues(
          alpha:
              n.opacity *
              (n.isSelected || n.isConnected || n.isMatch ? 1 : 0.85),
        ),
        backdrop,
      );
    if (n.isSelected || n.isMatch) {
      canvas.drawCircle(
        n.center,
        n.radius + 4,
        Paint()
          ..color = n.color.withValues(alpha: 0.55 * n.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    } else if (n.isConnected) {
      canvas.drawCircle(
        n.center,
        n.radius + 1,
        Paint()
          ..color = n.color.withValues(alpha: 0.3 * n.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawCircle(n.center, n.radius, fill);
    if (n.isSelected || n.isMatch) {
      canvas.drawCircle(
        n.center,
        n.radius - 1.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: 0.7 * n.opacity),
      );
    }
  }

  void _paintLabel(Canvas canvas, PaintedNode n) {
    final emphasised = n.isSelected || n.isConnected || n.isMatch;
    final shown =
        (fadeLabels
            ? labelOpacity(
                zoom: zoom,
                radius: n.radius,
                nodeCount: nodes.length,
                emphasised: emphasised,
              )
            : 1.0) *
        n.opacity;
    if (shown < 0.05 || n.label.isEmpty) return;
    // Quantised so a fading label reuses a cached layout instead of laying
    // text out afresh every frame.
    final bucket = (shown * 4).round().clamp(1, 4);
    final strong = n.isSelected || n.isMatch;
    final key = '${n.label}|$bucket|$strong|${n.color.toARGB32()}';
    final tp = _labels.putIfAbsent(key, () {
      if (_labels.length > 600) _labels.clear();
      return TextPainter(
        text: TextSpan(
          text: n.label,
          style: TextStyle(
            fontSize: fadeLabels ? 11 : 10,
            height: 1.15,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            color: (strong ? n.color : labelColor).withValues(
              alpha: bucket / 4,
            ),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 92);
    });
    // Constant screen size: counter-scale so text neither balloons nor shrinks
    // with zoom, which is what keeps zoomed-out labels from piling up.
    final s = fadeLabels ? 1 / math.max(zoom, 0.6) : 1.0;
    canvas.save();
    canvas.translate(n.center.dx, n.center.dy + n.radius + 5 * s);
    canvas.scale(s);
    tp.paint(canvas, Offset(-tp.width / 2, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(GraphPainter old) => true;
}
