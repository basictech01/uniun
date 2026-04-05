import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/shiv/model_select/utils/ai_model_l10n.dart';

class ModelCard extends StatelessWidget {
  const ModelCard({
    super.key,
    required this.model,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
  });

  final AIModelEntity model;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.03)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModelVisual(tier: model.tier, isSelected: isSelected),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                model.modelId.displayName(l10n),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                        .withValues(alpha: 0.15)
                                    : AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                model.sizeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.modelId.description(l10n),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ModelCapabilityChip(
                              label: _optimizationLabel(
                                  l10n, model.optimization),
                              isSelected: isSelected,
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 6),
                              ModelCapabilityChip(
                                label: l10n.aiModelAlreadyActive,
                                isSelected: true,
                                icon: Icons.check_circle_rounded,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (model.isRecommended)
              Positioned(
                top: -1,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.aiModelRecommendedBadge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _optimizationLabel(
      AppLocalizations l10n, AIModelOptimization opt) {
    return switch (opt) {
      AIModelOptimization.cpu => l10n.aiModelOptimizedCpu,
      AIModelOptimization.gpuCpu => l10n.aiModelOptimizedGpuCpu,
      AIModelOptimization.gpu => l10n.aiModelOptimizedGpu,
    };
  }
}

// ── Model visual panel ────────────────────────────────────────────────────────

class ModelVisual extends StatelessWidget {
  const ModelVisual({
    super.key,
    required this.tier,
    required this.isSelected,
  });

  final AIModelTier tier;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final (Color bg, IconData icon) = switch (tier) {
      AIModelTier.lite => (
          AppColors.surfaceContainerHighest,
          Icons.bolt_rounded,
        ),
      AIModelTier.balanced => (
          AppColors.primary.withValues(alpha: 0.15),
          Icons.auto_awesome_rounded,
        ),
      AIModelTier.performance => (
          AppColors.secondaryContainer.withValues(alpha: 0.4),
          Icons.psychology_rounded,
        ),
      AIModelTier.flagship => (
          AppColors.surfaceContainerHigh,
          Icons.rocket_launch_rounded,
        ),
    };

    return Container(
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 28,
          color:
              isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Capability chip ───────────────────────────────────────────────────────────

class ModelCapabilityChip extends StatelessWidget {
  const ModelCapabilityChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
