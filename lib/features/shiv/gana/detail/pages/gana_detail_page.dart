import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/usecases/gana_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_outcome_bar.dart';
import 'package:uniun/features/shiv/gana/dashboard/widgets/gana_stat_tile.dart';
import 'package:uniun/features/shiv/gana/detail/widgets/gana_run_tile.dart';
import 'package:uniun/features/shiv/gana/utils/gana_formatters.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Lightweight read-only detail page — name + summary + recent runs.
/// The Edit button hands off to [GanaFormPage] for actual changes; this
/// page deliberately does not own form state.
class GanaDetailPage extends StatefulWidget {
  const GanaDetailPage({super.key, required this.ganaId});
  final String ganaId;

  @override
  State<GanaDetailPage> createState() => _GanaDetailPageState();
}

class _GanaDetailPageState extends State<GanaDetailPage> {
  GanaEntity? _gana;
  List<GanaRunEntity> _runs = const [];
  Map<String, NoteEntity> _outputs = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ganaRes = await getIt<GetGanaByIdUseCase>().call(widget.ganaId);
    final runsRes = await getIt<GetGanaRunsUseCase>().call(widget.ganaId);
    final runs = runsRes.fold<List<GanaRunEntity>>((_) => const [], (l) => l);
    // The notes the runs published, so a run can show what it wrote.
    final outputIds = [
      for (final r in runs)
        if (r.outputEventId != null) r.outputEventId!,
    ];
    final notesRes = await getIt<ResolveNotesByIdsUseCase>().call(outputIds);
    final notes = notesRes.fold<List<NoteEntity>>((_) => const [], (l) => l);
    if (!mounted) return;
    setState(() {
      _gana = ganaRes.fold<GanaEntity?>((_) => null, (g) => g);
      _runs = runs;
      _outputs = {for (final n in notes) n.id: n};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final g = _gana;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: UniunBackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          g?.name ?? l10n.ganaFormEditTitleFallback,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: Theme.of(context).colorScheme.primary,
            onPressed: g == null
                ? null
                : () async {
                    final changed = await context.pushNamed<bool>(
                      AppRoutes.shivGanaForm,
                      extra: {'ganaId': g.ganaId},
                    );
                    if (changed == true && mounted) _load();
                  },
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: DropLoadingIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : g == null
              ? Center(
                  child: Text(
                  l10n.ganaFormEditTitleFallback,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _StatsCard(gana: g),
                    const SizedBox(height: 12),
                    _StatusRow(gana: g),
                    const SizedBox(height: 24),
                    Text(
                      l10n.ganaFormRunsSectionTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_runs.isEmpty)
                      Text(
                        l10n.ganaFormRunsEmpty,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                    else
                      for (final r in _runs)
                        GanaRunTile(
                          key: ValueKey(r.runId),
                          run: r,
                          output: _outputs[r.outputEventId],
                        ),
                  ],
                ),
    );
  }
}

/// Lifetime done / failed / skipped for this Gana, with the outcome bar.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.gana});
  final GanaEntity gana;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final percent = ganaSuccessPercent(
      succeeded: gana.runsSucceeded,
      failed: gana.runsFailed,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GanaStatTile(
                  value: '${gana.runsSucceeded}',
                  label: l10n.ganaDashboardDone,
                  color: context.custom.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GanaStatTile(
                  value: '${gana.runsFailed}',
                  label: l10n.ganaDashboardFailed,
                  color: gana.runsFailed > 0
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GanaStatTile(
                  value: '${gana.runsSkipped}',
                  label: l10n.ganaDashboardSkipped,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GanaOutcomeBar(
            succeeded: gana.runsSucceeded,
            failed: gana.runsFailed,
            skipped: gana.runsSkipped,
          ),
          if (percent != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.ganaDashboardRate(percent),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.gana});
  final GanaEntity gana;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(context, 'Enabled', gana.enabled ? 'Yes' : 'No'),
          _kv(context, l10n.ganaDetailManasesLabel,
              gana.manasIds.length.toString()),
          _kv(context, 'Input',
              gana.inputType?.name ?? 'standalone (interval-only)'),
          _kv(context, 'Output', gana.outputType.name),
          _kv(context, 'Mode',
              gana.triggerMode == GanaTriggerMode.oneShot ? 'one-shot' : 'recurring'),
          // Interval is meaningless in one-shot — the engine ignores it.
          // Hide it so the UI matches the engine's actual behavior.
          if (gana.triggerMode == GanaTriggerMode.recurring &&
              gana.triggerIntervalMinutes != null)
            _kv(context, 'Interval', '${gana.triggerIntervalMinutes}m'),
          if (gana.triggerReactive) _kv(context, 'Reactive', 'on'),
          if (gana.triggerMode == GanaTriggerMode.recurring &&
              gana.maxOutputs != null)
            _kv(context, 'Max notes', gana.maxOutputs!.toString()),
          if (gana.lastRunAt != null)
            _kv(context, 'Last run', gana.lastRunAt!.toLocal().toString()),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                  fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
