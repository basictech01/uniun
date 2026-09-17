import 'package:flutter/material.dart';

/// `‹ 2/7 ›` — walks a cursor through an ordered set of graph nodes, flying the
/// camera to each one. Shared by the two things that produce such a set: search
/// matches (in the header) and the connections of a selected node (in the node
/// panel).
class GraphStepper extends StatelessWidget {
  const GraphStepper({
    super.key,
    required this.current,
    required this.total,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.onStep,
    this.positionLabel,
    this.icon,
  });

  /// 1-based position, or 0 when the cursor has not entered the set yet.
  final int current;
  final int total;
  final String prevTooltip;
  final String nextTooltip;
  final void Function(int delta) onStep;

  /// Pre-formatted `current/total` from l10n.
  final String? positionLabel;

  /// Optional leading glyph naming what is being stepped.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 4),
        ],
        _StepButton(
          icon: Icons.keyboard_arrow_up_rounded,
          tooltip: prevTooltip,
          onPressed: () => onStep(-1),
        ),
        Text(
          positionLabel ?? '$current/$total',
          style: TextStyle(
            fontSize: 13,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: muted,
          ),
        ),
        _StepButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: nextTooltip,
          onPressed: () => onStep(1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: onPressed,
    );
  }
}
