import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_outcome_bar.dart';
import 'package:uniun/features/shiv/gana/list/bloc/gana_list_bloc.dart';
import 'package:uniun/features/shiv/gana/utils/gana_formatters.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One Gana on the dashboard: on/off switch, outcome bar, lifetime counts and
/// the last run. Tapping it opens the Gana's detail page.
class GanaDashboardRow extends StatelessWidget {
  const GanaDashboardRow({super.key, required this.gana, required this.lastRun});

  final GanaEntity gana;
  final GanaRunEntity? lastRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final percent = ganaSuccessPercent(
      succeeded: gana.runsSucceeded,
      failed: gana.runsFailed,
    );
    final br = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: br,
        border: Border.all(color: context.custom.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: () => context.pushNamed(
            AppRoutes.shivGanaDetail,
            pathParameters: {'ganaId': gana.ganaId},
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gana.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (percent != null)
                      Text(
                        l10n.ganaDashboardRate(percent),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Switch(
                      value: gana.enabled,
                      onChanged: (v) => context.read<GanaListBloc>().add(
                            GanaListToggleEnabledEvent(gana.ganaId, v),
                          ),
                      activeThumbColor: Colors.white,
                      activeTrackColor: colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GanaOutcomeBar(
                    succeeded: gana.runsSucceeded,
                    failed: gana.runsFailed,
                    skipped: gana.runsSkipped,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _MetaLine(
                      icon: ganaTriggerIcon(gana),
                      value: ganaTriggerSummary(gana, l10n),
                    ),
                    _MetaLine(
                      icon: Icons.hub_rounded,
                      value: ganaScopeLabel(gana, l10n),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.ganaStatsCounts(
                    gana.runsSucceeded,
                    gana.runsFailed,
                    gana.runsSkipped,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lastRun == null
                      ? l10n.ganaTileLastRunNever
                      : '${ganaRunStatusLabel(lastRun!.status, l10n)} · '
                          '${ganaRelativeWhen(lastRun!.startedAt, l10n)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: lastRun == null
                        ? colorScheme.onSurfaceVariant
                        : ganaRunColor(context, lastRun!.status),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
