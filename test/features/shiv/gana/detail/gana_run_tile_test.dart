import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/features/shiv/gana/detail/widgets/gana_run_tile.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../../_helpers/fixtures.dart';

/// GanaRunTile: a closed one-line summary per run, and on opening the note it
/// published, the failure in plain words with the raw error, or the skip reason.
void main() {
  Future<void> show(WidgetTester t, GanaRunEntity run, {NoteEntity? output}) =>
      t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GanaRunTile(run: run, output: output),
          ),
        ),
      );

  Future<void> open(WidgetTester t) async {
    await t.tap(find.byType(ExpansionTile));
    await t.pumpAndSettle();
  }

  group('succeeded', () {
    final run = aGanaRun(
      status: GanaRunStatus.succeeded,
    ).copyWith(outputEventId: 'note-1', inputEventIds: const ['a', 'b', 'c']);

    testWidgets('closed, shows the first line of what it published', (t) async {
      await show(t, run, output: aNote(content: 'First line\nSecond line'));

      expect(find.text('First line'), findsOneWidget);
      expect(find.text('Second line'), findsNothing);
    });

    testWidgets('open, shows the whole note and how many messages it read', (
      t,
    ) async {
      await show(t, run, output: aNote(content: 'First line\nSecond line'));
      await open(t);

      expect(find.text('NOTE IT PUBLISHED'), findsOneWidget);
      expect(find.text('First line\nSecond line'), findsOneWidget);
      expect(find.textContaining('Read 3 messages'), findsOneWidget);
      expect(find.text('Open note'), findsOneWidget);
    });

    testWidgets('a note that is gone says so instead of an empty box', (
      t,
    ) async {
      await show(t, run);
      await open(t);

      expect(
        find.text('This note is no longer on this device.'),
        findsOneWidget,
      );
      expect(find.text('Open note'), findsNothing);
    });

    testWidgets('a DM output has no Open note button', (t) async {
      await show(t, run, output: aNote(kind: 14, content: 'private'));
      await open(t);

      expect(find.text('private'), findsOneWidget);
      expect(find.text('Open note'), findsNothing);
    });

    testWidgets('shows Hindi and emoji output unchanged', (t) async {
      await show(t, run, output: aNote(content: 'नमस्ते 🌟'));
      await open(t);

      expect(find.text('नमस्ते 🌟'), findsOneWidget);
    });
  });

  group('failed', () {
    testWidgets('closed, shows the kind of problem, not the raw text', (
      t,
    ) async {
      await show(
        t,
        aGanaRun(
          status: GanaRunStatus.failed,
          error: 'SocketException: Connection refused',
        ),
      );

      expect(find.text('Network problem'), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
    });

    testWidgets('open, explains it and shows the raw error underneath', (
      t,
    ) async {
      await show(
        t,
        aGanaRun(
          status: GanaRunStatus.failed,
          error: 'publish: Failure.errorFailure(message: relay said no)',
        ),
      );
      await open(t);

      expect(find.text("Couldn't publish the note"), findsOneWidget);
      expect(
        find.textContaining('tries again on the next trigger'),
        findsOneWidget,
      );
      expect(find.text('TECHNICAL DETAIL'), findsNothing);
      expect(find.text('Technical detail'), findsOneWidget);
      expect(
        find.text('publish: Failure.errorFailure(message: relay said no)'),
        findsOneWidget,
      );
    });

    testWidgets('a failed run with no message is not expandable', (t) async {
      await show(t, aGanaRun(status: GanaRunStatus.failed));

      expect(find.byType(ExpansionTile), findsNothing);
    });
  });

  group('skipped', () {
    const reasons = {
      GanaSkipReason.noActiveModel: 'No AI model is active. Pick one in Shiv.',
      GanaSkipReason.modelMismatch:
          "The active model isn't the one this Gana is pinned to.",
      GanaSkipReason.noNewInput: 'Nothing new to read.',
      GanaSkipReason.modelSwapped:
          'The model changed mid-run, so this run was cancelled.',
      GanaSkipReason.noopReturned: 'The model chose to stay silent.',
      GanaSkipReason.maxOutputsReached:
          'It reached its max notes and switched itself off.',
      GanaSkipReason.cloudUnavailable:
          "UNIUN Cloud isn't connected, or no cloud model is set.",
    };

    for (final entry in reasons.entries) {
      testWidgets('${entry.key.name} says why in words', (t) async {
        await show(
          t,
          aGanaRun(
            status: GanaRunStatus.skipped,
          ).copyWith(skipReason: entry.key),
        );

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(entry.key.name), findsNothing);
      });
    }

    testWidgets('a skip with no recorded reason is not expandable', (t) async {
      await show(t, aGanaRun(status: GanaRunStatus.skipped));

      expect(find.byType(ExpansionTile), findsNothing);
    });
  });

  testWidgets('Open note opens the published note\'s thread', (t) async {
    final opened = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: GanaRunTile(
              run: aGanaRun().copyWith(outputEventId: 'note-9'),
              output: aNote(id: 'note-9'),
            ),
          ),
        ),
        GoRoute(
          name: AppRoutes.thread,
          path: '/thread/:noteId',
          builder: (_, s) {
            opened.add(s.pathParameters['noteId']!);
            return const Scaffold(body: Text('THREAD PAGE'));
          },
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await open(t);

    await t.tap(find.text('Open note'));
    await t.pumpAndSettle();

    expect(opened, ['note-9']);
  });

  testWidgets('a running run is a plain row with nothing to open', (t) async {
    await show(t, aGanaRun(status: GanaRunStatus.running));

    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.textContaining('Running'), findsOneWidget);
  });
}
