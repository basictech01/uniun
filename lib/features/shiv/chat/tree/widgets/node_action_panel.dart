import 'package:flutter/material.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/drop_icon.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/core/utils/formatters.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

class NodeActionPanel extends StatelessWidget {
  const NodeActionPanel({
    super.key,
    required this.message,
    required this.messageCount,
    required this.isActiveBranch,
    required this.onDismiss,
    required this.onOpenBranch,
  });

  final ShivMessageEntity message;
  final int messageCount;
  final bool isActiveBranch;
  final VoidCallback onDismiss;
  final VoidCallback onOpenBranch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUser = message.role == MessageRole.user;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header: active badge + time + message count
          Row(
            children: [
              if (isActiveBranch) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    l10n.shivActiveBranch,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                formatTimeAgo(message.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.shivNodeMessages(messageCount),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Role icon + content preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.surfaceContainerHigh
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isUser
                    ? Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : DropIcon(
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.content.isEmpty ? '…' : message.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Open Branch — switches to this branch and returns to chat
          SizedBox(
            width: double.infinity,
            child: UniunButton(
              height: 52,
              borderRadius: 20,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: l10n.shivNodeOpenBranch,
              onPressed: onOpenBranch,
            ),
          ),
        ],
      ),
    );
  }
}
