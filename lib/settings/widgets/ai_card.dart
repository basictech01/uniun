import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_theme.dart';

class AICard extends StatelessWidget {
  const AICard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Model selector row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiSelectModel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiGemma2bRecommended,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: AppColors.onSurfaceVariant),
            ],
          ),

          Divider(
            height: 32,
            color: AppColors.surfaceContainer.withValues(alpha: 0.5),
          ),

          // Clear AI cache
          GestureDetector(
            onTap: () {
              // TODO: clear AI cache
            },
            child: Row(
              children: [
                const Icon(Icons.delete_sweep_rounded,
                    color: Color(0xFFBA1A1A), size: 20),
                const SizedBox(width: 12),
                Text(
                  l10n.aiClearCache,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
