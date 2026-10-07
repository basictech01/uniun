// Real-device look at the Gana dashboard: seeds a few Ganas and runs into the
// app's Isar, opens the page with real DI, checks the numbers on screen, then
// removes only the rows it added. Hold the screen open to look at it:
//   flutter test integration_test/gana_dashboard_e2e_test.dart \
//     --dart-define=HOLD_SECONDS=60

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/models/gana_run_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/features/shiv/gana/detail/pages/gana_detail_page.dart';
import 'package:uniun/features/shiv/gana/dashboard/pages/gana_dashboard_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

const _holdSeconds = int.fromEnvironment('HOLD_SECONDS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the dashboard shows seeded Gana numbers and recent runs', (
    tester,
  ) async {
    await configureDependencies();
    final isar = getIt<Isar>();
    final now = DateTime.now();

    final ganas = [
      ('Life Lessons Replier', true, 42, 3, 11),
      ('Morning Digest', true, 12, 0, 0),
      ('Group Summariser', false, 0, 5, 2),
    ];
    final runs = [
      ('e2e-g0', GanaRunStatus.succeeded, 4, null),
      ('e2e-g1', GanaRunStatus.succeeded, 35, null),
      ('e2e-g2', GanaRunStatus.failed, 90, 'Native engine closed mid-run'),
    ];

    await isar.writeTxn(() async {
      for (var i = 0; i < ganas.length; i++) {
        final (name, on, ok, bad, skipped) = ganas[i];
        await isar.ganaModels.put(
          GanaModel()
            ..ganaId = 'e2e-g$i'
            ..name = name
            ..manasIds = const []
            ..taskPrompt = 't'
            ..outputType = GanaOutputType.feed
            ..triggerMode = GanaTriggerMode.recurring
            ..enabled = on
            ..runsSucceeded = ok
            ..runsFailed = bad
            ..runsSkipped = skipped
            ..createdAt = now
            ..updatedAt = now,
        );
      }
      for (var i = 0; i < runs.length; i++) {
        final (ganaId, status, minutesAgo, error) = runs[i];
        await isar.ganaRunModels.put(
          GanaRunModel()
            ..runId = 'e2e-r$i'
            ..ganaId = ganaId
            ..startedAt = now.subtract(Duration(minutes: minutesAgo))
            ..status = status
            ..error = error,
        );
      }
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GanaDashboardPage(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('NEEDS ATTENTION'), findsOneWidget);
      expect(find.text('Native engine closed mid-run'), findsWidgets);
      expect(find.text('42 done · 3 failed · 11 skipped'), findsOneWidget);

      if (_holdSeconds > 0) {
        await tester.pump(const Duration(seconds: _holdSeconds));
      }
    } finally {
      await isar.writeTxn(() async {
        await isar.ganaModels.filter().ganaIdStartsWith('e2e-').deleteAll();
        await isar.ganaRunModels.filter().ganaIdStartsWith('e2e-').deleteAll();
      });
    }
  });

  testWidgets('a Gana run opens to the note it wrote and the reason it failed', (
    tester,
  ) async {
    await configureDependencies();
    final isar = getIt<Isar>();
    final now = DateTime.now();

    await isar.writeTxn(() async {
      await isar.ganaModels.put(
        GanaModel()
          ..ganaId = 'e2e-g0'
          ..name = 'Life Lessons Replier'
          ..manasIds = const []
          ..taskPrompt = 't'
          ..outputType = GanaOutputType.feed
          ..triggerMode = GanaTriggerMode.recurring
          ..runsSucceeded = 1
          ..runsFailed = 1
          ..runsSkipped = 1
          ..createdAt = now
          ..updatedAt = now,
      );
      await isar.noteModels.put(
        NoteModel(
          eventId: 'e2e-note-1',
          sig: '',
          authorPubkey: 'e2e',
          content:
              'Small habits compound.\nShow up today, even for five minutes.',
          type: NoteType.text,
          eTagRefs: const [],
          pTagRefs: const [],
          tTags: const [],
          created: now,
        ),
      );
      for (final r in [
        ('e2e-r0', GanaRunStatus.succeeded, 4, null, 'e2e-note-1'),
        (
          'e2e-r1',
          GanaRunStatus.failed,
          40,
          'SocketException: Failed host lookup: api.uniun.in',
          null,
        ),
        ('e2e-r2', GanaRunStatus.skipped, 90, null, null),
      ]) {
        await isar.ganaRunModels.put(
          GanaRunModel()
            ..runId = r.$1
            ..ganaId = 'e2e-g0'
            ..startedAt = now.subtract(Duration(minutes: r.$3))
            ..status = r.$2
            ..error = r.$4
            ..outputEventId = r.$5
            ..skipReason = r.$2 == GanaRunStatus.skipped
                ? GanaSkipReason.noNewInput
                : null
            ..inputEventIds = r.$2 == GanaRunStatus.succeeded
                ? const ['a', 'b']
                : const [],
        );
      }
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GanaDetailPage(ganaId: 'e2e-g0'),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // The first two runs, newest first: the published note, then the failure.
      await tester.tap(find.text('Failed · 40m ago'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Succeeded · 4m ago'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Small habits compound.'), findsOneWidget);
      expect(find.text('Network problem'), findsWidgets);
      expect(find.textContaining('Failed host lookup'), findsOneWidget);

      if (_holdSeconds > 0) {
        await tester.pump(const Duration(seconds: _holdSeconds));
      }
    } finally {
      await isar.writeTxn(() async {
        await isar.ganaModels.filter().ganaIdStartsWith('e2e-').deleteAll();
        await isar.ganaRunModels.filter().ganaIdStartsWith('e2e-').deleteAll();
        await isar.noteModels.filter().eventIdStartsWith('e2e-').deleteAll();
      });
    }
  });
}
