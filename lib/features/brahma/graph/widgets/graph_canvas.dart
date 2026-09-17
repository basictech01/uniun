import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:uniun/common/widgets/markdown/strip_markdown.dart';
import 'package:uniun/common/widgets/safe_interactive_viewer.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/features/brahma/graph/layout/force_layout_tuning.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/painters/dot_pattern_painter.dart';
import 'package:uniun/features/brahma/graph/painters/edge_painter.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_header.dart';
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
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with SingleTickerProviderStateMixin {
  late Graph _graph;
  Timer? _timer;
  bool _initialized = false;

  double _graphW = 400;
  double _graphH = 800;

  bool _isDragging = false;
  Node? _draggingNode;
  final Set<Node> _pinned = {};

  // ── d3-force-style simulation state ────────────────────────────────────────
  // These four scale with node count (see _tuneForces) so a dense graph spreads
  // out instead of compressing into a tangled hairball; defaults match the feel
  // at small N. Everything below them stays fixed.
  double _linkDistance = 240;
  double _chargeStrength = -4000;
  double _centerStrength = 0.025;
  double _collidePadding = 6;
  // sqrt-of-density scale factor (1.0 at small N), also used to widen the
  // initial seed ring. Set by _tuneForces before the first tick.
  double _spreadScale = 1.0;
  // Each node widget is a circle + 5px gap + a 2-line label (~26px tall, 88px wide).
  // Inflate the collision disc so the label of one node never overlaps the
  // circle or label of another.
  static const double _labelFootprint = 24;
  // Label SizedBox width — drives Column intrinsic width, so the Positioned
  // is shifted by (label - circle)/2 to keep node.x as the circle's top-left.
  static const double _labelWidth = 88;
  static const int _collideIters = 3;
  static const double _velocityDecay = 0.4;
  static const double _alphaMin = 0.001;
  static const double _alphaDecay = 0.0228;
  static const double _reheatAlpha = 0.3;

  double _alpha = 1.0;
  final Map<Node, Offset> _velocity = {};
  final Map<Node, int> _degree = {};

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
    _prepareGraph(widget.nodes);
  }

  void _prepareGraph(List<GraphNodeData> nodes) {
    // A new node set is re-seeded from scratch, so a camera position captured
    // against the old layout no longer points anywhere meaningful.
    _camera.stop();
    _followNodeId = null;
    _preSearchView = null;
    _initialized = false;
    _isDragging = false;
    _draggingNode = null;
    _timer?.cancel();
    _timer = null;
    _velocity.clear();
    _degree.clear();
    _pinned.clear();
    _alpha = 1.0;
    _graph = _buildGraph(nodes);
  }

  double _sizeFor(String nodeId) {
    final connections = widget.adjacency[nodeId]?.length ?? 0;
    return nodeRadiusForConnections(connections);
  }

  Graph _buildGraph(List<GraphNodeData> nodes) {
    final g = Graph()..isTree = false;
    final nodeMap = <String, Node>{};
    final allIds = {for (final n in nodes) n.eventId};

    for (final n in nodes) {
      final sz = _sizeFor(n.eventId);
      final node = Node.Id(n.eventId);
      node.size = Size(sz, sz);
      nodeMap[n.eventId] = node;
      g.addNode(node);
    }

    final added = <String>{};
    for (final n in nodes) {
      // refEdges = canonical reference/reply parents (NIP-10 root excluded),
      // so the drawn graph matches the adjacency and the comment/reference
      // counts — one edge per pair, no thread-root hub.
      for (final ref in n.refEdges) {
        if (allIds.contains(ref) && ref != n.eventId) {
          final key = ([n.eventId, ref]..sort()).join('|');
          if (added.add(key)) {
            g.addEdge(nodeMap[n.eventId]!, nodeMap[ref]!);
          }
        }
      }
    }
    return g;
  }

  // Scale the spreading forces with node count so per-node area grows ∝ N
  // (constant visual density) and the dense core de-densifies as the graph
  // grows, instead of compressing into a tangled hairball.
  void _tuneForces(int n) {
    final t = ForceLayoutTuning.forNodes(n);
    _spreadScale = t.spreadScale;
    _linkDistance = t.linkDistance;
    _chargeStrength = t.chargeStrength;
    _centerStrength = t.centerStrength;
    _collidePadding = t.collidePadding;
  }

  void _initPhysics(double w, double h) {
    _graphW = w;
    _graphH = h;
    _tuneForces(_graph.nodes.length);
    final rng = math.Random(42);
    final cx = w / 2;
    final cy = h / 2;
    // Seed positions in a random ring around center so forces can spread.
    // Widen the ring with _spreadScale so large graphs don't start as a tight
    // knot that settles into a tangled local minimum.
    for (final node in _graph.nodes) {
      final nodeId = node.key!.value as String;
      final sz = _sizeFor(nodeId);
      node.size = Size(sz, sz);
      final seedRadius = math.min(w, h) * _spreadScale;
      final r = seedRadius * (0.6 + rng.nextDouble() * 0.5);
      final a = rng.nextDouble() * 2 * math.pi;
      node.position = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      _velocity[node] = Offset.zero;
      _degree[node] = 0;
    }
    for (final edge in _graph.edges) {
      _degree[edge.source] = (_degree[edge.source] ?? 0) + 1;
      _degree[edge.destination] = (_degree[edge.destination] ?? 0) + 1;
    }
    _alpha = 1.0;
    _initialized = true;
  }

  // Node center from top-left position + size.
  Offset _centerOf(Node n) => Offset(n.x + n.width / 2, n.y + n.height / 2);

  void _setCenter(Node n, Offset c) {
    n.position = Offset(c.dx - n.width / 2, c.dy - n.height / 2);
  }

  void _tick() {
    final nodes = _graph.nodes;
    if (nodes.isEmpty) return;

    final forces = {for (final n in nodes) n: Offset.zero};
    final cx = _graphW / 2;
    final cy = _graphH / 2;

    // 1. Many-body repulsion (charge)
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];
        final ca = _centerOf(a);
        final cb = _centerOf(b);
        var dx = ca.dx - cb.dx;
        var dy = ca.dy - cb.dy;
        var d2 = dx * dx + dy * dy;
        if (d2 < 1) {
          dx = (math.Random().nextDouble() - 0.5) * 2;
          dy = (math.Random().nextDouble() - 0.5) * 2;
          d2 = dx * dx + dy * dy;
        }
        final d = math.sqrt(d2);
        final f = _chargeStrength / d2;
        final fx = (dx / d) * f;
        final fy = (dy / d) * f;
        forces[a] = forces[a]! - Offset(fx, fy);
        forces[b] = forces[b]! + Offset(fx, fy);
      }
    }

    // 2. Link spring
    for (final edge in _graph.edges) {
      final a = edge.source;
      final b = edge.destination;
      final ca = _centerOf(a);
      final cb = _centerOf(b);
      final dx = cb.dx - ca.dx;
      final dy = cb.dy - ca.dy;
      final d = math.sqrt(dx * dx + dy * dy).clamp(0.01, double.infinity);
      final degA = _degree[a] ?? 1;
      final degB = _degree[b] ?? 1;
      final strength = 1.0 / math.max(degA, degB);
      final disp = (d - _linkDistance) * strength;
      final fx = (dx / d) * disp;
      final fy = (dy / d) * disp;
      // Bias split by degree (d3 default): heavier node moves less.
      final bias = degA / (degA + degB);
      forces[a] = forces[a]! + Offset(fx * (1 - bias), fy * (1 - bias));
      forces[b] = forces[b]! - Offset(fx * bias, fy * bias);
    }

    // 2b. Edge-avoidance — push nodes away from unrelated edges so no node
    // sits on top of a line connecting two others.
    for (final edge in _graph.edges) {
      final s = edge.source;
      final e = edge.destination;
      final p1 = _centerOf(s);
      final p2 = _centerOf(e);
      final ex = p2.dx - p1.dx;
      final ey = p2.dy - p1.dy;
      final elen2 = ex * ex + ey * ey;
      if (elen2 < 1) continue;
      for (final n in nodes) {
        if (n == s || n == e) continue;
        final cn = _centerOf(n);
        // Project cn onto segment p1→p2.
        var t = ((cn.dx - p1.dx) * ex + (cn.dy - p1.dy) * ey) / elen2;
        if (t < 0 || t > 1) continue; // only push when inside the span
        final px = p1.dx + ex * t;
        final py = p1.dy + ey * t;
        var dx = cn.dx - px;
        var dy = cn.dy - py;
        var d2 = dx * dx + dy * dy;
        final r = n.width / 2 + _labelFootprint + _collidePadding;
        if (d2 > r * r) continue;
        if (d2 < 0.01) {
          dx = -ey;
          dy = ex;
          d2 = ex * ex + ey * ey;
        }
        final d = math.sqrt(d2);
        final push = (r - d) * 0.3; // gentle shove
        forces[n] = forces[n]! + Offset((dx / d) * push, (dy / d) * push);
      }
    }

    // 3. Center pull
    for (final n in nodes) {
      final c = _centerOf(n);
      forces[n] =
          forces[n]! +
          Offset((cx - c.dx) * _centerStrength, (cy - c.dy) * _centerStrength);
    }

    // Integrate: velocity += force * alpha; velocity *= (1 - decay); pos += vel
    for (final n in nodes) {
      if (n == _draggingNode || _pinned.contains(n)) {
        _velocity[n] = Offset.zero;
        continue;
      }
      var v = (_velocity[n] ?? Offset.zero) + forces[n]! * _alpha;
      v = v * (1 - _velocityDecay);
      _velocity[n] = v;
      _setCenter(n, _centerOf(n) + v);
    }

    // 4. Collide — hard non-overlap pass (iterated)
    for (int iter = 0; iter < _collideIters; iter++) {
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final a = nodes[i];
          final b = nodes[j];
          final ra = a.width / 2 + _labelFootprint;
          final rb = b.width / 2 + _labelFootprint;
          final minDist = ra + rb + _collidePadding;
          final ca = _centerOf(a);
          final cb = _centerOf(b);
          var dx = cb.dx - ca.dx;
          var dy = cb.dy - ca.dy;
          var d2 = dx * dx + dy * dy;
          final min2 = minDist * minDist;
          if (d2 < min2 && d2 > 0) {
            final d = math.sqrt(d2);
            final overlap = (minDist - d) / 2;
            final ox = (dx / d) * overlap;
            final oy = (dy / d) * overlap;
            if (a != _draggingNode && !_pinned.contains(a)) {
              _setCenter(a, ca - Offset(ox, oy));
            }
            if (b != _draggingNode && !_pinned.contains(b)) {
              _setCenter(b, cb + Offset(ox, oy));
            }
          } else if (d2 == 0) {
            // Exact overlap — nudge apart.
            if (b != _draggingNode && !_pinned.contains(b)) {
              _setCenter(b, cb + const Offset(1, 0));
            }
          }
        }
      }
    }

    _alpha +=
        (-_alpha) *
        _alphaDecay; // alpha += (alphaTarget - alpha) * decay; target = 0
  }

  void _startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (_alpha < _alphaMin && !_isDragging) {
        t.cancel();
        return;
      }
      _tick();
      // Hold the focused node under the camera as the layout settles. During
      // the flight itself _driveCamera already re-reads its position.
      if (_followNodeId != null && !_camera.isAnimating) {
        _viewer.value = _viewCentredOn(_followNodeId!) ?? _viewer.value;
      }
      if (mounted) setState(() {});
    });
  }

  void _reheat([double target = _reheatAlpha]) {
    if (_alpha < target) _alpha = target;
    if (_timer == null || !_timer!.isActive) _startSimulation();
  }

  Node? _nodeById(String id) {
    for (final n in _graph.nodes) {
      if (n.key?.value == id) return n;
    }
    return null;
  }

  /// The transform that parks [id]'s current centre at the focus point.
  Matrix4? _viewCentredOn(String id) {
    final node = _nodeById(id);
    if (node == null) return null;
    final c = _centerOf(node);
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
    final to = _flyTo ?? (_followNodeId == null ? null : _viewCentredOn(_followNodeId!));
    if (to == null) return;
    _viewer.value =
        _lerpView(from, to, Curves.easeOutCubic.transform(_camera.value));
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
    _timer?.cancel();
    _camera.dispose();
    _viewer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(
                  painter: DotPatternPainter(
                      color: context.custom.graphDotPattern))),
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
                painter: DotPatternPainter(
                    color: context.custom.graphDotPattern))),

        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onCanvasTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 400.0;
              final h = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 800.0;

              if (!_initialized) {
                _initPhysics(w, h);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _startSimulation();
                });
              }

              return SafeInteractiveViewer(
                constrained: false,
                minScale: 0.3,
                maxScale: 4.0,
                controller: _viewer,
                onInteractionStart: () {
                  _releaseCamera();
                  widget.onInteractingChanged?.call(true);
                },
                onInteractionEnd: () =>
                    widget.onInteractingChanged?.call(false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(_graphW, _graphH),
                      painter: EdgePainter(
                        graph: _graph,
                        selectedNodeId: widget.selectedNodeId,
                        dim: widget.isSearching,
                        restColor: context.custom.neutral300,
                        highlightColor:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    ..._graph.nodes.map((node) {
                      final nodeId = node.key!.value as String;
                      final nodeData = widget.nodes
                          .where((n) => n.eventId == nodeId)
                          .firstOrNull;
                      // Nodes are coloured by type (saved / own / draft) —
                      // the same fixed palette for the unscoped Brahma graph
                      // and every Manas-scoped view.
                      final color = nodeData != null
                          ? graphNodeTypeColorsOf(context)[nodeData.type]!
                          : Theme.of(context).colorScheme.primary;
                      final nodeSize = _sizeFor(nodeId);
                      final isSelected = widget.selectedNodeId == nodeId;
                      final isConnected =
                          widget.selectedNodeId != null &&
                          (widget.adjacency[widget.selectedNodeId]?.contains(
                                nodeId,
                              ) ??
                              false);
                      final hasSelection = widget.selectedNodeId != null;
                      // A search match glows like a connected node; while
                      // searching, search highlighting takes precedence over
                      // the selection dim.
                      final isSearchMatch = widget.isSearching &&
                          widget.matchedNodeIds.contains(nodeId);
                      final double opacity;
                      if (widget.isSearching) {
                        opacity = isSearchMatch ? 1.0 : 0.18;
                      } else {
                        opacity = hasSelection && !isSelected && !isConnected
                            ? 0.25
                            : 1.0;
                      }

                      return Positioned(
                        left: node.x - (_labelWidth - nodeSize) / 2,
                        top: node.y,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onNodeTap(nodeId),
                          onPanStart: (_) {
                            _releaseCamera();
                            _isDragging = true;
                            _draggingNode = node;
                            _pinned.remove(node);
                            _velocity[node] = Offset.zero;
                            _reheat(0.5);
                            widget.onInteractingChanged?.call(true);
                          },
                          onPanUpdate: (details) {
                            node.position = node.position + details.delta;
                            if (mounted) setState(() {});
                          },
                          onPanEnd: (_) {
                            _isDragging = false;
                            _pinned.add(node);
                            _draggingNode = null;
                            _reheat();
                            widget.onInteractingChanged?.call(false);
                          },
                          onPanCancel: () {
                            _isDragging = false;
                            _pinned.add(node);
                            _draggingNode = null;
                            _reheat();
                            widget.onInteractingChanged?.call(false);
                          },
                          onDoubleTap: () {
                            _pinned.remove(node);
                            _reheat();
                          },
                          child: Opacity(
                            opacity: opacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: nodeSize,
                                  height: nodeSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ||
                                            isConnected ||
                                            isSearchMatch
                                        ? color
                                        : color.withValues(alpha: 0.85),
                                    border: isSelected || isSearchMatch
                                        ? Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            width: 2.5,
                                          )
                                        : null,
                                    boxShadow: isSelected || isSearchMatch
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.55,
                                              ),
                                              blurRadius: 18,
                                              spreadRadius: 4,
                                            ),
                                          ]
                                        : isConnected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: _labelWidth,
                                  child: Text(
                                    _labelFor(nodeId),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected || isSearchMatch
                                          ? color
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected || isSearchMatch
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ), // GestureDetector
      ],
    );
  }

  String _labelFor(String nodeId) {
    try {
      final node = widget.nodes.firstWhere((n) => n.eventId == nodeId);
      final text = stripMarkdownPreview(node.content).trim().replaceAll('\n', ' ');
      return text.length > 30 ? '${text.substring(0, 30)}…' : text;
    } catch (_) {
      return '…';
    }
  }
}
