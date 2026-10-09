import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/chat/unread_count_cubit.dart';

/// Covers: UnreadCountCubit following a count stream and stopping on close.
void main() {
  blocTest<UnreadCountCubit, int>(
    'emits each count the stream reports',
    build: () => UnreadCountCubit(Stream.fromIterable([2, 5, 0])),
    expect: () => [2, 5, 0],
  );

  test('starts at 0 before the stream reports', () async {
    final c = StreamController<int>();
    final cubit = UnreadCountCubit(c.stream);

    expect(cubit.state, 0);

    await cubit.close();
    await c.close();
  });

  test('closing stops listening, so a late count is ignored', () async {
    final c = StreamController<int>();
    final cubit = UnreadCountCubit(c.stream);
    await cubit.close();

    c.add(9);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, 0);
    expect(c.hasListener, isFalse);
    await c.close();
  });
}
