import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// Caller's choice when a publish target carries unpublished draft references.
///
/// [PublishChainChoice.cancel] is returned when the user dismisses the sheet
/// (taps outside / back). Callers should not publish on cancel.
enum PublishChainChoice { only, chain, cancel }

/// Bottom-sheet shown right before publishing a draft that still has
/// unpublished `draftRefIds`. The published Kind-1 cannot retroactively
/// reference notes that don't exist yet — see [docs/brahma/draft_links.md] —
/// so we ask explicitly:
///
/// - [PublishChainChoice.chain] (default-highlighted): walks the dependency
///   closure, publishes leaves first, rewrites UUIDs into real event ids on
///   the parent's `e` tags. Link survives on Nostr.
/// - [PublishChainChoice.only]: drop the draft refs from this note's tags.
///   The other drafts stay where they are; the published note has no link.
///
/// [draftCount] is the number of unpublished drafts this note references
/// (used in the body copy).
Future<PublishChainChoice> showPublishChainSheet(
  BuildContext context, {
  required int draftCount,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showModalBottomSheet<PublishChainChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.brahmaPublishChainTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.brahmaPublishChainSubtitle(draftCount),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _PublishModeTile(
              icon: Icons.account_tree_rounded,
              title: l10n.brahmaPublishChain,
              subtitle: l10n.brahmaPublishChainBody(draftCount),
              recommended: true,
              onTap: () => Navigator.pop(ctx, PublishChainChoice.chain),
            ),
            const SizedBox(height: 10),
            _PublishModeTile(
              icon: Icons.bolt_rounded,
              title: l10n.brahmaPublishOnlyThis,
              subtitle: l10n.brahmaPublishOnlyThisSubtitle,
              onTap: () => Navigator.pop(ctx, PublishChainChoice.only),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? PublishChainChoice.cancel;
}

class _PublishModeTile extends StatelessWidget {
  const _PublishModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: recommended
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: recommended
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : context.custom.borderSubtle,
            width: recommended ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.aiModelRecommendedBadge.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
