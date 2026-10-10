// Covers Brahma's note A → note B selection and Manas membership on a device.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/note_card/note_card_menu.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_node_panel.dart';
import 'package:uniun/features/brahma/manas/widgets/manas_membership_sheet.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/fixtures.dart';

const _manasId = 'e2e-manas-issue-261';
const _noteA = 'e2e-manas-issue-261-a';
const _noteB = 'e2e-manas-issue-261-b';

GraphNodeData _node(String id) => GraphNodeData(
  eventId: id,
  content: id == _noteA ? 'Brahma note A' : 'Brahma note B',
  eTagRefs: const [],
  type: GraphNodeType.saved,
  authorPubkey: kAlicePub,
  created: DateTime(2026, 1, 1),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
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
    final selected = ValueNotifier<GraphNodeData>(_node(_noteA));

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
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<GraphBloc>(
            create: (_) => getIt<GraphBloc>(),
            child: Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => selected.value = _node(_noteB),
                    child: const Text('Open note B'),
                  ),
                  Expanded(
                    child: ValueListenableBuilder<GraphNodeData>(
                      valueListenable: selected,
                      builder: (_, node, __) =>
                          GraphNodePanel(node: node, onClose: () {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> openMembership() async {
        await tester.tap(find.byType(NoteCardMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add to Manas'));
        await tester.pumpAndSettle();
        expect(find.byType(ManasMembershipSheet), findsOneWidget);
      }

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
      await tester.tap(find.text('Open note B'));
      await tester.pumpAndSettle();
      expect(find.text('Brahma note B'), findsOneWidget);

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
      selected.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await cleanup();
    }
  });
}
