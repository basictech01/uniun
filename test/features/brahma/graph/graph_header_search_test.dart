import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_header.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockGraphBloc extends MockBloc<GraphEvent, GraphState>
    implements GraphBloc {}

/// Covers the search match stepper (#208): the `‹ n/total ›` control that walks
/// the camera through the matches. It only exists while the search field is
/// open and the query matches something.
void main() {
  late _MockGraphBloc bloc;

  setUpAll(() => registerFallbackValue(const StepGraphMatchEvent(1)));

  setUp(() {
    bloc = _MockGraphBloc();
    whenListen(bloc, const Stream<GraphState>.empty());
  });

  Widget host(GraphState state) {
    when(() => bloc.state).thenReturn(state);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<GraphBloc>.value(
        value: bloc,
        child: const Scaffold(body: GraphHeader()),
      ),
    );
  }

  Future<void> openSearch(WidgetTester t) async {
    await t.tap(find.byIcon(Icons.search_rounded));
    await t.pumpAndSettle();
  }

  const searched = GraphState(
    status: GraphStatus.loaded,
    searchQuery: 'hit',
    matchedNodeIds: {'a', 'b', 'c'},
    matchOrder: ['a', 'b', 'c'],
  );

  testWidgets('no stepper before the search field is opened', (t) async {
    await t.pumpWidget(host(searched));
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });

  testWidgets('no stepper when the query matches nothing', (t) async {
    await t.pumpWidget(host(const GraphState(
      status: GraphStatus.loaded,
      searchQuery: 'hit',
    )));
    await openSearch(t);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });

  testWidgets('an unstepped search reads 0/3 — the matches are lit but the '
      'camera has not moved to one', (t) async {
    await t.pumpWidget(host(searched));
    await openSearch(t);

    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('the position reflects the focused match', (t) async {
    await t.pumpWidget(host(searched.copyWith(matchIndex: 1)));
    await openSearch(t);

    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('the arrows step the cursor forwards and backwards', (t) async {
    await t.pumpWidget(host(searched));
    await openSearch(t);

    await t.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await t.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await t.pump();

    final deltas = verify(() => bloc.add(captureAny()))
        .captured
        .whereType<StepGraphMatchEvent>()
        .map((e) => e.delta)
        .toList();
    expect(deltas, [1, -1]);
  });

  testWidgets('closing the search clears the query and hides the stepper',
      (t) async {
    await t.pumpWidget(host(searched));
    await openSearch(t);

    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();

    verify(() => bloc.add(const SearchGraphEvent(''))).called(1);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });
}
