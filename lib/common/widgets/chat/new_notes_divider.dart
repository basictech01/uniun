import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// "New notes" line drawn above the first unread note when a chat opens.
class NewNotesDivider extends StatelessWidget {
  const NewNotesDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = AppLocalizations.of(context)!.newNotesDivider;
    final line = Expanded(
      child: Divider(height: 1, color: scheme.primary.withValues(alpha: 0.4)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}
