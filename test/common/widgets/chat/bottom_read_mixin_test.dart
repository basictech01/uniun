import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/chat/bottom_read_mixin.dart';

class _Host extends StatefulWidget {
  const _Host({
    required this.count,
    this.reversed = false,
    this.allowed = true,
    super.key,
  });
  final int count;
  final bool reversed;
  final bool allowed;

  @override
  State<_Host> createState() => HostState();
}

class HostState extends State<_Host> with BottomReadMixin {
  final controller = ScrollController();
  int marks = 0;

  @override
  ScrollController get readScrollController => controller;
  @override
  bool get readListReversed => widget.reversed;
  @override
  bool get canMarkRead => widget.allowed;
  @override
  void markContainerRead() => marks++;

  @override
  void initState() {
    super.initState();
    controller.addListener(onReadScroll);
  }

  @override
  Widget build(BuildContext context) {
    contentChanged(widget.count);
    return ListView.builder(
      controller: controller,
      reverse: widget.reversed,
      itemCount: widget.count,
      itemBuilder: (_, i) => SizedBox(height: 100, child: Text('n$i')),
    );
  }
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Covers: BottomReadMixin marking a chat read on open, on arrival, on
/// reaching the bottom, and not when the user cannot see it.
void main() {
  Future<HostState> pump(
    WidgetTester t, {
    int count = 3,
    bool reversed = false,
    bool allowed = true,
  }) async {
    final key = GlobalKey<HostState>();
    await t.pumpWidget(
      _app(_Host(key: key, count: count, reversed: reversed, allowed: allowed)),
    );
    await t.pump();
    return key.currentState!;
  }

  testWidgets('a short chat that fits on screen is marked read on open', (
    t,
  ) async {
    final h = await pump(t);

    expect(h.marks, 1);
  });

  testWidgets('a reversed chat opened at the newest note is marked read', (
    t,
  ) async {
    final h = await pump(t, reversed: true);

    expect(h.marks, 1);
  });

  testWidgets('a long chat opened at the top is not marked until the bottom', (
    t,
  ) async {
    final h = await pump(t, count: 40);
    expect(h.marks, 0);

    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();

    expect(h.marks, 1);
  });

  testWidgets('scrolling back up and down again marks it once more', (t) async {
    final h = await pump(t, count: 40);
    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();
    h.controller.jumpTo(0);
    await t.pump();
    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();

    expect(h.marks, 2);
  });

  testWidgets('staying at the bottom does not mark on every scroll frame', (
    t,
  ) async {
    final h = await pump(t, count: 40);
    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();
    h.controller.jumpTo(h.controller.position.maxScrollExtent - 2);
    await t.pump();
    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();

    expect(h.marks, 1);
  });

  testWidgets('a note arriving while at the bottom is marked read', (t) async {
    final key = GlobalKey<HostState>();
    await t.pumpWidget(_app(_Host(key: key, count: 3)));
    await t.pump();
    expect(key.currentState!.marks, 1);

    await t.pumpWidget(_app(_Host(key: key, count: 4)));
    await t.pump();

    expect(key.currentState!.marks, 2);
  });

  testWidgets('a note arriving while scrolled up stays unread', (t) async {
    final key = GlobalKey<HostState>();
    await t.pumpWidget(_app(_Host(key: key, count: 40)));
    await t.pump();

    await t.pumpWidget(_app(_Host(key: key, count: 41)));
    await t.pump();

    expect(key.currentState!.marks, 0);
  });

  testWidgets('nothing is marked while the surface is not allowed to', (
    t,
  ) async {
    final h = await pump(t, allowed: false);

    expect(h.marks, 0);
  });

  testWidgets('nothing is marked while another page covers the chat', (
    t,
  ) async {
    final key = GlobalKey<HostState>();
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: _Host(key: key, count: 40),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('thread')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();

    key.currentState!.controller.jumpTo(
      key.currentState!.controller.position.maxScrollExtent,
    );
    await t.pump();

    expect(key.currentState!.marks, 0);
  });

  testWidgets('an empty list is not marked: nothing was shown yet', (t) async {
    final h = await pump(t, count: 0);

    expect(h.marks, 0);
  });

  testWidgets('a list that was empty while loading is marked once notes show', (
    t,
  ) async {
    final key = GlobalKey<HostState>();
    await t.pumpWidget(_app(_Host(key: key, count: 0)));
    await t.pump();
    expect(key.currentState!.marks, 0);

    await t.pumpWidget(_app(_Host(key: key, count: 3)));
    await t.pump();

    expect(key.currentState!.marks, 1);
  });

  testWidgets('going to the background and back checks again', (t) async {
    final h = await pump(t, count: 40);
    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();
    expect(h.marks, 1);

    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    h.controller.jumpTo(0);
    await t.pump();
    h.controller.jumpTo(h.controller.position.maxScrollExtent);
    await t.pump();
    expect(h.marks, 1, reason: 'backgrounded: no marking');

    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await t.pump();
    expect(h.marks, 2);
  });

  group('markIfOnScreen', () {
    Future<_PlainState> host(WidgetTester t) async {
      final key = GlobalKey<_PlainState>();
      await t.pumpWidget(_app(_Plain(key: key)));
      return key.currentState!;
    }

    testWidgets('a note at least half on screen is marked', (t) async {
      final h = await host(t);
      final seen = <String>[];

      h.markIfOnScreen('a', 0.5, seen.add);
      h.markIfOnScreen('b', 1, seen.add);

      expect(seen, ['a', 'b']);
    });

    testWidgets('a note less than half on screen is not marked', (t) async {
      final h = await host(t);
      final seen = <String>[];

      h.markIfOnScreen('a', 0.49, seen.add);
      h.markIfOnScreen('b', 0, seen.add);

      expect(seen, isEmpty);
    });

    testWidgets('a callback arriving after the page is gone is ignored', (
      t,
    ) async {
      final h = await host(t);
      await t.pumpWidget(const SizedBox());
      final seen = <String>[];

      h.markIfOnScreen('a', 1, seen.add);

      expect(seen, isEmpty);
    });
  });

  testWidgets('by default a surface is allowed to mark and is not reversed', (
    t,
  ) async {
    final key = GlobalKey<_PlainState>();
    await t.pumpWidget(_app(_Plain(key: key)));
    await t.pump();

    expect(key.currentState!.canMarkRead, isTrue);
    expect(key.currentState!.readListReversed, isFalse);
    expect(key.currentState!.marks, 1);
  });
}

/// A host that overrides only what is required, so the defaults run.
class _Plain extends StatefulWidget {
  const _Plain({super.key});

  @override
  State<_Plain> createState() => _PlainState();
}

class _PlainState extends State<_Plain> with BottomReadMixin {
  final controller = ScrollController();
  int marks = 0;

  @override
  ScrollController get readScrollController => controller;
  @override
  void markContainerRead() => marks++;

  @override
  Widget build(BuildContext context) {
    contentChanged(3);
    return ListView(
      controller: controller,
      children: const [SizedBox(height: 100), SizedBox(height: 100)],
    );
  }
}
