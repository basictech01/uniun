import 'package:flutter/material.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// "just now" / "5m ago" / "3h ago" / "2d ago", then an ISO date after a week.
String ganaRelativeWhen(DateTime t, AppLocalizations l10n) {
  final delta = DateTime.now().difference(t);
  if (delta.inSeconds < 60) return l10n.ganaRelativeJustNow;
  if (delta.inMinutes < 60) return l10n.ganaRelativeMinutes(delta.inMinutes);
  if (delta.inHours < 24) return l10n.ganaRelativeHours(delta.inHours);
  if (delta.inDays < 7) return l10n.ganaRelativeDays(delta.inDays);
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}

Color ganaRunColor(BuildContext context, GanaRunStatus s) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (s) {
    GanaRunStatus.succeeded => colorScheme.primary,
    GanaRunStatus.skipped => colorScheme.onSurfaceVariant,
    GanaRunStatus.failed => colorScheme.error,
    GanaRunStatus.running => colorScheme.primary,
  };
}

String ganaRunStatusLabel(GanaRunStatus s, AppLocalizations l10n) =>
    switch (s) {
      GanaRunStatus.succeeded => l10n.ganaRunStatusSucceeded,
      GanaRunStatus.skipped => l10n.ganaRunStatusSkipped,
      GanaRunStatus.failed => l10n.ganaRunStatusFailed,
      GanaRunStatus.running => l10n.ganaRunStatusRunning,
    };

/// Share of finished runs that succeeded, as a whole percent. Skipped runs
/// are left out — a Gana that waits for input skips a lot and is not failing.
/// Null when it has neither succeeded nor failed yet.
int? ganaSuccessPercent({required int succeeded, required int failed}) {
  final total = succeeded + failed;
  return total == 0 ? null : (succeeded * 100 / total).round();
}

String ganaTriggerSummary(GanaEntity g, AppLocalizations l10n) {
  if (g.triggerMode == GanaTriggerMode.oneShot) {
    return g.inputType == null
        ? l10n.ganaTileTriggerOnceOnEnable
        : l10n.ganaTileTriggerOnceOnInput;
  }
  final reactive = g.triggerReactive;
  final interval = g.triggerIntervalMinutes;
  if (reactive && interval != null) return l10n.ganaTileTriggerBoth(interval);
  if (reactive) return l10n.ganaTileTriggerReactive;
  if (interval != null) return l10n.ganaTileTriggerInterval(interval);
  return '—';
}

IconData ganaTriggerIcon(GanaEntity g) =>
    (g.triggerReactive && g.triggerMode != GanaTriggerMode.oneShot)
    ? Icons.bolt_rounded
    : Icons.schedule_rounded;

String ganaScopeLabel(GanaEntity g, AppLocalizations l10n) => g.manasIds.isEmpty
    ? l10n.ganaListScopeAll
    : l10n.ganaListScopeCount(g.manasIds.length);
