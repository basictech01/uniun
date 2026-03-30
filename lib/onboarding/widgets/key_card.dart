import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Card displaying a Nostr key (npub or nsec) with copy + optional reveal toggle.
class KeyCard extends StatelessWidget {
  const KeyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.keyValue,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isSecret,
    required this.isVisible,
    required this.onToggle,
    required this.isCopied,
    required this.onCopy,
    this.warning,
  });

  final String title;
  final String subtitle;
  final String keyValue;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isSecret;
  final bool isVisible;
  final VoidCallback? onToggle;
  final bool isCopied;
  final VoidCallback onCopy;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final display =
        (isSecret && !isVisible) ? '• • • • • • • • • • • •' : keyValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isSecret && !isVisible
                          ? AppColors.onSurfaceVariant
                          : AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onToggle != null)
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      isVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isCopied ? null : onCopy,
                  child: isCopied
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 14,
                                color:
                                    AppColors.primary.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              'Copied',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COPY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(warning!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onErrorContainer,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder shown in place of the private key card until the public key is copied.
class PrivKeyHint extends StatelessWidget {
  const PrivKeyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.lock_rounded,
                color: AppColors.outlineVariant, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Copy your public key above to reveal your private key.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
