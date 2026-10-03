import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:uniun/common/widgets/markdown/strip_markdown.dart';
import 'package:uniun/common/widgets/safe_interactive_viewer.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/features/brahma/graph/layout/graph_simulation.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/painters/dot_pattern_painter.dart';
import 'package:uniun/features/brahma/graph/painters/graph_painter.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_header.dart';
import 'package:uniun/l10n/app_localizations.dart';

// ── Graph canvas ───────────────────────────────────────────────────────────────

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.nodes,
    required this.adjacency,
    required this.selectedNodeId,
    required this.onNodeTap,
    required this.onCanvasTap,
    this.onInteractingChanged,
    this.isSearching = false,
    this.matchedNodeIds = const {},
    this.focusedNodeId,
  });

  final List<GraphNodeData> nodes;
  final Map<String, Set<String>> adjacency;
  final String? selectedNodeId;
  final void Function(String nodeId) onNodeTap;
  final VoidCallback onCanvasTap;
  final ValueChanged<bool>? onInteractingChanged;

  /// When true, [matchedNodeIds] stay lit and every other node dims.
  final bool isSearching;
  final Set<String> matchedNodeIds;

  /// The node to centre the camera on — a search match or a connection of the
  /// selected node. Each new value flies the view to that node; the view held
  /// before the first flight comes back when the focus ends.
  final String? focusedNodeId;

  @override
  State<GraphCanvas> createState() => GraphCanvasState();
}

/// Node radius from its number of connections. The circle's diameter starts at
/// 24 and grows by 3 per link, capped at 50 — so a hub is about twice a leaf,
/// never more.
double nodeRadiusFor(int connections) =>
    (24.0 + connections * 3.0).clamp(24.0, 50.0) / 2;

/// The label under a node is up to ~26 px tall and 88 px wide; the layout keeps
/// this much clear around each circle so labels never sit on each other.
const double kLabelFootprint = 24;

/// The layout's constants for these nodes: the many-body strength scales with
/// the square of the lengths (see [SimConfig]), so roomier nodes get a longer
/// link and a stronger push.
const SimConfig kGraphSimConfig = SimConfig(
  charge: -1200,
  linkDistance: 160,
  centerStrength: 0.08,
  collidePadding: 6,
  collideExtra: kLabelFootprint,
  distanceMax: 1600,
);

class GraphCanvasState extends State<GraphCanvas>
    with TickerProviderStateMixin {
  GraphSimulation? _sim;
  late List<String> _ids;
  late List<(int, int)> _links;
  late final Ticker _ticker = createTicker((_) => _step());
  bool _initialized = false;

  double _graphW = 400;
  double _graphH = 800;

  /// Heat the layout holds while a node is being dragged, so its neighbours
  /// follow it.
  static const double _dragHeat = 0.3;

  /// Extra reach around a node for a finger, in screen pixels.
  static const double _touchSlop = 14;

  int? _draggingIndex;

  /// Layout ticks run before the first frame, so the graph appears already
  /// laid out and still. 300 is where it cools to rest.
  static const int _warmUpTicks = 300;

  // ── Camera ─────────────────────────────────────────────────────────────────
  // Zoom level a search flight lands on, and where in the viewport it parks the
  // node: high enough that the node panel (up to 52% of the screen) can open
  // under it without covering it.
  static const double _focusScale = 1.4;
  static const double _focusYFraction = 0.3;

  final TransformationController _viewer = TransformationController();
  late final AnimationController _camera = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(_driveCamera);

  // Matrix the running flight started from.
  Matrix4? _flyFrom;
  // Fixed destination (the restore flight). Null while flying to a node, whose
  // destination is recomputed every frame from its live position.
  Matrix4? _flyTo;
  // Node the camera is locked onto — kept centred while the simulation is
  // still moving it. Cleared as soon as the user touches the canvas.
  String? _followNodeId;
  // The view to return to when the search closes; captured before the first
  // flight of a search session.
  Matrix4? _preSearchView;

  @override
  void initState() {
    super.initState();
    _viewer.addListener(_onView);
    _prepareGraph(widget.nodes);
  }

  void _onView() {
    if (mounted) setState(() {});
  }

  void _prepareGraph(List<GraphNodeData> nodes) {
    // A new node set is laid out from scratch, so a camera position captured
    // against the old layout no longer points anywhere meaningful.
    _camera.stop();
    _followNodeId = null;
    _preSearchView = null;
    _initialized = false;
    _draggingIndex = null;
    _ticker.stop();
    _sim = null;
    final all = {for (final n in nodes) n.eventId};
    _ids = [for (final n in nodes) n.eventId];
    final index = {for (var i = 0; i < _ids.length; i++) _ids[i]: i};
    final seen = <String>{};
    _links = [];
    for (final n in nodes) {
      // refEdges = canonical reference/reply parents (NIP-10 root excluded),
      // so the drawn graph matches the adjacency and the comment/reference
      // counts — one edge per pair, no thread-root hub.
      for (final ref in n.refEdges) {
        if (all.contains(ref) && ref != n.eventId) {
          final key = ([n.eventId, ref]..sort()).join('|');
          if (seen.add(key)) _links.add((index[n.eventId]!, index[ref]!));
        }
      }
    }
  }

  double _radiusFor(String id) =>
      nodeRadiusFor(widget.adjacency[id]?.length ?? 0);

  void _initSimulation(double w, double h) {
    _graphW = w;
    _graphH = h;
    final sim = GraphSimulation(
      ids: _ids,
      radii: [for (final id in _ids) _radiusFor(id)],
      links: _links,
      config: kGraphSimConfig,
      center: Offset2(w / 2, h / 2),
    )..warmUp(_warmUpTicks);
    _sim = sim;
    _initialized = true;
    _fitIfNeeded();
  }

  /// Opens the view on the whole graph: zoomed out to fit when it is wider than
  /// the screen, at natural size when it already fits.
  void _fitIfNeeded() {
    final sim = _sim;
    if (sim == null || sim.count == 0) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i < sim.count; i++) {
      final p = sim.position(i), r = sim.radius(i) + kLabelFootprint + 18;
      minX = math.min(minX, p.dx - r);
      maxX = math.max(maxX, p.dx + r);
      minY = math.min(minY, p.dy - r);
      maxY = math.max(maxY, p.dy + r);
    }
    final bw = maxX - minX, bh = maxY - minY;
    final Matrix4 target;
    if (bw <= _graphW && bh <= _graphH) {
      target = Matrix4.identity();
    } else {
      final s = math.max(0.1, math.min(_graphW / bw, _graphH / bh) * 0.94);
      final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
      target = Matrix4.identity()
        ..translateByDouble(_graphW / 2 - s * cx, _graphH / 2 - s * cy, 0, 1)
        ..scaleByDouble(s, s, s, 1);
    }
    // Held off from the view listener: this runs while the canvas is built.
    _viewer.removeListener(_onView);
    _viewer.value = target;
    _viewer.addListener(_onView);
  }

  /// One frame of the layout. Stops itself once the graph has settled, so a
  /// resting graph costs nothing.
  void _step() {
    final sim = _sim;
    if (sim == null) return;
    sim.tick();
    if (_followNodeId != null && !_camera.isAnimating) {
      _viewer.value = _viewCentredOn(_followNodeId!) ?? _viewer.value;
    }
    if (mounted) setState(() {});
    if (sim.isSettled && _draggingIndex == null) _ticker.stop();
  }

  void _wake([double heat = _dragHeat]) {
    _sim?.reheat(heat);
    if (!_ticker.isActive) _ticker.start();
  }

  // ── Camera helpers over the simulation ─────────────────────────────────────

  Offset? _centreOf(String id) {
    final sim = _sim;
    final i = sim?.indexOf(id);
    if (sim == null || i == null) return null;
    final p = sim.position(i);
    return Offset(p.dx, p.dy);
  }

  /// The running layout, so a test can move a node as the layout would.
  @visibleForTesting
  GraphSimulation? get simulation => _sim;

  /// Where node [id] sits in the canvas's own coordinates, for tests.
  @visibleForTesting
  Offset? nodeCentre(String id) => _centreOf(id);

  /// The transform that parks [id]'s current centre at the focus point.
  Matrix4? _viewCentredOn(String id) {
    final c = _centreOf(id);
    if (c == null) return null;
    const s = _focusScale;
    return Matrix4.identity()
      ..translateByDouble(
        _graphW / 2 - s * c.dx,
        _graphH * _focusYFraction - s * c.dy,
        0,
        1,
      )
      ..scaleByDouble(s, s, s, 1);
  }

  /// Interpolates the scale and translation of two pan/zoom transforms. Both
  /// carry no rotation or skew, so `s·p + t` fully describes them.
  static Matrix4 _lerpView(Matrix4 a, Matrix4 b, double t) {
    final sa = a.getMaxScaleOnAxis();
    final sb = b.getMaxScaleOnAxis();
    final s = sa + (sb - sa) * t;
    final ta = a.getTranslation();
    final tb = b.getTranslation();
    return Matrix4.identity()
      ..translateByDouble(
        ta.x + (tb.x - ta.x) * t,
        ta.y + (tb.y - ta.y) * t,
        0,
        1,
      )
      ..scaleByDouble(s, s, s, 1);
  }

  void _driveCamera() {
    final from = _flyFrom;
    if (from == null) return;
    // While flying to a node the destination is re-read every frame: the
    // simulation is often still moving that node, and a destination frozen at
    // take-off would land the camera where the node used to be.
    final to =
        _flyTo ??
        (_followNodeId == null ? null : _viewCentredOn(_followNodeId!));
    if (to == null) return;
    _viewer.value = _lerpView(
      from,
      to,
      Curves.easeOutCubic.transform(_camera.value),
    );
  }

  void _flyToNode(String id) {
    if (_viewCentredOn(id) == null) return;
    _preSearchView ??= _viewer.value.clone();
    _flyFrom = _viewer.value.clone();
    _flyTo = null;
    _followNodeId = id;
    _camera.forward(from: 0);
  }

  /// Returns to the view held before the search's first flight. No-op when the
  /// camera never moved — closing a search you only typed into leaves the view
  /// exactly where you left it.
  void _restoreView() {
    final target = _preSearchView;
    _preSearchView = null;
    _followNodeId = null;
    if (target == null) return;
    _flyFrom = _viewer.value.clone();
    _flyTo = target;
    _camera.forward(from: 0);
  }

  /// Any touch on the canvas takes the camera back: a flight in progress stops
  /// and the lock on the focused node releases, so gestures are never fought.
  void _releaseCamera() {
    _camera.stop();
    _followNodeId = null;
  }

  @override
  void didUpdateWidget(GraphCanvas old) {
    super.didUpdateWidget(old);
    if (old.nodes != widget.nodes) {
      _prepareGraph(widget.nodes);
      setState(() {});
    }
    if (widget.focusedNodeId != null &&
        widget.focusedNodeId != old.focusedNodeId) {
      _flyToNode(widget.focusedNodeId!);
    } else if (widget.focusedNodeId == null && old.focusedNodeId != null) {
      _restoreView();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _camera.dispose();
    _viewer.removeListener(_onView);
    _viewer.dispose();
    super.dispose();
  }

  // ── Gestures ───────────────────────────────────────────────────────────────
  // Every touch is taken over the whole canvas and converted to graph
  // coordinates, never over the canvas's own box: a node laid out beyond that
  // box is drawn but a box-shaped hit area would never see a finger there.

  /// The node under a touch at [screen] (canvas-widget coordinates), with a
  /// finger's worth of reach that stays the same size on screen at any zoom.
  int? _hit(Offset screen) {
    final zoom = _viewer.value.getMaxScaleOnAxis();
    final world = _viewer.toScene(screen);
    return _sim?.nodeAt(world.dx, world.dy, slop: _touchSlop / zoom);
  }

  /// The node a tap went down on. A tap belongs to what was under the finger
  /// when it landed: the layout may have moved that node by the time it lifts.
  int? _tapDownNode;

  void _dragStart(int i) {
    _releaseCamera();
    _draggingIndex = i;
    final sim = _sim!;
    final p = sim.position(i);
    sim.pin(i, p.dx, p.dy);
    sim.alphaTarget = _dragHeat;
    _wake(_dragHeat);
    widget.onInteractingChanged?.call(true);
  }

  void _dragUpdate(Offset screenDelta) {
    final i = _draggingIndex;
    final sim = _sim;
    if (i == null || sim == null) return;
    final zoom = _viewer.value.getMaxScaleOnAxis();
    final p = sim.position(i);
    sim.pin(i, p.dx + screenDelta.dx / zoom, p.dy + screenDelta.dy / zoom);
    if (mounted) setState(() {});
  }

  /// Letting go releases the node: the layout relaxes around where it was
  /// dropped, as in Obsidian.
  void _dragEnd() {
    final i = _draggingIndex;
    final sim = _sim;
    if (i == null || sim == null) return;
    sim.unpin(i);
    sim.alphaTarget = 0;
    _draggingIndex = null;
    _wake(0.15);
    widget.onInteractingChanged?.call(false);
  }

  void _tapDown(Offset screen) => _tapDownNode = _hit(screen);

  void _tapUp() {
    final i = _tapDownNode;
    _tapDownNode = null;
    if (i == null) {
      widget.onCanvasTap();
    } else {
      widget.onNodeTap(_ids[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(color: context.custom.graphDotPattern),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppLocalizations.of(context)!.graphEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: DotPatternPainter(color: context.custom.graphDotPattern),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 400.0;
            final h = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 800.0;
            if (!_initialized) {
              _initSimulation(w, h);
            }
            return RawGestureDetector(
              // A drag only starts on a node: the recogniser declines any
              // touch that lands on empty space, so the canvas still pans.
              gestures: {
                _NodeDragRecognizer:
                    GestureRecognizerFactoryWithHandlers<_NodeDragRecognizer>(
                      () => _NodeDragRecognizer(onNode: (p) => _hit(p) != null),
                      (r) {
                        r.onStart = (screen) {
                          final i = _hit(screen);
                          if (i != null) _dragStart(i);
                        };
                        r.onUpdate = _dragUpdate;
                        r.onEnd = _dragEnd;
                      },
                    ),
              },
              // The raw pointer-down is where the finger really landed; a tap
              // recogniser only reports it after its press timeout.
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) => _tapDown(e.localPosition),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (_) => _tapUp(),
                  onTapCancel: () => _tapDownNode = null,
                  child: SafeInteractiveViewer(
                    constrained: false,
                    minScale: 0.1,
                    maxScale: 4.0,
                    controller: _viewer,
                    onInteractionStart: () {
                      _releaseCamera();
                      widget.onInteractingChanged?.call(true);
                    },
                    onInteractionEnd: () =>
                        widget.onInteractingChanged?.call(false),
                    child: CustomPaint(
                      size: Size(_graphW, _graphH),
                      painter: _painter(context),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  GraphPainter _painter(BuildContext context) {
    final sim = _sim!;
    final scheme = Theme.of(context).colorScheme;
    final colors = graphNodeTypeColorsOf(context);
    final byId = {for (final n in widget.nodes) n.eventId: n};
    final selected = widget.selectedNodeId;
    final hasSelection = selected != null;
    final painted = <PaintedNode>[];
    for (var i = 0; i < sim.count; i++) {
      final id = _ids[i];
      final data = byId[id];
      final p = sim.position(i);
      final isSelected = selected == id;
      final isConnected =
          hasSelection && (widget.adjacency[selected]?.contains(id) ?? false);
      // A search match glows like a connected node; while searching, search
      // highlighting takes precedence over the selection dim.
      final isMatch = widget.isSearching && widget.matchedNodeIds.contains(id);
      final double opacity;
      if (widget.isSearching) {
        opacity = isMatch ? 1.0 : 0.18;
      } else {
        opacity = hasSelection && !isSelected && !isConnected ? 0.2 : 1.0;
      }
      painted.add(
        PaintedNode(
          center: Offset(p.dx, p.dy),
          radius: sim.radius(i),
          color: data != null ? colors[data.type]! : scheme.primary,
          label: _labelFor(id),
          opacity: opacity,
          isSelected: isSelected,
          isConnected: isConnected,
          isMatch: isMatch,
        ),
      );
    }
    return GraphPainter(
      nodes: painted,
      links: _links,
      zoom: _viewer.value.getMaxScaleOnAxis(),
      fadeLabels: false,
      backdrop: Theme.of(context).scaffoldBackgroundColor,
      restColor: context.custom.neutral300,
      highlightColor: scheme.primary,
      labelColor: scheme.onSurfaceVariant,
      hasSelection: hasSelection,
      isSearching: widget.isSearching,
    );
  }

  String _labelFor(String nodeId) {
    try {
      final node = widget.nodes.firstWhere((n) => n.eventId == nodeId);
      final text = stripMarkdownPreview(
        node.content,
      ).trim().replaceAll('\n', ' ');
      return text.length > 30 ? '${text.substring(0, 30)}…' : text;
    } catch (_) {
      return '…';
    }
  }
}

/// Drags a node: claims a touch that began on one once it has clearly moved —
/// further than the wobble of a finger tapping, so a tap is never taken for a
/// drag, yet before the canvas's own pan and pinch (which claim at 18 px) can
/// take it.
class _NodeDragRecognizer extends OneSequenceGestureRecognizer {
  _NodeDragRecognizer({required this.onNode});

  /// Whether a touch at this canvas position is on a node.
  final bool Function(Offset local) onNode;

  void Function(Offset local)? onStart;
  void Function(Offset delta)? onUpdate;
  VoidCallback? onEnd;

  static const double _claimDistance = 14;

  int? _pointer;
  Offset _downGlobal = Offset.zero;
  Offset _downLocal = Offset.zero;
  bool _dragging = false;

  /// Movement since the finger landed, handed to the drag when it starts so
  /// the node ends up under the finger rather than [_claimDistance] behind it.
  Offset _sinceDown = Offset.zero;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null || !onNode(event.localPosition)) return;
    _pointer = event.pointer;
    _downGlobal = event.position;
    _downLocal = event.localPosition;
    _dragging = false;
    _sinceDown = Offset.zero;
    startTrackingPointer(event.pointer, event.transform);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      if (_dragging) {
        onUpdate?.call(event.delta);
      } else {
        _sinceDown += event.delta;
        if ((event.position - _downGlobal).distance > _claimDistance) {
          resolve(GestureDisposition.accepted);
        }
      }
    } else if (event is PointerUpEvent) {
      if (_dragging) {
        _dragging = false;
        onEnd?.call();
      } else {
        resolve(GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      if (_dragging) {
        _dragging = false;
        onEnd?.call();
      }
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != _pointer) return;
    _dragging = true;
    onStart?.call(_downLocal);
    onUpdate?.call(_sinceDown);
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _pointer) stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
  }

  @override
  String get debugDescription => 'node drag';
}
