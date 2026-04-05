import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Reference graph preview shown below the compose card.
/// Renders a static dot-grid background + dynamic SVG graph
/// that updates as the user adds hashtags / references.
class GraphPreviewCard extends StatelessWidget {
  const GraphPreviewCard({super.key, this.hashtags = const []});

  final List<String> hashtags;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Row(
          children: [
            Text(
              l10n.brahmaGraphPreviewLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.hub_rounded,
              size: 18,
              color: AppColors.outline.withValues(alpha: 0.6),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Graph canvas ───────────────────────────────────────────────────
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Dot-grid background
                Positioned.fill(
                  child: CustomPaint(painter: _DotGridPainter()),
                ),

                // Dynamic graph SVG
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GraphPainter(hashtags: hashtags),
                  ),
                ),

                // "Interactive Preview" chip
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.outlineVariant
                            .withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.06),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.brahmaInteractivePreview,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dot grid background painter ───────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    const step = 24.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ── Dynamic graph painter ─────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  _GraphPainter({required this.hashtags});
  final List<String> hashtags;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Centre node (the new note)
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // Static seed nodes matching the design (always visible)
    final seedNodes = <Offset>[
      Offset(size.width * 0.25, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width * 0.375, size.height * 0.75),
      Offset(size.width * 0.625, size.height * 0.15),
    ];

    // Draw lines from center to seed nodes
    for (final node in seedNodes) {
      canvas.drawLine(center, node, linePaint);
    }

    // Extra nodes for each hashtag, arranged in a circle
    if (hashtags.isNotEmpty) {
      final angleStep = (2 * math.pi) / hashtags.length;
      for (int i = 0; i < hashtags.length; i++) {
        final angle = angleStep * i - math.pi / 2;
        final radius = math.min(size.width, size.height) * 0.32;
        final tagNode = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawLine(center, tagNode, linePaint);
        nodePaint.color = AppColors.primary.withValues(alpha: 0.55);
        canvas.drawCircle(tagNode, 4.5, nodePaint);
      }
    }

    // Draw seed nodes
    final seedSizes = [6.0, 5.0, 4.0, 4.0];
    for (int i = 0; i < seedNodes.length; i++) {
      nodePaint.color = AppColors.primary.withValues(alpha: 0.35);
      canvas.drawCircle(seedNodes[i], seedSizes[i], nodePaint);
    }

    // Center node (highlighted)
    nodePaint.color = AppColors.primary.withValues(alpha: 0.75);
    canvas.drawCircle(center, 8, nodePaint);
  }

  @override
  bool shouldRepaint(_GraphPainter old) => old.hashtags != hashtags;
}
