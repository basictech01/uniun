import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
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
    testWidgets('says why in words, not the enum name', (t) async {
      await show(
        t,
        aGanaRun(
          status: GanaRunStatus.skipped,
        ).copyWith(skipReason: GanaSkipReason.noActiveModel),
      );

      expect(find.textContaining('No AI model is active'), findsOneWidget);
      expect(find.text('noActiveModel'), findsNothing);
    });
  });

  testWidgets('a running run is a plain row with nothing to open', (t) async {
    await show(t, aGanaRun(status: GanaRunStatus.running));

    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.textContaining('Running'), findsOneWidget);
  });
}
