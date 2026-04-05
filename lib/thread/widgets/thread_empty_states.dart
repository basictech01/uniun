import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_theme.dart';

class ThreadEmptyReplies extends StatelessWidget {
  const ThreadEmptyReplies({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline_rounded,
            size: 52, color: AppColors.outlineVariant),
        const SizedBox(height: 16),
        Text(
          l10n.threadNoReplies,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.threadBeFirstToReply,
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class ThreadNoReferences extends StatelessWidget {
  const ThreadNoReferences({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_tree_outlined,
            size: 52, color: AppColors.outlineVariant),
        const SizedBox(height: 16),
        Text(
          l10n.threadNoReferences,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.threadNoReferencesDetail,
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ThreadReferenceItem extends StatelessWidget {
  const ThreadReferenceItem({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${eventId.substring(0, 12)}…',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.outlineVariant),
        ],
      ),
    );
  }
}

class ThreadErrorBody extends StatelessWidget {
  const ThreadErrorBody({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
