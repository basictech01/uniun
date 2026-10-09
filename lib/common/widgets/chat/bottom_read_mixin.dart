import 'package:flutter/material.dart';

/// Marks a chat-like surface (group, private group, DM) read whenever its list
/// sits at the newest note and the user can actually see it.
///
/// A scroll listener alone is not enough: a chat that opens already at the
/// newest note, or a note that arrives while the user is at the bottom, never
/// scrolls, so nothing would mark it. This mixin also checks after the first
/// frame, whenever the list's content changes ([contentChanged]) and when the
/// app comes back to the foreground.
mixin BottomReadMixin<T extends StatefulWidget> on State<T> {
  /// Pixels from the newest edge that still count as "at the bottom".
  static const double bottomTolerance = 8;

  /// A note counts as read once at least this much of it has been on screen.
  static const double visibleReadFraction = 0.5;

  ScrollController get readScrollController;

  /// True for a `reverse: true` list, where the newest note is at offset 0.
  bool get readListReversed => false;

  /// Hook for a surface that is not allowed to mark read yet (the group feed
  /// still has newer unread notes to load).
  bool get canMarkRead => true;

  /// Mark the whole container read. Must be idempotent.
  void markContainerRead();

  bool _markedAtBottom = false;
  bool _foreground = true;
  int _lastCount = -1;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        if (_foreground) {
          _markedAtBottom = false;
          scheduleBottomCheck();
        }
      },
    );
    scheduleBottomCheck();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  bool get _onTop => ModalRoute.of(context)?.isCurrent ?? true;

  bool get isAtBottom {
    final c = readScrollController;
    if (!c.hasClients) return false;
    final p = c.position;
    return readListReversed
        ? p.pixels <= p.minScrollExtent + bottomTolerance
        : p.pixels >= p.maxScrollExtent - bottomTolerance;
  }

  /// Call from a note's visibility callback: marks the note read as soon as
  /// enough of it is on screen, not when it later scrolls away (a note still on
  /// screen when the user goes back would never be marked). The callback can
  /// arrive after the page is gone, so a disposed page ignores it.
  void markIfOnScreen(
    String eventId,
    double visibleFraction,
    void Function(String eventId) markNote,
  ) {
    if (!mounted || visibleFraction < visibleReadFraction) return;
    markNote(eventId);
  }

  /// Call from the scroll listener.
  void onReadScroll() => _check();

  /// Call from `build` with the number of notes shown. When it changes (a note
  /// arrived, a page loaded) the bottom is checked again after layout.
  void contentChanged(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    _markedAtBottom = false;
    scheduleBottomCheck();
  }

  /// Re-check after the next frame (for example after returning from a thread).
  void scheduleBottomCheck() {
    // A post-frame callback does not ask for a frame; make sure one comes.
    WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  void _check() {
    // Nothing shown yet (still loading): marking now would read notes the user
    // has not seen.
    if (_lastCount <= 0) return;
    if (!mounted || !_foreground || !_onTop || !canMarkRead) return;
    if (!isAtBottom) {
      _markedAtBottom = false;
      return;
    }
    if (_markedAtBottom) return;
    _markedAtBottom = true;
    markContainerRead();
  }
}
