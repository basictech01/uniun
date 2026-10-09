import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Live number of unread notes in the open chat, shown on the jump-to-latest
/// button. Fed by one of the `Watch*UnreadCountUseCase` streams.
class UnreadCountCubit extends Cubit<int> {
  UnreadCountCubit(Stream<int> counts) : super(0) {
    _sub = counts.listen((n) {
      if (!isClosed) emit(n);
    });
  }

  late final StreamSubscription<int> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
