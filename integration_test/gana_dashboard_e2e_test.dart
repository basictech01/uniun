import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/models/gana_run_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/gana_usecases.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/features/brahma/manas/pages/manas_form_page.dart';
import 'package:uniun/features/shiv/gana/detail/pages/gana_detail_page.dart';
import 'package:uniun/features/shiv/gana/dashboard/pages/gana_dashboard_page.dart';
import 'package:uniun/features/shiv/gana/form/pages/gana_form_page.dart';
import 'package:uniun/features/shiv/gana/form/bloc/gana_form_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/fixtures.dart';

const _holdSeconds = int.fromEnvironment('HOLD_SECONDS');

/// Covers Gana scope selection, Manas creation, draft retention, and run views.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late UserRepository users;
  UserKeyEntity? previousUser;
  late UserKeyEntity testUser;

  setUpAll(() async {
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    if (!getIt.isRegistered<Isar>()) await configureDependencies();
    isar = getIt<Isar>();
    users = getIt<UserRepository>();
    previousUser = (await users.getActiveUser()).fold<UserKeyEntity?>(
      (_) => null,
      (u) => u,
    );
    testUser = (await users.importKey(kTestPrivHex)).getOrElse(
      () => throw StateError('Could not activate the shared test identity'),
    );
  });

  tearDownAll(() async {
    if (previousUser != null && previousUser!.pubkeyHex != testUser.pubkeyHex) {
      final restored = await users.importKey(previousUser!.nsec);
      expect(restored.isRight(), isTrue);
    }
  });

  GoRouter ganaRouter() => GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const GanaDashboardPage(),
      ),
      GoRoute(
        name: AppRoutes.shivGanaForm,
        path: '/gana/form',
        builder: (_, state) {
          final args = state.extra as Map<String, Object?>?;
          return GanaFormPage(ganaId: args?['ganaId'] as String?);
        },
      ),
      GoRoute(
        name: AppRoutes.shivGanaDetail,
        path: '/gana/:ganaId',
        builder: (_, state) =>
            GanaDetailPage(ganaId: state.pathParameters['ganaId']!),
      ),
      GoRoute(
        name: AppRoutes.brahmaManasForm,
        path: '/brahma/manas/form',
        builder: (_, __) => const ManasFormPage(),
      ),
    ],
  );

  Future<void> removeGanasNamed(String name) async {
    final result = await getIt<GetGanasUseCase>().call();
    final ids = result.fold(
      (_) => <String>[],
      (items) =>
          items.where((g) => g.name == name).map((g) => g.ganaId).toList(),
    );
    for (final id in ids) {
      await getIt<DeleteGanaUseCase>().call(id);
    }
  }

  Future<void> revealInGanaForm(WidgetTester tester, Finder target) async {
    final scrollable = find
        .descendant(
          of: find.byType(GanaFormPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(target, 220, scrollable: scrollable);
    await tester.pumpAndSettle();
    final bottom = tester.getRect(find.byType(GanaFormPage)).bottom;
    final targetBottom = tester.getRect(target).bottom;
    if (targetBottom > bottom - 130) {
      await tester.drag(scrollable, Offset(0, -(targetBottom - bottom + 210)));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'Brahma scope saves a Gana with no Manas and appears on dashboard',
    (tester) async {
      const ganaName = 'E2E Brahma Gana 262';
      final router = ganaRouter();
      try {
        await removeGanasNamed(ganaName);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();
        final newButton = find
            .ancestor(of: find.text('New'), matching: find.byType(TextButton))
            .first;
        await tester.tap(newButton);
        await tester.pumpAndSettle();
        expect(find.byType(GanaFormPage), findsOneWidget);
        final save = find.ancestor(
          of: find.text('Save'),
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        await tester.enterText(find.byType(TextField).first, ganaName);
        await tester.enterText(
          find.byType(TextField).at(1),
          'Summarize Brahma',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(save).onPressed, isNull);

        final preset = find.text('Once, when I enable it');
        await revealInGanaForm(tester, preset);
        await tester.tap(preset);
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
        await tester.tap(save);
        await tester.pumpAndSettle();

        final result = await getIt<GetGanasUseCase>().call();
        final saved = result.fold(
          (_) => throw StateError('Could not load saved Gana'),
          (items) => items.singleWhere((g) => g.name == ganaName),
        );
        expect(saved.manasIds, isEmpty);
        expect(saved.taskPrompt, 'Summarize Brahma');
        expect(saved.enabled, isFalse);
        expect(find.text(ganaName), findsWidgets);
        expect(find.text('Brahma'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await removeGanasNamed(ganaName);
      }
    },
  );

  testWidgets(
    'creating a Manas from a new Gana keeps its draft and adds the picker choice',
    (tester) async {
      const ganaName = 'Draft Gana 262';
      const manasName = 'E2E Gana new Manas 262';
      final getManases = getIt<GetManasListUseCase>();
      final deleteManas = getIt<DeleteManasUseCase>();
      final router = ganaRouter();

      Future<void> removeCreatedManas() async {
        final result = await getManases.call();
        final manases = result.fold(
          (_) => <String>[],
          (items) => items
              .where((m) => m.name == manasName)
              .map((m) => m.manasId)
              .toList(),
        );
        for (final id in manases) {
          await deleteManas.call(id);
        }
      }

      try {
        await removeCreatedManas();
        await removeGanasNamed(ganaName);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();
        final newButton = find
            .ancestor(of: find.text('New'), matching: find.byType(TextButton))
            .first;
        await tester.tap(newButton);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, ganaName);
        await tester.enterText(
          find.byType(TextField).at(1),
          'Summarize the notes',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final originalId = BlocProvider.of<GanaFormBloc>(
          tester.element(find.text('New Gana')),
        ).state.ganaId;
        expect(
          BlocProvider.of<GanaFormBloc>(
            tester.element(find.text('New Gana')),
          ).state.manases,
          isEmpty,
        );
        final create = find.text('Create Manas');
        await revealInGanaForm(tester, create.first);
        expect(
          find.ancestor(of: create, matching: find.byType(FilledButton)),
          findsOneWidget,
        );
        await tester.tap(create.first);
        await tester.pumpAndSettle();

        expect(find.byType(ManasFormPage), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, manasName);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(GanaFormPage), findsOneWidget);
        expect(find.text('New Gana'), findsOneWidget);
        expect(find.text('Gana not found'), findsNothing);
        expect(find.text(manasName), findsOneWidget);
        final returned = BlocProvider.of<GanaFormBloc>(
          tester.element(find.text('New Gana')),
        ).state;
        expect(returned.ganaId, originalId);
        expect(returned.name, ganaName);
        expect(returned.taskPrompt, 'Summarize the notes');
        expect(returned.status, GanaFormStatus.ready);
        expect(find.text('Brahma'), findsOneWidget);
        await revealInGanaForm(tester, find.text(manasName));
        await tester.tap(find.text(manasName));
        await tester.pumpAndSettle();
        final newManasChip = find.ancestor(
          of: find.text(manasName),
          matching: find.byType(FilterChip),
        );
        expect(tester.widget<FilterChip>(newManasChip).selected, isTrue);
        final chosenId = returned.manases
            .singleWhere((m) => m.name == manasName)
            .manasId;
        final preset = find.text('Once, when I enable it');
        await revealInGanaForm(tester, preset);
        await tester.tap(preset);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final result = await getIt<GetGanasUseCase>().call();
        final saved = result.fold(
          (_) => throw StateError('Could not load saved Gana'),
          (items) => items.singleWhere((g) => g.name == ganaName),
        );
        expect(saved.ganaId, originalId);
        expect(saved.manasIds, [chosenId]);
        expect(saved.taskPrompt, 'Summarize the notes');
        expect(saved.enabled, isFalse);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await removeGanasNamed(ganaName);
        await removeCreatedManas();
      }
    },
  );

  testWidgets(
    'editing a Gana keeps its draft through cancel and Manas creation',
    (tester) async {
      const ganaId = 'e2e-gana-262-edit';
      const ganaName = 'E2E Edit Gana 262';
      const initialManasId = 'e2e-gana-262-initial';
      const initialManasName = 'E2E Initial Manas 262';
      const newManasName = 'E2E Added Manas 262';
      final router = ganaRouter();
      final getManases = getIt<GetManasListUseCase>();
      final deleteManas = getIt<DeleteManasUseCase>();

      Future<String?> createdManasId() async {
        final result = await getManases.call();
        return result.fold<String?>(
          (_) => null,
          (items) => items
              .where((m) => m.name == newManasName)
              .map((m) => m.manasId)
              .firstOrNull,
        );
      }

      Future<void> cleanup() async {
        await getIt<DeleteGanaUseCase>().call(ganaId);
        final createdId = await createdManasId();
        if (createdId != null) await deleteManas.call(createdId);
        await deleteManas.call(initialManasId);
      }

      try {
        await cleanup();
        final manasResult = await getIt<UpsertManasUseCase>().call(
          aManas(manasId: initialManasId, name: initialManasName),
        );
        expect(manasResult.isRight(), isTrue);
        final ganaResult = await getIt<UpsertGanaUseCase>().call(
          aGana(
            ganaId: ganaId,
            name: ganaName,
            manasIds: const [initialManasId],
            taskPrompt: 'Keep this instruction',
            triggerMode: GanaTriggerMode.oneShot,
          ),
        );
        expect(ganaResult.isRight(), isTrue);

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();
        router.pushNamed(
          AppRoutes.shivGanaDetail,
          pathParameters: {'ganaId': ganaId},
        );
        await tester.pumpAndSettle();
        expect(find.byType(GanaDetailPage), findsOneWidget);
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        GanaFormState formState() => BlocProvider.of<GanaFormBloc>(
          tester.element(find.text('Edit · $ganaName')),
        ).state;
        expect(formState().isEditMode, isTrue);
        expect(formState().selectedManasId, initialManasId);
        expect(formState().name, ganaName);
        expect(formState().taskPrompt, 'Keep this instruction');
        final create = find.text('Create Manas');
        await revealInGanaForm(tester, create.first);
        expect(
          find.ancestor(of: create, matching: find.byType(ActionChip)),
          findsOneWidget,
        );

        await tester.tap(create.first);
        await tester.pumpAndSettle();
        expect(find.byType(ManasFormPage), findsOneWidget);
        await tester.tap(find.byType(UniunBackButton));
        await tester.pumpAndSettle();
        expect(formState().ganaId, ganaId);
        expect(formState().selectedManasId, initialManasId);
        expect(formState().name, ganaName);

        await tester.tap(create.first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, newManasName);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.byType(GanaFormPage), findsOneWidget);
        expect(formState().ganaId, ganaId);
        expect(formState().selectedManasId, initialManasId);
        expect(formState().name, ganaName);
        expect(formState().taskPrompt, 'Keep this instruction');
        expect(find.text('Gana not found'), findsNothing);
        final addedId = await createdManasId();
        expect(addedId, isNotNull);
        expect(formState().manases.any((m) => m.manasId == addedId), isTrue);

        await revealInGanaForm(tester, find.text(newManasName));
        await tester.tap(find.text(newManasName));
        await tester.pumpAndSettle();
        expect(formState().selectedManasId, addedId);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        final afterManas = await getIt<GetGanaByIdUseCase>().call(ganaId);
        expect(afterManas.fold((_) => null, (g) => g.manasIds), [addedId]);

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        await revealInGanaForm(tester, find.text('Brahma'));
        await tester.tap(find.text('Brahma'));
        await tester.pumpAndSettle();
        expect(formState().selectedManasId, isNull);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        final afterBrahma = await getIt<GetGanaByIdUseCase>().call(ganaId);
        expect(afterBrahma.fold((_) => null, (g) => g.manasIds), isEmpty);
        expect(find.text('Brahma'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await cleanup();
      }
    },
  );

  testWidgets('the dashboard shows seeded Gana numbers and recent runs', (
    tester,
  ) async {
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
