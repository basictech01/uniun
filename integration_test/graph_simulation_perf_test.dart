// Device test: the graph layout must fit a 60 fps frame on a real phone.
//
//   flutter test integration_test/graph_simulation_perf_test.dart -d <device-id>
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uniun/features/brahma/graph/layout/graph_simulation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  GraphSimulation sim(int n) {
    final rng = math.Random(7);
    return GraphSimulation(
      ids: [for (var i = 0; i < n; i++) 'n$i'],
      radii: List.filled(n, 9),
      links: [
        for (var i = 1; i < n; i++) (rng.nextInt(i), i),
        for (var k = 0; k < n ~/ 3; k++) (rng.nextInt(n), rng.nextInt(n)),
      ].where((e) => e.$1 != e.$2).toList(),
      center: const Offset2(200, 400),
    );
  }

  for (final n in [100, 300, 500]) {
    test('$n nodes: a tick fits a frame, and the layout settles', () {
      final s = sim(n);
      final watch = Stopwatch()..start();
      var ticks = 0;
      while (!s.isSettled && ticks < 1000) {
        s.tick();
        ticks++;
      }
      final perTick = watch.elapsedMicroseconds / ticks / 1000;
      // ignore: avoid_print
      print(
        'GRAPH $n nodes: $ticks ticks to settle, '
        '${perTick.toStringAsFixed(2)} ms per tick, '
        '${(watch.elapsedMilliseconds)} ms total',
      );
      expect(s.isSettled, isTrue);
      expect(perTick, lessThan(16), reason: 'must fit a 60 fps frame');
    });
  }
}
