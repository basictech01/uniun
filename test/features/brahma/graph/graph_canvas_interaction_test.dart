import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/safe_interactive_viewer.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/painters/graph_painter.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_canvas.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: GraphCanvas on a single painter — tapping a node or empty space,
/// dragging a node (and its release) versus panning on empty space, selection
/// fading the rest, label fade by zoom, opening zoomed out on a big graph, and
/// going idle once settled.
void main() {
  const size = Size(400, 800);

  GraphNodeData node(String id, {List<String> refs = const []}) =>
      GraphNodeData(
        eventId: id,
        content: id,
        eTagRefs: refs,
        type: GraphNodeType.own,
        created: DateTime(2026, 1, 1),
      );

  /// A chain n0 - n1 - n2 - ...
  List<GraphNodeData> chain(int n) => [
    for (var i = 0; i < n; i++) node('n$i', refs: i > 0 ? ['n${i - 1}'] : []),
  ];

  Map<String, Set<String>> adjacencyOf(int n) => {
    for (var i = 0; i < n; i++)
      'n$i': {if (i > 0) 'n${i - 1}', if (i < n - 1) 'n${i + 1}'},
  };

  Widget host({
    required List<GraphNodeData> nodes,
    String? selected,
    void Function(String)? onTap,
    VoidCallback? onCanvasTap,
    ValueChanged<bool>? onInteracting,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: GraphCanvas(
            nodes: nodes,
            adjacency: adjacencyOf(nodes.length),
            selectedNodeId: selected,
            onNodeTap: onTap ?? (_) {},
            onCanvasTap: onCanvasTap ?? () {},
            onInteractingChanged: onInteracting,
          ),
        ),
      ),
    ),
  );

  GraphCanvasState state(WidgetTester t) =>
      t.state<GraphCanvasState>(find.byType(GraphCanvas));

  Matrix4 camera(WidgetTester t) => t
      .widget<Transform>(
        find.descendant(
          of: find.byType(SafeInteractiveViewer),
          matching: find.byType(Transform),
        ),
      )
      .transform;

  Offset screenOf(WidgetTester t, String id) {
    final canvas = t.getRect(find.byType(GraphCanvas));
    return canvas.topLeft +
        MatrixUtils.transformPoint(camera(t), state(t).nodeCentre(id)!);
  }

  GraphPainter painter(WidgetTester t) => t
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((c) => c.painter)
      .whereType<GraphPainter>()
      .single;

  /// A finger moves in small steps; one big jump is swallowed by the gesture
  /// slop and the drag would start from where it landed.
  Future<void> dragBy(TestGesture g, WidgetTester t, Offset total) async {
    const steps = 12;
    for (var i = 0; i < steps; i++) {
      await g.moveBy(total / steps.toDouble());
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  group('taps', () {
    testWidgets('tapping a node reports it', (t) async {
      String? tapped;
      await t.pumpWidget(host(nodes: chain(3), onTap: (id) => tapped = id));
      await t.pumpAndSettle();

      await t.tapAt(screenOf(t, 'n1'));
      await t.pumpAndSettle();

      expect(tapped, 'n1');
    });

    testWidgets('a tap just outside a node but within finger reach hits it', (
      t,
    ) async {
      String? tapped;
      await t.pumpWidget(host(nodes: chain(3), onTap: (id) => tapped = id));
      await t.pumpAndSettle();

      await t.tapAt(screenOf(t, 'n1') + const Offset(7 + 8, 0));
      await t.pumpAndSettle();

      expect(tapped, 'n1', reason: 'node radius 7 + 14 px of reach');
    });

    testWidgets('tapping empty space reports the canvas, not a node', (
      t,
    ) async {
      var canvasTaps = 0;
      String? tapped;
      await t.pumpWidget(
        host(
          nodes: chain(3),
          onTap: (id) => tapped = id,
          onCanvasTap: () => canvasTaps++,
        ),
      );
      await t.pumpAndSettle();

      await t.tapAt(
        const Offset(20, 40) + t.getTopLeft(find.byType(GraphCanvas)),
      );
      await t.pumpAndSettle();

      expect(canvasTaps, 1);
      expect(tapped, isNull);
    });
  });

  group('every node can be touched', () {
    testWidgets('a node laid out beyond the screen-sized canvas box is still '
        'tappable once it is on screen', (t) async {
      final tapped = <String>[];
      await t.pumpWidget(host(nodes: chain(60), onTap: tapped.add));
      await t.pumpAndSettle();

      // Nodes whose canvas position lies outside the 400 x 800 box the canvas
      // is laid out in: drawn fine, but a hit area clipped to that box would
      // never see a touch there.
      final outside = [
        for (var i = 0; i < 60; i++)
          if (!const Rect.fromLTWH(
            0,
            0,
            400,
            800,
          ).contains(state(t).nodeCentre('n$i')!))
            'n$i',
      ];
      expect(outside, isNotEmpty, reason: 'this graph must spill past the box');

      for (final id in outside) {
        final at = screenOf(t, id);
        final canvas = t.getRect(find.byType(GraphCanvas));
        if (!canvas.deflate(12).contains(at)) continue; // off screen: skip
        await t.tapAt(at);
        await t.pumpAndSettle();
        expect(tapped.last, id, reason: '$id was drawn at $at but ignored');
      }
    });

    testWidgets('a tap with a little finger wobble still counts as a tap', (
      t,
    ) async {
      final tapped = <String>[];
      await t.pumpWidget(host(nodes: chain(3), onTap: tapped.add));
      await t.pumpAndSettle();

      final g = await t.startGesture(screenOf(t, 'n1'));
      await g.moveBy(const Offset(3, 2));
      await t.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(4, -3));
      await t.pump(const Duration(milliseconds: 16));
      await g.up();
      await t.pumpAndSettle();

      expect(tapped, ['n1']);
    });

    testWidgets('a tap lands on the node that was under the finger when it '
        'went down, even if the layout moves it before the finger lifts', (
      t,
    ) async {
      final tapped = <String>[];
      await t.pumpWidget(host(nodes: chain(8), onTap: tapped.add));
      await t.pumpAndSettle();
      final at = screenOf(t, 'n3');

      final g = await t.startGesture(at);
      // The layout moves n3 away while the finger is still down.
      final sim = state(t).simulation!;
      final i = sim.indexOf('n3')!;
      final p = sim.position(i);
      sim.pin(i, p.dx + 150, p.dy + 150);
      sim.unpin(i);
      await t.pump(const Duration(milliseconds: 100));
      expect(screenOf(t, 'n3'), isNot(at), reason: 'n3 really moved');
      await g.up();
      await t.pumpAndSettle();

      expect(tapped, ['n3']);
    });
  });

  group('dragging', () {
    testWidgets(
      'dragging a node moves it and tells the page it is interacting',
      (t) async {
        final interacting = <bool>[];
        await t.pumpWidget(
          host(nodes: chain(3), onInteracting: interacting.add),
        );
        await t.pumpAndSettle();
        final before = state(t).nodeCentre('n1')!;

        final g = await t.startGesture(screenOf(t, 'n1'));
        await dragBy(g, t, const Offset(120, 0));

        expect(state(t).nodeCentre('n1')!.dx, greaterThan(before.dx + 90));
        expect(interacting, contains(true));

        await g.up();
        await t.pumpAndSettle();
        expect(interacting.last, isFalse);
      },
    );

    testWidgets('dragging a node does not pan the canvas', (t) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pumpAndSettle();
      final before = camera(t).clone();

      final g = await t.startGesture(screenOf(t, 'n1'));
      await dragBy(g, t, const Offset(80, 0));
      await g.up();
      await t.pumpAndSettle();

      expect(camera(t), before);
    });

    testWidgets('dragging empty space pans the canvas and leaves nodes alone', (
      t,
    ) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pumpAndSettle();
      final node = state(t).nodeCentre('n1')!;

      final g = await t.startGesture(
        t.getTopLeft(find.byType(GraphCanvas)) + const Offset(20, 40),
      );
      await dragBy(g, t, const Offset(50, 30));
      await g.up();
      await t.pumpAndSettle();

      expect(camera(t).getTranslation().x, greaterThan(20));
      expect(state(t).nodeCentre('n1'), node);
    });

    testWidgets('a dragged node is released and the layout relaxes around it', (
      t,
    ) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pumpAndSettle();

      final g = await t.startGesture(screenOf(t, 'n1'));
      await dragBy(g, t, const Offset(150, 0));
      await g.up();
      await t.pump();
      final dropped = state(t).nodeCentre('n1')!;
      await t.pumpAndSettle();

      // Not held: once let go the springs pull it back towards its neighbours.
      expect(state(t).nodeCentre('n1')!.dx, lessThan(dropped.dx - 5));
    });
  });

  group('selection and labels', () {
    testWidgets('selecting a node fades everything that is not connected', (
      t,
    ) async {
      await t.pumpWidget(host(nodes: chain(5), selected: 'n1'));
      await t.pumpAndSettle();

      final byLabel = {for (final n in painter(t).nodes) n.label: n};
      expect(byLabel['n1']!.opacity, 1);
      expect(byLabel['n0']!.opacity, 1, reason: 'a neighbour');
      expect(byLabel['n2']!.opacity, 1, reason: 'a neighbour');
      expect(byLabel['n4']!.opacity, closeTo(0.2, 1e-9));
      expect(painter(t).hasSelection, isTrue);
    });

    testWidgets('no selection leaves every node at full strength', (t) async {
      await t.pumpWidget(host(nodes: chain(5)));
      await t.pumpAndSettle();

      expect(painter(t).nodes.every((n) => n.opacity == 1), isTrue);
      expect(painter(t).hasSelection, isFalse);
    });

    testWidgets('every chain link is drawn once', (t) async {
      await t.pumpWidget(host(nodes: chain(6)));
      await t.pumpAndSettle();

      expect(painter(t).links, hasLength(5));
    });

    testWidgets(
      'a leaf starts at the original size and a hub grows with its links, up to a cap',
      (t) async {
        final hub = [
          node('hub'),
          for (var i = 0; i < 40; i++) node('leaf$i', refs: ['hub']),
        ];
        await t.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphCanvas(
                nodes: hub,
                adjacency: {
                  'hub': {for (var i = 0; i < 40; i++) 'leaf$i'},
                  for (var i = 0; i < 40; i++) 'leaf$i': {'hub'},
                },
                selectedNodeId: null,
                onNodeTap: (_) {},
                onCanvasTap: () {},
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        final nodes = {for (final n in painter(t).nodes) n.label: n};
        expect(nodes['hub']!.radius, greaterThan(nodes['leaf0']!.radius * 1.5));
        expect(
          nodes['hub']!.radius,
          lessThanOrEqualTo(25),
          reason: 'diameter 50 at most',
        );
        expect(
          nodes['leaf0']!.radius,
          13.5,
          reason:
              'a one-link node: the original 24 px diameter plus 3 per link',
        );
      },
    );
  });

  group('labelOpacity', () {
    test('a small graph shows every label at any zoom', () {
      expect(labelOpacity(zoom: 0.3, radius: 7, nodeCount: 20), 1);
    });

    test('a big graph hides small nodes\' labels until zoomed in', () {
      expect(labelOpacity(zoom: 1, radius: 7, nodeCount: 300), 0);
      expect(labelOpacity(zoom: 3, radius: 7, nodeCount: 300), 1);
    });

    test('fades in smoothly between hidden and shown', () {
      final mid = labelOpacity(zoom: 2, radius: 7, nodeCount: 300);

      expect(mid, inExclusiveRange(0, 1));
    });

    test('a hub is named sooner than a leaf', () {
      final leaf = labelOpacity(zoom: 1, radius: 7, nodeCount: 300);
      final hub = labelOpacity(zoom: 1, radius: 22, nodeCount: 300);

      expect(hub, greaterThan(leaf));
    });

    test('the selected or searched node is always named', () {
      expect(
        labelOpacity(zoom: 0.3, radius: 7, nodeCount: 900, emphasised: true),
        1,
      );
    });

    test('zooming out never makes a label more visible', () {
      var prev = double.infinity;
      for (final z in [4.0, 3.0, 2.0, 1.0, 0.5, 0.25]) {
        final o = labelOpacity(zoom: z, radius: 9, nodeCount: 300);
        expect(o, lessThanOrEqualTo(prev));
        prev = o;
      }
    });
  });

  group('opening', () {
    testWidgets('the graph opens already laid out and still', (t) async {
      await t.pumpWidget(host(nodes: chain(12)));
      await t.pump(const Duration(milliseconds: 16));
      final first = {
        for (var i = 0; i < 12; i++) 'n$i': state(t).nodeCentre('n$i')!,
      };

      await t.pump(const Duration(seconds: 2));

      for (var i = 0; i < 12; i++) {
        expect(
          state(t).nodeCentre('n$i'),
          first['n$i'],
          reason: 'n$i moved after the first frame',
        );
      }
      expect(
        t.binding.hasScheduledFrame,
        isFalse,
        reason: 'nothing is animating, so nothing costs battery',
      );
    });

    testWidgets('on opening the layout has already settled: spread out, no '
        'two nodes touching', (t) async {
      await t.pumpWidget(host(nodes: chain(30)));
      await t.pump();

      final sim = state(t).simulation!;
      expect(sim.isSettled, isTrue);
      for (var i = 0; i < sim.count; i++) {
        for (var j = i + 1; j < sim.count; j++) {
          final a = sim.position(i), b = sim.position(j);
          final d = (Offset(a.dx, a.dy) - Offset(b.dx, b.dy)).distance;
          expect(
            d,
            greaterThan(sim.radius(i) + sim.radius(j) - 0.5),
            reason: 'n$i and n$j overlap on the first frame',
          );
        }
      }
    });

    testWidgets('a node follows the finger one-to-one even when zoomed out', (
      t,
    ) async {
      await t.pumpWidget(host(nodes: chain(120)));
      await t.pump();
      expect(camera(t).getMaxScaleOnAxis(), lessThan(0.9));
      // A node well inside the screen.
      final canvas = t.getRect(find.byType(GraphCanvas));
      final id = [
        for (var i = 0; i < 120; i++) 'n$i',
      ].firstWhere((id) => canvas.deflate(120).contains(screenOf(t, id)));
      final start = screenOf(t, id);

      final g = await t.startGesture(start);
      await dragBy(g, t, const Offset(60, 0));

      expect(
        screenOf(t, id).dx - start.dx,
        closeTo(60, 12),
        reason: 'under the finger, not scaled by the zoom',
      );
      await g.up();
      await t.pumpAndSettle();
    });

    testWidgets('a big graph opens already fitted to the screen', (t) async {
      await t.pumpWidget(host(nodes: chain(120)));
      await t.pump();

      final canvas = t.getRect(find.byType(GraphCanvas));
      for (var k = 0; k < 120; k += 11) {
        expect(
          canvas.inflate(40).contains(screenOf(t, 'n$k')),
          isTrue,
          reason: 'n$k is off screen on the very first frame',
        );
      }
    });

    testWidgets('a node can be dragged the moment the graph opens', (t) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pump();
      final before = state(t).nodeCentre('n1')!;

      final g = await t.startGesture(screenOf(t, 'n1'));
      await dragBy(g, t, const Offset(0, 100));
      expect(state(t).nodeCentre('n1')!.dy, greaterThan(before.dy + 60));
      await g.up();
      await t.pumpAndSettle();
    });

    testWidgets('a node can be dragged into empty space, and again after the '
        'layout has settled', (t) async {
      await t.pumpWidget(host(nodes: chain(4)));
      await t.pumpAndSettle();

      for (final delta in const [Offset(120, 0), Offset(-80, 90)]) {
        final before = state(t).nodeCentre('n2')!;
        final g = await t.startGesture(screenOf(t, 'n2'));
        await dragBy(g, t, delta);
        final held = state(t).nodeCentre('n2')!;
        expect(held.dx, closeTo(before.dx + delta.dx, 30));
        expect(held.dy, closeTo(before.dy + delta.dy, 30));
        await g.up();
        await t.pumpAndSettle();
      }
    });

    testWidgets('a dragged node follows the finger even past the screen edge', (
      t,
    ) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pumpAndSettle();
      final before = state(t).nodeCentre('n1')!;

      final g = await t.startGesture(screenOf(t, 'n1'));
      await dragBy(g, t, const Offset(300, 0));

      expect(state(t).nodeCentre('n1')!.dx, greaterThan(before.dx + 200));
      await g.up();
      await t.pumpAndSettle();
    });
  });

  group('large graphs', () {
    testWidgets('a big graph opens zoomed out to fit, a small one does not', (
      t,
    ) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pumpAndSettle();
      expect(camera(t), Matrix4.identity());

      await t.pumpWidget(host(nodes: chain(200)));
      await t.pumpAndSettle();
      expect(camera(t).getMaxScaleOnAxis(), lessThan(1));
    });

    testWidgets(
      'a 300-node graph lays out and settles without error',
      (t) async {
        await t.pumpWidget(host(nodes: chain(300)));
        await t.pumpAndSettle(const Duration(milliseconds: 100));

        expect(t.takeException(), isNull);
        expect(painter(t).nodes, hasLength(300));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('resting', () {
    testWidgets('once settled the canvas schedules no more frames', (t) async {
      await t.pumpWidget(host(nodes: chain(8)));

      // pumpAndSettle only returns when nothing is animating or ticking.
      await t.pumpAndSettle(const Duration(milliseconds: 100));

      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('an empty graph shows the hint, not a canvas', (t) async {
      await t.pumpWidget(host(nodes: const []));

      expect(find.byType(GraphPainter), findsNothing);
      expect(find.byType(SafeInteractiveViewer), findsNothing);
    });

    testWidgets('new nodes are laid out afresh', (t) async {
      await t.pumpWidget(host(nodes: chain(3)));
      await t.pumpAndSettle();

      await t.pumpWidget(host(nodes: chain(5)));
      await t.pumpAndSettle();

      expect(painter(t).nodes, hasLength(5));
    });
  });
}
