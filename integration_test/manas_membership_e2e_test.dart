// Covers Manas membership from Brahma, Vishnu, thread, and both group feeds on a device.
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
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/followed_user_model.dart';
import 'package:uniun/data/models/group_model.dart';
import 'package:uniun/data/models/private_group_model.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/brahma/graph/pages/graph_page.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_canvas.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_node_panel.dart';
import 'package:uniun/features/brahma/manas/widgets/manas_membership_sheet.dart';
import 'package:uniun/features/home/pages/home_page.dart';
import 'package:uniun/features/thread/pages/thread_page.dart';
import 'package:uniun/features/groups/feed/pages/group_feed_page.dart';
import 'package:uniun/features/private_groups/detail/pages/private_group_detail_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/fixtures.dart';
import '../test/_helpers/isar_seeds.dart';
import '../test/_helpers/isar_test_harness.dart'
    show groupSeed, privateGroupSeed, followedUserSeed;

const _manasId = 'e2e-manas-issue-261';
const _noteA = 'e2e-manas-issue-261-a';
const _noteB = 'e2e-manas-issue-261-b';
const _surfaceGroupId = 'e2e-manas-issue-261-group';
const _surfaceAuthor =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

enum _Surface { vishnu, thread, group, privateGroup }

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  UserKeyEntity? previousUser;
  late String testPubkey;

  setUpAll(() async {
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    if (!getIt.isRegistered<Isar>()) await configureDependencies();
    final users = getIt<UserRepository>();
    previousUser = (await users.getActiveUser()).fold((_) => null, (u) => u);
    final testUser = (await users.importKey(kTestPrivHex)).getOrElse(
      () => throw StateError('Could not activate the shared test identity'),
    );
    testPubkey = testUser.pubkeyHex;
  });

  tearDownAll(() async {
    final previous = previousUser;
    if (previous != null && previous.pubkeyHex != testPubkey) {
      final restored = await getIt<UserRepository>().importKey(previous.nsec);
      expect(restored.isRight(), isTrue);
    }
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

  Future<void> verifySurface(WidgetTester tester, _Surface surface) async {
    final isar = getIt<Isar>();
    final id = 'e2e-manas-issue-261-${surface.name}';
    final manasId = '$id-manas';
    final content = 'Manas ${surface.name} note';
    final isGroup = surface == _Surface.group;
    final isPrivateGroup = surface == _Surface.privateGroup;
    final router = GoRouter(
      initialLocation: isGroup
          ? '/group/$_surfaceGroupId'
          : isPrivateGroup
          ? '/private-group/$_surfaceGroupId'
          : '/home',
      routes: [
        GoRoute(
          name: AppRoutes.home,
          path: '/home',
          builder: (_, __) => const HomePage(),
        ),
        GoRoute(
          name: AppRoutes.thread,
          path: '/thread/:noteId',
          builder: (_, state) =>
              ThreadPage(noteId: state.pathParameters['noteId']!),
        ),
        GoRoute(
          name: AppRoutes.groupDetail,
          path: '/group/:groupId',
          builder: (_, state) =>
              GroupFeedPage(groupId: state.pathParameters['groupId']!),
        ),
        GoRoute(
          name: AppRoutes.privateGroupDetail,
          path: '/private-group/:groupId',
          builder: (_, state) =>
              PrivateGroupDetailPage(groupId: state.pathParameters['groupId']!),
        ),
      ],
    );

    Future<void> cleanup() async {
      await getIt<DeleteManasUseCase>().call(manasId);
      await isar.writeTxn(() async {
        await isar.noteModels.filter().eventIdEqualTo(id).deleteAll();
        await isar.unreadNoteModels.filter().eventIdEqualTo(id).deleteAll();
        await isar.savedNoteModels.filter().eventIdEqualTo(id).deleteAll();
        if (isGroup) {
          await isar.groupModels
              .filter()
              .groupIdEqualTo(_surfaceGroupId)
              .deleteAll();
        } else if (isPrivateGroup) {
          await isar.privateGroupModels
              .filter()
              .groupIdEqualTo(_surfaceGroupId)
              .deleteAll();
        } else {
          await isar.followedUserModels
              .filter()
              .pubkeyHexEqualTo(_surfaceAuthor)
              .deleteAll();
        }
      });
    }

    try {
      await cleanup();
      await getIt<UpsertManasUseCase>().call(
        ManasEntity(
          manasId: manasId,
          name: 'Surface Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await isar.writeTxn(() async {
        await isar.noteModels.put(
          noteRow(
            id,
            content: content,
            authorPubkey: _surfaceAuthor,
            kind: isGroup
                ? kGroupMessageKind
                : isPrivateGroup
                ? kPrivateGroupKind
                : kNoteKind,
            groupId: isGroup ? _surfaceGroupId : null,
            privateGroupId: isPrivateGroup ? _surfaceGroupId : null,
            created: DateTime.now(),
          ),
        );
        if (isGroup) {
          await isar.groupModels.put(groupSeed(_surfaceGroupId));
        } else if (isPrivateGroup) {
          await isar.privateGroupModels.put(
            privateGroupSeed(_surfaceGroupId)..adminPubkey = testPubkey,
          );
        } else {
          await isar.followedUserModels.put(followedUserSeed(_surfaceAuthor));
          await isar.unreadNoteModels.put(
            unreadRow(
              id,
              authorPubkey: _surfaceAuthor,
              created: DateTime.now(),
            ),
          );
        }
      });

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
      expect(find.text(content), findsOneWidget);

      if (surface == _Surface.thread) {
        await tester.tap(find.text(content));
        await tester.pumpAndSettle();
        expect(find.byType(ThreadPage), findsOneWidget);
        expect(find.text(content), findsOneWidget);
      }

      await tester.tap(find.byType(NoteCardMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Manas'));
      await tester.pumpAndSettle();
      expect(find.byType(ManasMembershipSheet), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
      await tester.tap(find.text('Surface Work'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('1 note'), findsOneWidget);
      expect(
        (await getIt<GetManasByIdUseCase>().call(
          manasId,
        )).getOrElse(() => throw 'missing').noteCount,
        1,
      );
      expect(
        (await getIt<GetManasIdsForNoteUseCase>().call(id)).getOrElse(() => []),
        [manasId],
      );
      expect(await isar.savedNoteModels.filter().eventIdEqualTo(id).count(), 1);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await cleanup();
    }
  }

  testWidgets(
    'Vishnu feed menu saves and adds a note to Manas',
    (tester) => verifySurface(tester, _Surface.vishnu),
  );

  testWidgets(
    'thread menu saves and adds its root note to Manas',
    (tester) => verifySurface(tester, _Surface.thread),
  );

  testWidgets(
    'public group menu saves and adds its message to Manas',
    (tester) => verifySurface(tester, _Surface.group),
  );

  testWidgets(
    'private group menu saves and adds its message to Manas',
    (tester) => verifySurface(tester, _Surface.privateGroup),
  );
}
