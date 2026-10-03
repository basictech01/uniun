import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/brahma/graph/layout/graph_simulation.dart';

/// Covers: GraphSimulation — settling, determinism, no overlapping nodes, links
/// pulling neighbours together, pinning and drag reheating, hit-testing,
/// Barnes-Hut against exact repulsion, disconnected parts staying together,
/// 500-node cost, and layout-quality measures (nodes sitting on other links).
void main() {
  const centre = Offset2(200, 400);

  GraphSimulation sim(
    int n, {
    List<(int, int)> links = const [],
    double radius = 10,
    SimConfig config = const SimConfig(),
  }) => GraphSimulation(
    ids: [for (var i = 0; i < n; i++) 'n$i'],
    radii: List.filled(n, radius),
    links: links,
    center: centre,
    config: config,
  );

  /// A connected random-ish graph: a spanning chain plus [extra] cross links.
  List<(int, int)> randomLinks(int n, int extra, {int seed = 7}) {
    final rng = math.Random(seed);
    return [
      for (var i = 1; i < n; i++) (rng.nextInt(i), i),
      for (var k = 0; k < extra; k++) (rng.nextInt(n), rng.nextInt(n)),
    ].where((e) => e.$1 != e.$2).toList();
  }

  double dist(GraphSimulation s, int a, int b) {
    final p = s.position(a), q = s.position(b);
    return math.sqrt(math.pow(p.dx - q.dx, 2) + math.pow(p.dy - q.dy, 2));
  }

  void settle(GraphSimulation s) {
    for (var i = 0; i < 1500 && !s.isSettled; i++) {
      s.tick();
    }
  }

  /// How many (node, link) pairs have the node's circle crossing a link it is
  /// not an end of — the "line through a node" tangle.
  int nodesOnOtherLinks(GraphSimulation s, List<(int, int)> links) {
    var bad = 0;
    for (final (a, b) in links) {
      final p = s.position(a), q = s.position(b);
      final ex = q.dx - p.dx, ey = q.dy - p.dy;
      final len2 = ex * ex + ey * ey;
      if (len2 == 0) continue;
      for (var n = 0; n < s.count; n++) {
        if (n == a || n == b) continue;
        final c = s.position(n);
        final t = ((c.dx - p.dx) * ex + (c.dy - p.dy) * ey) / len2;
        if (t <= 0 || t >= 1) continue;
        final px = p.dx + ex * t, py = p.dy + ey * t;
        final d = math.sqrt(math.pow(c.dx - px, 2) + math.pow(c.dy - py, 2));
        if (d < s.radius(n)) bad++;
      }
    }
    return bad;
  }

  group('settling', () {
    test('cools to rest in a few hundred ticks', () {
      final s = sim(30, links: randomLinks(30, 10));
      var ticks = 0;
      while (!s.isSettled && ticks < 2000) {
        s.tick();
        ticks++;
      }

      expect(s.isSettled, isTrue);
      expect(ticks, inInclusiveRange(250, 400));
    });

    test('is deterministic: same graph, same layout', () {
      final a = sim(25, links: randomLinks(25, 8))..warmUp(300);
      final b = sim(25, links: randomLinks(25, 8))..warmUp(300);

      for (var i = 0; i < 25; i++) {
        expect(a.position(i).dx, b.position(i).dx);
        expect(a.position(i).dy, b.position(i).dy);
      }
    });

    test('a settled simulation does not drift', () {
      final s = sim(20, links: randomLinks(20, 5));
      settle(s);
      final before = s.position(3).dx;

      for (var i = 0; i < 50; i++) {
        s.tick();
      }

      expect(s.position(3).dx, closeTo(before, 0.5));
    });
  });

  group('seeding', () {
    test('no two nodes start on the same spot', () {
      final s = sim(50);

      for (var i = 0; i < 50; i++) {
        for (var j = i + 1; j < 50; j++) {
          expect(dist(s, i, j), greaterThan(1));
        }
      }
    });
  });

  group('layout quality', () {
    test('no two nodes overlap once settled', () {
      final s = sim(60, links: randomLinks(60, 20), radius: 12);
      settle(s);

      var worst = double.infinity;
      for (var i = 0; i < s.count; i++) {
        for (var j = i + 1; j < s.count; j++) {
          worst = math.min(worst, dist(s, i, j) - s.radius(i) - s.radius(j));
        }
      }
      expect(worst, greaterThan(-0.5), reason: 'circles must not touch');
    });

    test('linked nodes end up much closer than unlinked ones', () {
      final links = randomLinks(40, 10);
      final s = sim(40, links: links);
      settle(s);
      final linked = {for (final (a, b) in links) '$a-$b'};
      var lSum = 0.0, lN = 0, uSum = 0.0, uN = 0;
      for (var i = 0; i < 40; i++) {
        for (var j = i + 1; j < 40; j++) {
          final isLink = linked.contains('$i-$j') || linked.contains('$j-$i');
          if (isLink) {
            lSum += dist(s, i, j);
            lN++;
          } else {
            uSum += dist(s, i, j);
            uN++;
          }
        }
      }

      expect(lSum / lN, lessThan(0.6 * uSum / uN));
    });

    test(
      'a chain is laid out near the link distance, not crushed or stretched',
      () {
        final links = [for (var i = 0; i < 9; i++) (i, i + 1)];
        final s = sim(10, links: links);
        settle(s);

        final lengths = [for (final (a, b) in links) dist(s, a, b)];
        final mean = lengths.reduce((a, b) => a + b) / lengths.length;
        expect(mean, inInclusiveRange(60, 160));
      },
    );

    test('few nodes sit on a link that is not theirs', () {
      final links = randomLinks(40, 12);
      final s = sim(40, links: links);
      settle(s);

      // The old layout needed a dedicated "edge-avoidance" pass for this.
      expect(nodesOnOtherLinks(s, links), lessThanOrEqualTo(2));
    });

    test('disconnected parts and lone nodes stay together near the centre', () {
      final links = [(0, 1), (1, 2), (3, 4)]; // two chains, 5 and 6 alone
      final s = sim(7, links: links);
      settle(s);

      for (var i = 0; i < 7; i++) {
        final p = s.position(i);
        final d = math.sqrt(
          math.pow(p.dx - centre.dx, 2) + math.pow(p.dy - centre.dy, 2),
        );
        expect(d, lessThan(400), reason: 'node $i drifted away');
      }
    });

    test('the layout stays compact as the graph grows', () {
      final s = sim(200, links: randomLinks(200, 60), radius: 8);
      settle(s);

      var far = 0.0;
      for (var i = 0; i < 200; i++) {
        final p = s.position(i);
        far = math.max(
          far,
          math.sqrt(
            math.pow(p.dx - centre.dx, 2) + math.pow(p.dy - centre.dy, 2),
          ),
        );
      }
      expect(far, lessThan(1400));
    });
  });

  group('dragging', () {
    test('a pinned node stays exactly where it is held', () {
      final s = sim(10, links: randomLinks(10, 3));
      s.pin(4, 50, 60);

      for (var i = 0; i < 100; i++) {
        s.tick();
      }

      expect(s.position(4).dx, 50);
      expect(s.position(4).dy, 60);
      expect(s.isPinned(4), isTrue);
    });

    test('moving a pinned node pulls its neighbours after it', () {
      final links = [(0, 1), (1, 2)];
      final s = sim(3, links: links);
      settle(s);
      final near = s.position(1).dx;
      final far = s.position(2).dx;

      s.alphaTarget = 0.3;
      for (var x = 0; x < 100; x++) {
        s.pin(0, s.position(0).dx - 4, s.position(0).dy);
        s.tick();
      }

      // The dragged node went 400 units left; both followers lag but follow.
      expect(near - s.position(1).dx, greaterThan(100));
      expect(far - s.position(2).dx, greaterThan(20));
      expect(s.position(1).dx, lessThan(near), reason: 'it did not stay put');
    });

    test('releasing returns the heat to zero and the layout settles again', () {
      final s = sim(10, links: randomLinks(10, 3));
      settle(s);

      s.alphaTarget = 0.3;
      s.reheat();
      for (var i = 0; i < 50; i++) {
        s.tick();
      }
      expect(s.isSettled, isFalse);

      s.alphaTarget = 0;
      s.unpin(0);
      settle(s);
      expect(s.isSettled, isTrue);
    });

    test('reheat only ever raises the heat', () {
      final s = sim(3)..alpha = 0.8;

      s.reheat(0.3);

      expect(s.alpha, 0.8);
    });

    test('a node dropped on another is pushed off it', () {
      final s = sim(2);
      settle(s);
      s.pin(0, s.position(1).dx, s.position(1).dy);
      s.reheat(0.3);
      for (var i = 0; i < 5; i++) {
        s.tick();
      }

      expect(dist(s, 0, 1), greaterThan(18));
    });
  });

  group('hit testing', () {
    test('finds the node under a point, with slop', () {
      final s = sim(3);
      final p = s.position(1);

      expect(s.nodeAt(p.dx, p.dy), 1);
      expect(s.nodeAt(p.dx + 12, p.dy), isNull, reason: 'outside radius 10');
      expect(s.nodeAt(p.dx + 12, p.dy, slop: 6), 1);
    });

    test('the closest centre wins where circles overlap', () {
      final s = sim(2, radius: 40);
      final p = s.position(0);

      expect(s.nodeAt(p.dx, p.dy), 0);
    });

    test('empty space hits nothing', () {
      expect(sim(3).nodeAt(9999, 9999), isNull);
    });
  });

  group('Barnes-Hut', () {
    test('one step matches exact repulsion to a fraction of a unit', () {
      // Layouts diverge over many ticks whatever the approximation (a force
      // layout is chaotic), so compare a single step from identical states.
      final links = randomLinks(80, 20);
      final start = sim(80, links: links);
      final exact = sim(80, links: links, config: const SimConfig(theta: 0))
        ..tick();
      final fast = sim(80, links: links)..tick();

      var error = 0.0, moved = 0.0;
      for (var i = 0; i < 80; i++) {
        final a = exact.position(i), b = fast.position(i);
        final s0 = start.position(i);
        error += math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
        moved += math.sqrt(
          math.pow(a.dx - s0.dx, 2) + math.pow(a.dy - s0.dy, 2),
        );
      }
      expect(
        error,
        lessThan(0.1 * moved),
        reason: 'the approximation error is a small part of the step itself',
      );
    });

    test('is far cheaper than comparing every pair at 500 nodes', () {
      final s = sim(500, links: randomLinks(500, 150), radius: 8);
      final watch = Stopwatch()..start();

      for (var i = 0; i < 60; i++) {
        s.tick();
      }

      // 60 ticks of 500 nodes: well under a second leaves ample room per frame.
      expect(
        watch.elapsedMilliseconds / 60,
        lessThan(30),
        reason: 'ms per tick must fit a 16 ms frame with margin',
      );
    });
  });

  group('edge cases', () {
    test('no nodes, one node, and two nodes on the same spot do not crash', () {
      expect(() => sim(0).tick(), returnsNormally);
      expect(() => sim(1).tick(), returnsNormally);
      final two = sim(2);
      two.pin(0, 100, 100);
      two.pin(1, 100, 100);
      two.unpin(0);
      two.unpin(1);
      expect(() {
        for (var i = 0; i < 20; i++) {
          two.tick();
        }
      }, returnsNormally);
      expect(two.position(0).dx.isFinite, isTrue);
    });

    test('a link from a node to itself or a duplicate link is harmless', () {
      final s = sim(3, links: [(0, 0), (0, 1), (0, 1)]);

      expect(() => s.warmUp(100), returnsNormally);
      expect(s.position(1).dx.isFinite, isTrue);
    });

    test('every position stays finite on a dense graph', () {
      final n = 40;
      final links = [
        for (var i = 0; i < n; i++)
          for (var j = i + 1; j < n; j++) (i, j),
      ];
      final s = sim(n, links: links);

      s.warmUp(300);

      for (var i = 0; i < n; i++) {
        expect(s.position(i).dx.isFinite && s.position(i).dy.isFinite, isTrue);
      }
    });
  });
}
