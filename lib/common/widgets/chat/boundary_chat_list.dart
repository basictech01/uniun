import 'package:flutter/material.dart';

/// A chat list that opens at the read → unread boundary, like WhatsApp: the
/// first unread note sits near the middle of the screen with the notes you have
/// already read above it and the unread ones below. With nothing unread it opens
/// at the newest note.
///
/// [notes] is oldest first. Everything from [boundaryIndex] on is unread.
/// [unreadDivider], when given, is drawn right above the first unread note.
///
/// The notes before the boundary live in the sliver before the center, which
/// lays out upward, so loading older notes never moves what is on screen.
class BoundaryChatList<T> extends StatefulWidget {
  const BoundaryChatList({
    super.key,
    required this.controller,
    required this.notes,
    required this.boundaryIndex,
    required this.openedAtBoundary,
    required this.itemBuilder,
    this.unreadDivider,
    this.header,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final ScrollController controller;
  final List<T> notes;

  /// Index in [notes] of the first unread note; [notes.length] when all read.
  final int boundaryIndex;

  /// Whether the chat opened with unread notes. Fixed at open: notes that
  /// arrive later land below the boundary but must not move the view.
  final bool openedAtBoundary;
  final Widget Function(BuildContext context, T note) itemBuilder;
  final Widget? unreadDivider;

  /// Shown above the oldest loaded note.
  final Widget? header;
  final double topPadding;
  final double bottomPadding;

  @override
  State<BoundaryChatList<T>> createState() => _BoundaryChatListState<T>();
}

class _BoundaryChatListState<T> extends State<BoundaryChatList<T>> {
  final _centerKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final split = widget.boundaryIndex.clamp(0, widget.notes.length);
    final read = widget.notes.sublist(0, split);
    final unread = widget.notes.sublist(split);
    final hasDivider =
        widget.openedAtBoundary &&
        widget.unreadDivider != null &&
        unread.isNotEmpty;

    return CustomScrollView(
      controller: widget.controller,
      center: _centerKey,
      // First unread near the middle of the screen; otherwise the newest note
      // sits at the bottom like a normal chat.
      anchor: widget.openedAtBoundary ? 0.5 : 1.0,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (widget.header != null) SliverToBoxAdapter(child: widget.header),
        SliverPadding(
          padding: EdgeInsets.only(top: widget.topPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => widget.itemBuilder(ctx, read[read.length - 1 - i]),
              childCount: read.length,
            ),
          ),
        ),
        SliverList(
          key: _centerKey,
          delegate: SliverChildBuilderDelegate((ctx, i) {
            if (hasDivider) {
              if (i == 0) return widget.unreadDivider;
              return widget.itemBuilder(ctx, unread[i - 1]);
            }
            return widget.itemBuilder(ctx, unread[i]);
          }, childCount: unread.length + (hasDivider ? 1 : 0)),
        ),
        SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
      ],
    );
  }
}
