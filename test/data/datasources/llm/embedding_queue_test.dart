import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';

/// [EmbeddingQueue]: one embed in flight, interactive requests ahead of
/// queued background ones, and a slot freed even when the work throws.
void main() {
  Future<void> pause([int ms = 10]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  group('one at a time', () {
    test('caps in-flight at 1', () async {
      final q = EmbeddingQueue();
      var maxInFlight = 0, current = 0;

      Future<void> task() async {
        current++;
        if (current > maxInFlight) maxInFlight = current;
        await pause(20);
        current--;
      }

      await Future.wait(List.generate(6, (_) => q.run(task)));

      expect(maxInFlight, 1);
    });

    test('returns the work result', () async {
      expect(await EmbeddingQueue().run<String>(() async => 'hello'), 'hello');
    });

    test('a thousand queued tasks all run, in order', () async {
      final q = EmbeddingQueue();
      final order = <int>[];

      await Future.wait([
        for (var i = 0; i < 1000; i++) q.run(() async => order.add(i)),
      ]);

      expect(order, List.generate(1000, (i) => i));
    });
  });

  group('failures free the slot', () {
    test('a throw does not block the next task', () async {
      final q = EmbeddingQueue();

      await q
          .run(() => Future<void>.error(Exception('boom')))
          .catchError((_) {});
      final ok = await q
          .run<int>(() async => 42)
          .timeout(const Duration(seconds: 1));

      expect(ok, 42);
    });

    test('the error reaches the caller', () async {
      final q = EmbeddingQueue();

      await expectLater(
        q.run(() => Future<void>.error(StateError('model closed'))),
        throwsA(isA<StateError>()),
      );
    });

    test('a throw while others wait still lets them run', () async {
      final q = EmbeddingQueue();
      final ran = <String>[];
      final first = q
          .run<void>(() async {
            await pause(30);
            throw Exception('first fails');
          })
          .then<void>((_) {}, onError: (_) {});
      await pause();

      final second = q.run(() async => ran.add('second'));
      final third = q.run(() async => ran.add('third'));
      await Future.wait([first, second, third]);

      expect(ran, ['second', 'third']);
    });
  });

  group('priority', () {
    test('background waiters are served first-come first-served', () async {
      final q = EmbeddingQueue();
      final order = <int>[];
      final pin = q.run<void>(() => pause(60));
      await pause();

      final waiters = [
        for (var i = 3; i <= 5; i++) q.run<void>(() async => order.add(i)),
      ];
      await Future.wait([pin, ...waiters]);

      expect(order, [3, 4, 5]);
    });

    test(
      'an interactive request goes ahead of queued background work',
      () async {
        final q = EmbeddingQueue();
        final order = <String>[];
        final pin = q.run<void>(() async {
          await pause(60);
          order.add('in flight');
        });
        await pause();

        final bg1 = q.run<void>(() async => order.add('bg1'));
        final bg2 = q.run<void>(() async => order.add('bg2'));
        final question = q.run<void>(
          () async => order.add('question'),
          priority: EmbedPriority.interactive,
        );
        await Future.wait([pin, bg1, bg2, question]);

        expect(order, ['in flight', 'question', 'bg1', 'bg2']);
      },
    );

    test('it never interrupts the one already running', () async {
      final q = EmbeddingQueue();
      final order = <String>[];
      final running = q.run<void>(() async {
        order.add('start');
        await pause(60);
        order.add('end');
      });
      await pause();

      final question = q.run<void>(
        () async => order.add('question'),
        priority: EmbedPriority.interactive,
      );
      await Future.wait([running, question]);

      expect(order, ['start', 'end', 'question']);
    });

    test('interactive requests keep their own order', () async {
      final q = EmbeddingQueue();
      final order = <int>[];
      final pin = q.run<void>(() => pause(60));
      await pause();

      final asks = [
        for (var i = 1; i <= 3; i++)
          q.run<void>(
            () async => order.add(i),
            priority: EmbedPriority.interactive,
          ),
      ];
      await Future.wait([pin, ...asks]);

      expect(order, [1, 2, 3]);
    });

    test('background work still runs once the questions are done', () async {
      final q = EmbeddingQueue();
      final order = <String>[];
      final pin = q.run<void>(() => pause(40));
      await pause();

      final bg = q.run<void>(() async => order.add('bg'));
      final ask1 = q.run<void>(
        () async => order.add('q1'),
        priority: EmbedPriority.interactive,
      );
      final ask2 = q.run<void>(
        () async => order.add('q2'),
        priority: EmbedPriority.interactive,
      );
      await Future.wait([pin, bg, ask1, ask2]);

      expect(order, ['q1', 'q2', 'bg']);
    });

    test('the default priority is background', () async {
      final q = EmbeddingQueue();
      final order = <String>[];
      final pin = q.run<void>(() => pause(40));
      await pause();

      final defaulted = q.run<void>(() async => order.add('default'));
      final question = q.run<void>(
        () async => order.add('question'),
        priority: EmbedPriority.interactive,
      );
      await Future.wait([pin, defaulted, question]);

      expect(order, ['question', 'default']);
    });

    test('an idle queue runs an interactive request immediately', () async {
      final q = EmbeddingQueue();

      final ran = await q
          .run<bool>(() async => true, priority: EmbedPriority.interactive)
          .timeout(const Duration(seconds: 1));

      expect(ran, isTrue);
    });
  });
}
