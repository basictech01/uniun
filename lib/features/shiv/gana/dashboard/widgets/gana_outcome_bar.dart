import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// Thin stacked bar of how a Gana's runs ended: done, failed, skipped.
/// An empty track when it has not run yet.
class GanaOutcomeBar extends StatelessWidget {
  const GanaOutcomeBar({
    super.key,
    required this.succeeded,
    required this.failed,
    required this.skipped,
  });

  final int succeeded;
  final int failed;
  final int skipped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = succeeded + failed + skipped;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: total == 0
            ? ColoredBox(color: colorScheme.outlineVariant.withValues(alpha: 0.4))
            : Row(
                // Without stretch the empty segments collapse to zero height.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (succeeded > 0)
                    Expanded(
                      flex: succeeded,
                      child: ColoredBox(color: context.custom.success),
                    ),
                  if (failed > 0)
                    Expanded(
                      flex: failed,
                      child: ColoredBox(color: colorScheme.error),
                    ),
                  if (skipped > 0)
                    Expanded(
                      flex: skipped,
                      child: ColoredBox(color: colorScheme.outlineVariant),
                    ),
                ],
              ),
      ),
    );
  }
}
