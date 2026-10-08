import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/chat/boundary_chat_list.dart';

Widget _list({
  required List<String> notes,
  required int boundary,
  required bool opened,
  required ScrollController controller,
  bool divider = true,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      height: 600,
      child: BoundaryChatList<String>(
        controller: controller,
        notes: notes,
        boundaryIndex: boundary,
        openedAtBoundary: opened,
        unreadDivider: divider
            ? const SizedBox(height: 40, child: Text('DIVIDER'))
            : null,
        itemBuilder: (_, n) => SizedBox(height: 80, child: Text(n)),
      ),
    ),
  ),
);

List<String> _notes(int n) => [for (var i = 0; i < n; i++) 'n$i'];

/// Covers: BoundaryChatList opening at the read→unread boundary or at the
/// newest note, the divider, and staying put when later notes arrive.
void main() {
  testWidgets('opens with the first unread note near the middle', (t) async {
    final c = ScrollController();
    await t.pumpWidget(
      _list(notes: _notes(60), boundary: 30, opened: true, controller: c),
    );

    final top = t.getTopLeft(find.text('n30')).dy;
    expect(top, inInclusiveRange(200, 400));
    expect(find.text('DIVIDER'), findsOneWidget);
    expect(find.text('n29'), findsOneWidget, reason: 'read notes sit above');
  });

  testWidgets('with nothing unread it opens at the newest note', (t) async {
    final c = ScrollController();
    await t.pumpWidget(
      _list(notes: _notes(60), boundary: 60, opened: false, controller: c),
    );

    expect(find.text('n59'), findsOneWidget);
    expect(find.text('DIVIDER'), findsNothing);
    expect(c.position.pixels, c.position.maxScrollExtent);
  });

  testWidgets('a note arriving after open does not move the view', (t) async {
    final c = ScrollController();
    await t.pumpWidget(
      _list(notes: _notes(60), boundary: 60, opened: false, controller: c),
    );
    final before = t.getTopLeft(find.text('n59')).dy;

    await t.pumpWidget(
      _list(notes: _notes(61), boundary: 60, opened: false, controller: c),
    );
    await t.pump();

    expect(t.getTopLeft(find.text('n59')).dy, before);
    expect(find.text('DIVIDER'), findsNothing);
  });

  testWidgets('older notes loading above do not shift what is on screen', (
    t,
  ) async {
    final c = ScrollController();
    final all = _notes(80);
    await t.pumpWidget(
      _list(notes: all.sublist(20), boundary: 30, opened: true, controller: c),
    );
    final before = t.getTopLeft(find.text('n50')).dy;

    await t.pumpWidget(
      _list(notes: all, boundary: 50, opened: true, controller: c),
    );
    await t.pump();

    expect(t.getTopLeft(find.text('n50')).dy, before);
  });

  testWidgets('every note unread: boundary at 0 still builds', (t) async {
    final c = ScrollController();
    await t.pumpWidget(
      _list(notes: _notes(5), boundary: 0, opened: true, controller: c),
    );

    expect(find.text('n0'), findsOneWidget);
    expect(find.text('DIVIDER'), findsOneWidget);
  });

  testWidgets('empty list and out-of-range boundary do not throw', (t) async {
    final c = ScrollController();
    await t.pumpWidget(
      _list(notes: const [], boundary: 7, opened: false, controller: c),
    );
    expect(tester(t), isTrue);

    await t.pumpWidget(
      _list(notes: _notes(3), boundary: 99, opened: false, controller: c),
    );
    expect(find.text('n2'), findsOneWidget);

    await t.pumpWidget(
      _list(notes: _notes(3), boundary: -4, opened: true, controller: c),
    );
    expect(find.text('n0'), findsOneWidget);
  });

  testWidgets('no divider widget given means none is drawn', (t) async {
    final c = ScrollController();
    await t.pumpWidget(
      _list(
        notes: _notes(10),
        boundary: 5,
        opened: true,
        controller: c,
        divider: false,
      ),
    );

    expect(find.text('DIVIDER'), findsNothing);
    expect(find.text('n5'), findsOneWidget);
  });
}

bool tester(WidgetTester t) => t.takeException() == null;
