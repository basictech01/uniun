import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/safe_interactive_viewer.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_canvas.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: camera flight to a focused node, zoom level, stepping between
/// matches, view restore on close, no-op when nothing is focused, gesture interrupt.
void main() {
  const size = Size(400, 800);

  GraphNodeData node(String id) => GraphNodeData(
    eventId: id,
    content: id,
    eTagRefs: const [],
    type: GraphNodeType.own,
    created: DateTime(2026, 1, 1),
  );

  final nodes = [node('alpha'), node('beta'), node('gamma')];

  Widget host({bool isSearching = false, String? focusedNodeId}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: GraphCanvas(
            nodes: nodes,
            adjacency: const {},
            selectedNodeId: focusedNodeId,
            isSearching: isSearching,
            matchedNodeIds: isSearching ? const {'beta'} : const {},
            focusedNodeId: focusedNodeId,
            onNodeTap: (_) {},
            onCanvasTap: () {},
          ),
        ),
      ),
    ),
  );

  Matrix4 camera(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(SafeInteractiveViewer),
          matching: find.byType(Transform),
        ),
      )
      .transform;

  /// Where the canvas parks a focused node: horizontally centred, in the upper
  /// third so the node panel can open under it.
  Offset focusPoint(WidgetTester tester) {
    final canvas = tester.getRect(find.byType(GraphCanvas));
    return Offset(canvas.center.dx, canvas.top + canvas.height * 0.3);
  }

  /// Screen centre of a node's circle (the point the camera aims at): its
  /// position on the canvas, carried through the current pan and zoom.
  Offset circleCentre(WidgetTester tester, String id) {
    final state = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
    final local = state.nodeCentre(id)!;
    final canvas = tester.getRect(find.byType(GraphCanvas));
    final p = MatrixUtils.transformPoint(camera(tester), local);
    return canvas.topLeft + p;
  }

  testWidgets('a focused match is flown to the focus point and zoomed in', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(camera(tester), Matrix4.identity());

    await tester.pumpWidget(host(isSearching: true, focusedNodeId: 'beta'));
    await tester.pumpAndSettle();

    final target = focusPoint(tester);
    final landed = circleCentre(tester, 'beta');
    expect(landed.dx, closeTo(target.dx, 1));
    expect(landed.dy, closeTo(target.dy, 1));
    expect(camera(tester).getMaxScaleOnAxis(), closeTo(1.4, 0.001));
  });

  testWidgets('stepping to another match flies on to that one', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(isSearching: true, focusedNodeId: 'beta'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(isSearching: true, focusedNodeId: 'gamma'));
    await tester.pumpAndSettle();

    final target = focusPoint(tester);
    final landed = circleCentre(tester, 'gamma');
    expect(landed.dx, closeTo(target.dx, 1));
    expect(landed.dy, closeTo(target.dy, 1));
  });

  testWidgets('closing the search restores the view held before the flight', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(isSearching: true, focusedNodeId: 'beta'));
    await tester.pumpAndSettle();
    expect(camera(tester), isNot(Matrix4.identity()));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(camera(tester), Matrix4.identity());
  });

  testWidgets('a search that was only typed into leaves the view alone — '
      'nothing flew, so there is nothing to restore', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(isSearching: true));
    await tester.pumpAndSettle();
    expect(camera(tester), Matrix4.identity());

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(camera(tester), Matrix4.identity());
  });

  testWidgets('stepping back out to the overview slot restores the view while '
      'the search is still open', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(isSearching: true, focusedNodeId: 'beta'));
    await tester.pumpAndSettle();
    expect(camera(tester), isNot(Matrix4.identity()));

    // The cursor wrapped past the last match: still searching, nothing focused.
    await tester.pumpWidget(host(isSearching: true));
    await tester.pumpAndSettle();

    expect(camera(tester), Matrix4.identity());
  });

  testWidgets('panning during a flight takes the camera back from it', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(isSearching: true, focusedNodeId: 'beta'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(
      find.byType(SafeInteractiveViewer),
      const Offset(-50, -40),
    );
    await tester.pump();
    final afterDrag = camera(tester).clone();
    await tester.pumpAndSettle();

    // The interrupted flight never resumes — the view stays where the drag
    // left it.
    expect(camera(tester), afterDrag);
  });
}
