import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_activity_tile.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_dashboard_row.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_empty_state.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_stat_tile.dart';
import 'package:uniun/features/shiv/gana/list/bloc/gana_list_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// How many runs the recent-activity section lists, newest first.
const int _kActivityLimit = 10;

/// Overview of every Gana: how many are on, lifetime done / failed / skipped,
/// the ones whose last run failed, each Gana's numbers, and the latest runs.
/// Shares [GanaListBloc] with the list, so it refreshes as the engine runs.
class GanaDashboardPage extends StatelessWidget {
  const GanaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GanaListBloc>()..add(const GanaListLoadEvent()),
      child: const _GanaDashboardView(),
    );
  }
}

class _GanaDashboardView extends StatelessWidget {
  const _GanaDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: UniunBackButton(onPressed: () => Navigator.of(context).pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.shivGanaForm),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.ganaListNew),
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: const StadiumBorder(),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        title: Text(
          l10n.ganaDashboardTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<GanaListBloc, GanaListState>(
        builder: (context, state) {
          if (state.status == GanaListStatus.loading ||
              state.status == GanaListStatus.initial) {
            return const Center(child: DropLoadingIndicator());
          }
          if (state.ganas.isEmpty) return const GanaEmptyState();

          final names = {for (final g in state.ganas) g.ganaId: g.name};
          final active = state.ganas.where((g) => g.enabled).length;
          final done = state.ganas.fold<int>(0, (n, g) => n + g.runsSucceeded);
          final failed = state.ganas.fold<int>(0, (n, g) => n + g.runsFailed);
          final skipped = state.ganas.fold<int>(0, (n, g) => n + g.runsSkipped);

          final attention = <GanaRunEntity>[
            for (final g in state.ganas)
              if (state.lastRuns[g.ganaId]?.status == GanaRunStatus.failed)
                state.lastRuns[g.ganaId]!,
          ];
          final activity = [for (final runs in state.recentRuns.values) ...runs]
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: GanaStatTile(
                      value: '$active/${state.ganas.length}',
                      label: l10n.ganaDashboardActive,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GanaStatTile(
                      value: '$done',
                      label: l10n.ganaDashboardDone,
                      color: context.custom.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GanaStatTile(
                      value: '$failed',
                      label: l10n.ganaDashboardFailed,
                      color: failed > 0
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GanaStatTile(
                      value: '$skipped',
                      label: l10n.ganaDashboardSkipped,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (attention.isNotEmpty) ...[
                _SectionTitle(l10n.ganaDashboardAttentionTitle),
                for (final run in attention)
                  GanaActivityTile(
                    ganaName: names[run.ganaId] ?? '',
                    run: run,
                    showError: true,
                  ),
              ],
              _SectionTitle(l10n.ganaDashboardGanasTitle),
              for (final g in state.ganas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GanaDashboardRow(
                    gana: g,
                    lastRun: state.lastRuns[g.ganaId],
                  ),
                ),
              _SectionTitle(l10n.ganaDashboardActivityTitle),
              if (activity.isEmpty)
                Text(
                  l10n.ganaDashboardActivityEmpty,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final run in activity.take(_kActivityLimit))
                  GanaActivityTile(ganaName: names[run.ganaId] ?? '', run: run),
              const SizedBox(height: 16),
              Text(
                l10n.ganaDashboardFootnote,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
