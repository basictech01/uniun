import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/floating_nav.dart';
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/pages/graph_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockGraphBloc extends MockBloc<GraphEvent, GraphState>
    implements GraphBloc {}

class _MockBrahmaCreateBloc
    extends MockBloc<BrahmaCreateEvent, BrahmaCreateState>
    implements BrahmaCreateBloc {}

/// The graph's keyboard behaviour: the floating nav must get out of the way
/// when the search keyboard comes up (it sat on top of it), and a tap on empty
/// canvas must put that keyboard away.
void main() {
  late _MockGraphBloc graph;
  late _MockBrahmaCreateBloc create;

  GraphNodeData node(String id) => GraphNodeData(
        eventId: id,
        content: id,
        eTagRefs: const [],
        type: GraphNodeType.own,
        created: DateTime(2026, 1, 1),
      );

  setUpAll(() => registerFallbackValue(const LoadGraphEvent()));

  setUp(() async {
    graph = _MockGraphBloc();
    create = _MockBrahmaCreateBloc();
    when(() => create.state).thenReturn(const BrahmaCreateState());
    when(() => graph.isClosed).thenReturn(false);
    when(() => graph.state).thenReturn(GraphState(
      status: GraphStatus.loaded,
      nodes: [node('alpha'), node('beta')],
      adjacency: const {'alpha': {}, 'beta': {}},
    ));
    await GetIt.instance.reset();
    GetIt.instance.registerFactory<GraphBloc>(() => graph);
    GetIt.instance.registerFactory<BrahmaCreateBloc>(() => create);
    KeyboardVisibilityTesting.setVisibilityForTesting(false);
  });

  tearDown(() async {
    KeyboardVisibilityTesting.setVisibilityForTesting(false);
    await GetIt.instance.reset();
  });

  Widget host() => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GraphPage(),
      );

  Offset navOffset(WidgetTester tester) => tester
      .widget<AnimatedSlide>(
        find.ancestor(
          of: find.byType(FloatingNav),
          matching: find.byType(AnimatedSlide),
        ),
      )
      .offset;

  bool searchFieldHasFocus(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  testWidgets('the nav rides at rest while the keyboard is down', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    expect(navOffset(t), Offset.zero);
  });

  testWidgets('the nav slides away when the keyboard comes up', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    KeyboardVisibilityTesting.setVisibilityForTesting(true);
    await t.pumpAndSettle();

    expect(navOffset(t).dy, greaterThan(0));
  });

  testWidgets('tapping empty canvas dismisses the search keyboard', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.search_rounded));
    await t.pumpAndSettle();
    expect(searchFieldHasFocus(t), isTrue);

    await t.tapAt(const Offset(8, 200));
    await t.pumpAndSettle();

    expect(searchFieldHasFocus(t), isFalse);
  });
}
