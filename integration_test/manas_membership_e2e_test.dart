// Covers Brahma's note A → note B selection and Manas membership on a device.
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/note_card/note_card_menu.dart';
import 'package:uniun/common/widgets/safe_interactive_viewer.dart';
import 'package:uniun/common/widgets/floating_nav.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/brahma/graph/pages/graph_page.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_canvas.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_node_panel.dart';
import 'package:uniun/features/brahma/manas/widgets/manas_membership_sheet.dart';
import 'package:uniun/features/home/pages/home_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/fixtures.dart';

const _manasId = 'e2e-manas-issue-261';
const _noteA = 'e2e-manas-issue-261-a';
const _noteB = 'e2e-manas-issue-261-b';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    if (!getIt.isRegistered<Isar>()) await configureDependencies();
  });

  testWidgets('Brahma adds note A and then note B to the same Manas', (
    tester,
  ) async {
    final isar = getIt<Isar>();
    final upsert = getIt<UpsertManasUseCase>();
    final delete = getIt<DeleteManasUseCase>();
    final byId = getIt<GetManasByIdUseCase>();
    final members = getIt<GetManasIdsForNoteUseCase>();
    final notes = getIt<GetNoteIdsForManasUseCase>();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          name: AppRoutes.home,
          path: '/home',
          builder: (_, __) => const HomePage(),
        ),
        GoRoute(
          name: AppRoutes.graph,
          path: '/graph',
          builder: (_, __) => const GraphPage(),
        ),
      ],
    );

    Future<void> cleanup() async {
      await delete.call(_manasId);
      await isar.writeTxn(() async {
        await isar.savedNoteModels.filter().eventIdEqualTo(_noteA).deleteAll();
        await isar.savedNoteModels.filter().eventIdEqualTo(_noteB).deleteAll();
      });
    }

    try {
      await cleanup();
      await upsert.call(
        ManasEntity(
          manasId: _manasId,
          name: 'Issue 261 Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final save = getIt<SaveNoteUseCase>();
      for (final id in [_noteA, _noteB]) {
        final result = await save.call(
          aNote(
            id: id,
            authorPubkey: kAlicePub,
            content: id == _noteA ? 'Brahma note A' : 'Brahma note B',
          ),
        );
        expect(result.isRight(), isTrue);
      }

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
      expect(find.byType(FloatingNav), findsOneWidget);
      final nav = tester.getRect(find.byType(FloatingNav));
      await tester.tapAt(Offset(nav.center.dx, nav.top + 28));
      await tester.pumpAndSettle();
      expect(find.byType(GraphCanvas), findsOneWidget);

      Offset nodeScreenPosition(String id) {
        final canvas = tester.getRect(find.byType(GraphCanvas));
        final state = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
        final camera = tester
            .widget<Transform>(
              find.descendant(
                of: find.byType(SafeInteractiveViewer),
                matching: find.byType(Transform),
              ),
            )
            .transform;
        return canvas.topLeft +
            MatrixUtils.transformPoint(camera, state.nodeCentre(id)!);
      }

      Future<void> openNote(String id) async {
        await tester.tapAt(nodeScreenPosition(id));
        await tester.pumpAndSettle();
        expect(find.byType(GraphNodePanel), findsOneWidget);
        expect(
          find.text(id == _noteA ? 'Brahma note A' : 'Brahma note B'),
          findsOneWidget,
        );
      }

      Future<void> openMembership() async {
        await tester.tap(find.byType(NoteCardMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add to Manas'));
        await tester.pumpAndSettle();
        expect(find.byType(ManasMembershipSheet), findsOneWidget);
      }

      await openNote(_noteA);
      await openMembership();
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
      await tester.tap(find.text('Issue 261 Work'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(
        (await byId.call(_manasId)).getOrElse(() => throw 'missing').noteCount,
        1,
      );
      expect((await members.call(_noteA)).getOrElse(() => []), [_manasId]);
      expect((await members.call(_noteB)).getOrElse(() => []), isEmpty);

      Navigator.of(tester.element(find.byType(ManasMembershipSheet))).pop();
      await tester.pumpAndSettle();
      await openNote(_noteB);

      await openMembership();
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
      expect(find.text('1 note'), findsOneWidget);
      await tester.tap(find.text('Issue 261 Work'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('2 notes'), findsOneWidget);
      expect(
        (await byId.call(_manasId)).getOrElse(() => throw 'missing').noteCount,
        2,
      );
      expect((await notes.call(_manasId)).getOrElse(() => []).toSet(), {
        _noteA,
        _noteB,
      });
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await cleanup();
    }
  });
}
