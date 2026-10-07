import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/features/shiv/gana/utils/gana_formatters.dart';
import 'package:uniun/features/shiv/gana/utils/gana_run_error.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One run in a Gana's history, as a drop-down: the header says how it ended
/// and when, and opening it shows what the run actually produced — the note it
/// published, the reason it failed in plain words (raw error underneath), or
/// why it was skipped.
class GanaRunTile extends StatefulWidget {
  const GanaRunTile({super.key, required this.run, this.output});

  final GanaRunEntity run;

  /// The note this run published, when it is still on this device.
  final NoteEntity? output;

  @override
  State<GanaRunTile> createState() => _GanaRunTileState();
}

class _GanaRunTileState extends State<GanaRunTile> {
  bool _expanded = false;

  GanaRunEntity get run => widget.run;
  NoteEntity? get output => widget.output;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final color = ganaRunColor(context, run.status);
    final summary = _summary(l10n);
    final body = _body(context, l10n);

    final header = Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${ganaRunStatusLabel(run.status, l10n)} · '
                '${ganaRelativeWhen(run.startedAt, l10n)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              // Opening the tile shows the same thing in full, so drop the line.
              if (summary != null && !_expanded)
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (body == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: header,
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 0, 12),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        onExpansionChanged: (open) => setState(() => _expanded = open),
        title: header,
        children: [body],
      ),
    );
  }

  /// One line shown under the header while the tile is closed.
  String? _summary(AppLocalizations l10n) {
    switch (run.status) {
      case GanaRunStatus.succeeded:
        final text = output?.content.trim();
        if (text == null || text.isEmpty) return null;
        return text.split('\n').first;
      case GanaRunStatus.failed:
        final error = run.error;
        return error == null || error.isEmpty
            ? null
            : GanaRunError.parse(error).title(l10n);
      case GanaRunStatus.skipped:
        return _skipExplanation(l10n);
      case GanaRunStatus.running:
        return null;
    }
  }

  String? _skipExplanation(AppLocalizations l10n) => switch (run.skipReason) {
    GanaSkipReason.noActiveModel => l10n.ganaSkipNoActiveModel,
    GanaSkipReason.modelMismatch => l10n.ganaSkipModelMismatch,
    GanaSkipReason.noNewInput => l10n.ganaSkipNoNewInput,
    GanaSkipReason.modelSwapped => l10n.ganaSkipModelSwapped,
    GanaSkipReason.noopReturned => l10n.ganaSkipNoopReturned,
    GanaSkipReason.maxOutputsReached => l10n.ganaSkipMaxOutputs,
    GanaSkipReason.cloudUnavailable => l10n.ganaSkipCloudUnavailable,
    null => null,
  };

  /// What opening the tile shows; null when there is nothing to open.
  Widget? _body(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant);
    final when =
        '${MaterialLocalizations.of(context).formatMediumDate(run.startedAt.toLocal())}, '
        '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(run.startedAt.toLocal()))}';
    final read = run.inputEventIds.isEmpty
        ? null
        : l10n.ganaRunInputCount(run.inputEventIds.length);
    final footer = [when, ?read].join(' · ');

    switch (run.status) {
      case GanaRunStatus.succeeded:
        if (run.outputEventId == null) return null;
        final note = output;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(context, l10n.ganaRunOutputLabel),
            if (note == null)
              Text(l10n.ganaRunOutputMissing, style: muted)
            else ...[
              _Boxed(child: SelectableText(note.content)),
              if (note.kind == kNoteKind || note.kind == kGroupMessageKind)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.pushNamed(
                      AppRoutes.thread,
                      pathParameters: {'noteId': note.id},
                    ),
                    child: Text(l10n.ganaRunOpenNote),
                  ),
                ),
            ],
            const SizedBox(height: 6),
            Text(footer, style: muted),
          ],
        );
      case GanaRunStatus.failed:
        final raw = run.error;
        if (raw == null || raw.isEmpty) return null;
        final error = GanaRunError.parse(raw);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.title(l10n),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.hint(l10n),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _label(context, l10n.ganaRunTechnicalDetail),
            _Boxed(
              child: SelectableText(
                error.raw,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 6),
            Text(footer, style: muted),
          ],
        );
      case GanaRunStatus.skipped:
        final why = _skipExplanation(l10n);
        if (why == null) return null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              why,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(footer, style: muted),
          ],
        );
      case GanaRunStatus.running:
        return null;
    }
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _Boxed extends StatelessWidget {
  const _Boxed({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.custom.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.custom.border),
      ),
      child: child,
    );
  }
}
