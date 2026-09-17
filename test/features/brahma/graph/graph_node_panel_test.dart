import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_node_panel.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fixtures.dart';

class _MockGraphBloc extends MockBloc<GraphEvent, GraphState>
    implements GraphBloc {}

class _MockNoteCardCubit extends MockCubit<NoteCardState>
    implements NoteCardCubit {}

GraphNodeData _node({GraphNodeType type = GraphNodeType.own}) => GraphNodeData(
      eventId: 'n1',
      content: 'a note',
      eTagRefs: const [],
      type: type,
      authorPubkey: 'me',
      sig: 'sig',
      created: DateTime(2026, 1, 1),
      cachedReplyCount: 3,
    );

/// Covers: the node panel's note tap → thread navigation, and the reload it
/// must fire on return (#197 — replying in the thread creates a note the
/// graph never watches for, so without this the graph shows stale nodes and
/// stale reply counts). Also pins that the reload carries the active Manas
/// scope, that nothing is dispatched while the thread is still open, and that
/// a closed bloc is never touched. Also covers the connection stepper (#208):
/// the no-search way to walk a node's edges.
void main() {
  late _MockGraphBloc bloc;
  late _MockNoteCardCubit cardCubit;

  NoteEntity note() => aNote(id: 'n1', authorPubkey: 'me', content: 'a note');

  setUpAll(() => registerFallbackValue(const LoadGraphEvent()));

  setUp(() async {
    bloc = _MockGraphBloc();
    cardCubit = _MockNoteCardCubit();
    when(() => cardCubit.state).thenReturn(const NoteCardState());
    when(() => cardCubit.note).thenReturn(note());
    when(() => bloc.isClosed).thenReturn(false);

    await GetIt.instance.reset();
    GetIt.instance.registerFactoryParam<NoteCardCubit, NoteEntity, void>(
      (_, __) => cardCubit,
    );
  });

  tearDown(() => GetIt.instance.reset());

  /// Two-route app: the panel at `/`, a stub thread page pushed on tap. The
  /// stub carries a Back button so the test can pop the way a user would.
  Widget host(GraphState state) {
    when(() => bloc.state).thenReturn(state);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider<GraphBloc>.value(
            value: bloc,
            child: Scaffold(
              body: GraphNodePanel(node: _node(), onClose: () {}),
            ),
          ),
        ),
        GoRoute(
          path: '/thread/:noteId',
          name: AppRoutes.thread,
          builder: (ctx, __) => Scaffold(
            body: TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('back'),
            ),
          ),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  /// Every LoadGraphEvent the panel pushed into the bloc, in order.
  List<LoadGraphEvent> loadsOn(_MockGraphBloc b) =>
      verify(() => b.add(captureAny()))
          .captured
          .whereType<LoadGraphEvent>()
          .toList();

  testWidgets('tapping the note pushes the thread route', (t) async {
    await t.pumpWidget(host(const GraphState(status: GraphStatus.loaded)));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();

    expect(find.text('back'), findsOneWidget);
  });

  testWidgets('no graph reload while the thread is still open', (t) async {
    await t.pumpWidget(host(const GraphState(status: GraphStatus.loaded)));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<LoadGraphEvent>())));
  });

  testWidgets('returning from the thread reloads the graph', (t) async {
    await t.pumpWidget(host(const GraphState(status: GraphStatus.loaded)));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();
    await t.tap(find.text('back'));
    await t.pumpAndSettle();

    expect(loadsOn(bloc), hasLength(1));
  });

  testWidgets('the reload carries the active Manas scope, not a bare reload',
      (t) async {
    await t.pumpWidget(host(const GraphState(
      status: GraphStatus.loaded,
      scopedManasId: 'm1',
      scopedManasName: 'Work',
    )));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();
    await t.tap(find.text('back'));
    await t.pumpAndSettle();

    final load = loadsOn(bloc).single;
    expect(load.manasId, 'm1');
    expect(load.manasName, 'Work');
  });

  testWidgets('an unscoped graph reloads unscoped (null scope stays null)',
      (t) async {
    await t.pumpWidget(host(const GraphState(status: GraphStatus.loaded)));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();
    await t.tap(find.text('back'));
    await t.pumpAndSettle();

    final load = loadsOn(bloc).single;
    expect(load.manasId, isNull);
    expect(load.manasName, isNull);
  });

  testWidgets('a bloc closed while the thread was open is not dispatched to',
      (t) async {
    await t.pumpWidget(host(const GraphState(status: GraphStatus.loaded)));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();

    when(() => bloc.isClosed).thenReturn(true);
    await t.tap(find.text('back'));
    await t.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<LoadGraphEvent>())));
  });

  /// State where `n1` is anchored with two connections.
  GraphState anchored({int connectionIndex = -1}) => GraphState(
        status: GraphStatus.loaded,
        nodes: [
          _node(),
          GraphNodeData(
            eventId: 'n2',
            content: 'two',
            eTagRefs: const [],
            type: GraphNodeType.own,
            created: DateTime(2026, 2, 1),
          ),
          GraphNodeData(
            eventId: 'n3',
            content: 'three',
            eTagRefs: const [],
            type: GraphNodeType.own,
            created: DateTime(2026, 3, 1),
          ),
        ],
        adjacency: const {
          'n1': {'n2', 'n3'},
          'n2': {'n1'},
          'n3': {'n1'},
        },
        selectedNodeId: 'n1',
        connectionAnchorId: 'n1',
        connectionIndex: connectionIndex,
      );

  testWidgets('no connection stepper on a node with no edges', (t) async {
    await t.pumpWidget(host(const GraphState(
      status: GraphStatus.loaded,
      selectedNodeId: 'n1',
      connectionAnchorId: 'n1',
    )));

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });

  testWidgets('an unwalked node reads 0/2 — its connections are there but the '
      'camera has not moved to one', (t) async {
    await t.pumpWidget(host(anchored()));

    expect(find.text('0/2'), findsOneWidget);
  });

  testWidgets('the position reflects the focused connection', (t) async {
    await t.pumpWidget(host(anchored(connectionIndex: 1)));

    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('the arrows walk the connections forwards and backwards',
      (t) async {
    await t.pumpWidget(host(anchored()));

    await t.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await t.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await t.pump();

    final deltas = verify(() => bloc.add(captureAny()))
        .captured
        .whereType<StepConnectedNodeEvent>()
        .map((e) => e.delta)
        .toList();
    expect(deltas, [1, -1]);
  });

  testWidgets('the panel does not re-select the node — that would toggle the '
      'open panel shut', (t) async {
    await t.pumpWidget(host(const GraphState(
      status: GraphStatus.loaded,
      selectedNodeId: 'n1',
    )));
    await t.tap(find.byType(NoteCard));
    await t.pumpAndSettle();
    await t.tap(find.text('back'));
    await t.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<SelectGraphNodeEvent>())));
  });
}
