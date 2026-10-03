import 'dart:math' as math;
import 'dart:typed_data';

/// Constants of the force layout, in graph units (logical pixels at zoom 1).
///
/// The shape follows d3-force as Quartz uses it to mirror Obsidian's graph —
/// repulsion balanced by a gentle centre pull, short links, nodes that never
/// overlap — scaled up for finger-sized nodes: lengths ×3, so the many-body
/// strength (which acts as strength/distance) is ×9 to keep the same balance.
class SimConfig {
  const SimConfig({
    this.charge = -500,
    this.linkDistance = 90,
    this.centerStrength = 0.05,
    this.collidePadding = 5,
    this.collideExtra = 0,
    this.collideIterations = 2,
    this.velocityDecay = 0.4,
    this.alphaMin = 0.001,
    this.alphaDecay = 0.0228,
    this.theta = 0.9,
    this.distanceMax = 900,
  });

  /// Repulsion between every pair (negative pushes apart).
  final double charge;

  /// Rest length of a link.
  final double linkDistance;

  /// Pull of each node towards the centre, per unit of distance.
  final double centerStrength;

  /// Gap kept between two nodes' circles.
  final double collidePadding;

  /// Room added around every node when separating them but not when hit-testing
  /// — the space a label hanging under the circle needs.
  final double collideExtra;

  final int collideIterations;

  /// Share of velocity lost each tick.
  final double velocityDecay;

  /// The simulation is settled once its heat falls below this.
  final double alphaMin;

  /// Cooling rate: heat decays by this share each tick (≈300 ticks to settle).
  final double alphaDecay;

  /// Barnes-Hut accuracy: a distant cluster is treated as one body when
  /// cell width / distance is below this. 0 is exact.
  final double theta;

  /// Repulsion is ignored beyond this distance.
  final double distanceMax;
}

/// A force-directed layout, advanced one [tick] at a time. Pure Dart: no
/// Flutter, so it is unit-tested directly and a widget only draws its result.
///
/// Mirrors d3-force: a heat (`alpha`) that decays towards `alphaTarget`; forces
/// add to velocities scaled by that heat; velocities decay; positions follow.
/// Repulsion uses a Barnes-Hut quadtree, so a tick is O(n log n) rather than
/// the O(n²) of comparing every pair.
class GraphSimulation {
  GraphSimulation({
    required List<String> ids,
    required List<double> radii,
    required List<(int, int)> links,
    this.config = const SimConfig(),
    this.center = Offset2.zero,
  }) : assert(ids.length == radii.length),
       count = ids.length,
       _ids = List.unmodifiable(ids),
       _radii = Float64List.fromList(radii),
       _links = List.unmodifiable(links),
       _x = Float64List(ids.length),
       _y = Float64List(ids.length),
       _vx = Float64List(ids.length),
       _vy = Float64List(ids.length),
       _pinned = List<bool>.filled(ids.length, false),
       _index = {for (var i = 0; i < ids.length; i++) ids[i]: i} {
    _degree = Int32List(count);
    for (final (a, b) in _links) {
      _degree[a]++;
      _degree[b]++;
    }
    _seed();
  }

  final SimConfig config;
  final Offset2 center;

  final int count;

  final List<String> _ids;
  final Float64List _radii;
  final List<(int, int)> _links;
  final Float64List _x;
  final Float64List _y;
  final Float64List _vx;
  final Float64List _vy;
  final List<bool> _pinned;
  final Map<String, int> _index;
  late final Int32List _degree;

  /// Heat: how far the forces still move nodes. 1 at the start, 0 when still.
  double alpha = 1;

  /// The heat the simulation cools towards. Dragging raises it so neighbours
  /// follow; releasing returns it to 0.
  double alphaTarget = 0;

  bool get isSettled => alpha < config.alphaMin && alphaTarget == 0;

  List<String> get ids => _ids;

  int? indexOf(String id) => _index[id];

  Offset2 position(int i) => Offset2(_x[i], _y[i]);

  double radius(int i) => _radii[i];

  int degree(int i) => _degree[i];

  bool isPinned(int i) => _pinned[i];

  /// Spreads nodes on a sunflower spiral around [center]: deterministic, evenly
  /// spaced, and none on top of another — so the first ticks have something to
  /// untangle rather than a knot.
  void _seed() {
    const golden = math.pi * (3 - 2.2360679775); // π(3 − √5)
    for (var i = 0; i < count; i++) {
      final r = 30 * math.sqrt(0.5 + i);
      final a = i * golden;
      _x[i] = center.dx + r * math.cos(a);
      _y[i] = center.dy + r * math.sin(a);
    }
  }

  /// Raises the heat so the layout re-settles, e.g. after a drag or when the
  /// graph changes.
  void reheat([double target = 0.3]) {
    if (alpha < target) alpha = target;
  }

  /// Holds node [i] at ([x], [y]) — a node being dragged, or one the user
  /// placed. Its velocity is zeroed so it does not spring away on release.
  void pin(int i, double x, double y) {
    _pinned[i] = true;
    _x[i] = x;
    _y[i] = y;
    _vx[i] = 0;
    _vy[i] = 0;
  }

  void unpin(int i) => _pinned[i] = false;

  /// Runs [n] ticks (to lay the graph out before it is first drawn).
  void warmUp(int n) {
    for (var i = 0; i < n && !isSettled; i++) {
      tick();
    }
  }

  /// The node whose circle (grown by [slop]) contains ([x], [y]), preferring
  /// the closest centre; `null` when none does.
  int? nodeAt(double x, double y, {double slop = 0}) {
    int? best;
    var bestD2 = double.infinity;
    for (var i = 0; i < count; i++) {
      final dx = _x[i] - x;
      final dy = _y[i] - y;
      final d2 = dx * dx + dy * dy;
      final r = _radii[i] + slop;
      if (d2 <= r * r && d2 < bestD2) {
        best = i;
        bestD2 = d2;
      }
    }
    return best;
  }

  /// One step: cool, apply forces, damp, move, then separate overlaps.
  void tick() {
    alpha += (alphaTarget - alpha) * config.alphaDecay;
    _linkForce();
    _chargeForce();
    _centerForce();
    final keep = 1 - config.velocityDecay;
    for (var i = 0; i < count; i++) {
      if (_pinned[i]) {
        _vx[i] = 0;
        _vy[i] = 0;
        continue;
      }
      _vx[i] *= keep;
      _vy[i] *= keep;
      _x[i] += _vx[i];
      _y[i] += _vy[i];
    }
    for (var it = 0; it < config.collideIterations; it++) {
      _collide();
    }
  }

  // Springs along links; d3's default strength 1/min(degree) keeps a hub from
  // being yanked by each of its many links, and the lighter end moves more.
  void _linkForce() {
    for (final (s, t) in _links) {
      var dx = _x[t] + _vx[t] - _x[s] - _vx[s];
      var dy = _y[t] + _vy[t] - _y[s] - _vy[s];
      var l = math.sqrt(dx * dx + dy * dy);
      if (l == 0) {
        dx = _jiggle(s, t);
        dy = _jiggle(t, s);
        l = math.sqrt(dx * dx + dy * dy);
      }
      final strength = 1 / math.min(_degree[s], _degree[t]);
      final k = (l - config.linkDistance) / l * alpha * strength;
      dx *= k;
      dy *= k;
      final bias = _degree[s] / (_degree[s] + _degree[t]);
      _vx[t] -= dx * bias;
      _vy[t] -= dy * bias;
      _vx[s] += dx * (1 - bias);
      _vy[s] += dy * (1 - bias);
    }
  }

  // A tiny deterministic nudge for two nodes exactly on top of each other.
  double _jiggle(int a, int b) => ((a * 7919 + b * 104729) % 1000 - 500) * 1e-6;

  void _centerForce() {
    final k = config.centerStrength * alpha;
    for (var i = 0; i < count; i++) {
      _vx[i] += (center.dx - _x[i]) * k;
      _vy[i] += (center.dy - _y[i]) * k;
    }
  }

  void _chargeForce() {
    if (count < 2) return;
    final tree = _Quad.build(_x, _y, count);
    final max2 = config.distanceMax * config.distanceMax;
    final theta2 = config.theta * config.theta;
    for (var i = 0; i < count; i++) {
      _visit(tree, i, max2, theta2);
    }
  }

  void _visit(_Quad q, int i, double max2, double theta2) {
    if (q.mass == 0) return;
    var dx = q.cx - _x[i];
    var dy = q.cy - _y[i];
    var d2 = dx * dx + dy * dy;
    final w = q.size;
    // Far enough: the whole cell acts as one body at its centre of mass.
    if (q.children == null || w * w / theta2 < d2) {
      if (q.children == null && q.single == i && q.mass == 1) return;
      if (d2 >= max2) return;
      if (d2 == 0) {
        dx = _jiggle(i, 1);
        dy = _jiggle(1, i);
        d2 = dx * dx + dy * dy;
      }
      // Very close pairs would fling apart; floor the distance at 1 unit.
      if (d2 < 1) d2 = math.sqrt(d2);
      final k = config.charge * alpha / d2 * q.mass;
      _vx[i] += dx * k;
      _vy[i] += dy * k;
      return;
    }
    for (final c in q.children!) {
      if (c != null) _visit(c, i, max2, theta2);
    }
  }

  // Hard non-overlap: push apart any two circles (plus padding) that touch.
  // A grid keeps it near-linear for a few hundred nodes.
  void _collide() {
    if (count < 2) return;
    var maxR = 0.0;
    for (var i = 0; i < count; i++) {
      if (_radii[i] > maxR) maxR = _radii[i];
    }
    final cell = 2 * (maxR + config.collideExtra) + config.collidePadding;
    final grid = <int, List<int>>{};
    int key(int cx, int cy) => cx * 73856093 ^ cy * 19349663;
    for (var i = 0; i < count; i++) {
      grid
          .putIfAbsent(
            key((_x[i] / cell).floor(), (_y[i] / cell).floor()),
            () => <int>[],
          )
          .add(i);
    }
    for (var i = 0; i < count; i++) {
      final gx = (_x[i] / cell).floor();
      final gy = (_y[i] / cell).floor();
      for (var ox = -1; ox <= 1; ox++) {
        for (var oy = -1; oy <= 1; oy++) {
          final bucket = grid[key(gx + ox, gy + oy)];
          if (bucket == null) continue;
          for (final j in bucket) {
            if (j <= i) continue;
            var dx = _x[j] - _x[i];
            var dy = _y[j] - _y[i];
            final min =
                _radii[i] +
                _radii[j] +
                2 * config.collideExtra +
                config.collidePadding;
            var d2 = dx * dx + dy * dy;
            if (d2 >= min * min) continue;
            if (d2 == 0) {
              dx = _jiggle(i, j) * 1000 + 0.5;
              dy = _jiggle(j, i) * 1000;
              d2 = dx * dx + dy * dy;
            }
            final d = math.sqrt(d2);
            final push = (min - d) / d / 2;
            final px = dx * push;
            final py = dy * push;
            if (!_pinned[i] && !_pinned[j]) {
              _x[i] -= px;
              _y[i] -= py;
              _x[j] += px;
              _y[j] += py;
            } else if (!_pinned[i]) {
              _x[i] -= px * 2;
              _y[i] -= py * 2;
            } else if (!_pinned[j]) {
              _x[j] += px * 2;
              _y[j] += py * 2;
            }
          }
        }
      }
    }
  }
}

/// A plain 2-D point, so this file needs no Flutter.
class Offset2 {
  const Offset2(this.dx, this.dy);
  static const zero = Offset2(0, 0);
  final double dx;
  final double dy;
}

/// A Barnes-Hut quadtree cell: the centre of mass and count of everything
/// beneath it.
class _Quad {
  _Quad(this.x0, this.y0, this.size);

  final double x0;
  final double y0;
  final double size;
  double cx = 0;
  double cy = 0;
  double mass = 0;
  int single = -1;
  List<_Quad?>? children;

  static _Quad build(Float64List xs, Float64List ys, int n) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i < n; i++) {
      if (xs[i] < minX) minX = xs[i];
      if (xs[i] > maxX) maxX = xs[i];
      if (ys[i] < minY) minY = ys[i];
      if (ys[i] > maxY) maxY = ys[i];
    }
    final size = math.max(maxX - minX, maxY - minY) + 1;
    final root = _Quad(minX, minY, size);
    for (var i = 0; i < n; i++) {
      root._insert(i, xs[i], ys[i], xs, ys, 0);
    }
    return root;
  }

  void _insert(
    int i,
    double x,
    double y,
    Float64List xs,
    Float64List ys,
    int depth,
  ) {
    // Running centre of mass.
    cx = (cx * mass + x) / (mass + 1);
    cy = (cy * mass + y) / (mass + 1);
    mass += 1;
    if (mass == 1) {
      single = i;
      return;
    }
    // Two points on the same spot, or too deep: keep them as one leaf.
    if (depth > 24) return;
    if (children == null) {
      children = List<_Quad?>.filled(4, null);
      final first = single;
      single = -1;
      if (first >= 0) _place(first, xs[first], ys[first], xs, ys, depth);
    }
    _place(i, x, y, xs, ys, depth);
  }

  void _place(
    int i,
    double x,
    double y,
    Float64List xs,
    Float64List ys,
    int depth,
  ) {
    final half = size / 2;
    final qx = x >= x0 + half ? 1 : 0;
    final qy = y >= y0 + half ? 1 : 0;
    final slot = qy * 2 + qx;
    final child = children![slot] ??= _Quad(
      x0 + qx * half,
      y0 + qy * half,
      half,
    );
    child._insert(i, x, y, xs, ys, depth + 1);
  }
}
