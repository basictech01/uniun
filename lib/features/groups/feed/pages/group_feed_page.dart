import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_card.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/features/groups/feed/bloc/group_feed_bloc.dart';
import 'package:uniun/features/groups/feed/bloc/group_feed_event.dart';
import 'package:uniun/features/groups/feed/bloc/group_feed_state.dart';
import 'package:uniun/common/widgets/composer/composer_host.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/nav_extensions.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/features/shiv/generation/chat_helpers.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/chat/boundary_chat_list.dart';
import 'package:uniun/common/widgets/chat/bottom_read_mixin.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/common/widgets/jump_to_bottom_button.dart';
import 'package:uniun/common/widgets/chat/unread_count_cubit.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class GroupFeedPage extends StatelessWidget {
  const GroupFeedPage({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              GroupFeedBloc()..add(LoadGroupFeedEvent(groupId)),
        ),
      ],
      child: _GroupFeedView(groupId: groupId),
    );
  }
}

class _GroupFeedView extends StatefulWidget {
  const _GroupFeedView({required this.groupId});
  final String groupId;

  @override
  State<_GroupFeedView> createState() => _GroupFeedViewState();
}

class _GroupFeedViewState extends State<_GroupFeedView>
    with BottomReadMixin {
  final _scrollController = ScrollController();

  late final UnreadCountCubit _unread;
  StreamSubscription<int>? _unreadSub;
  int _lastUnread = 0;

  /// Set when a note was pulled in for a user sitting at the bottom: once it
  /// lands, follow it down like a normal chat so it is on screen (and read).
  bool _followNewest = false;

  @override
  ScrollController get readScrollController => _scrollController;

  /// Newer unread notes still to load: marking now would mark unseen notes.
  @override
  bool get canMarkRead => !context.read<GroupFeedBloc>().state.hasMoreUnread;

  @override
  void markContainerRead() => context
      .read<GroupFeedBloc>()
      .add(MarkAllGroupSeenEvent(widget.groupId));

  /// Distance from an edge at which the next page is requested.
  static const double _loadTrigger = 240;

  /// Whether the jump-to-latest button is showing (set when scrolled above the
  /// bottom).
  bool _showJumpButton = false;

  @override
  void initState() {
    super.initState();
    _unread = UnreadCountCubit(
      getIt<WatchGroupUnreadCountUseCase>().call(widget.groupId),
    );
    // A note arriving while the user sits at the bottom is pulled in so it is
    // shown (and then read); scrolled up, the badge counts it instead.
    _unreadSub = _unread.stream.listen((n) {
      if (n > _lastUnread && mounted && isAtBottom) {
        _followNewest = true;
        context.read<GroupFeedBloc>().add(
          LoadNewerGroupMessagesEvent(widget.groupId, isRefresh: true),
        );
      }
      _lastUnread = n;
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _unreadSub?.cancel();
    _unread.close();
    super.dispose();
  }

  /// Drives bidirectional pagination: nearing the top loads older read
  /// messages, nearing the bottom loads newer unread messages and — once those
  /// are exhausted — marks the group fully read.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final bloc = context.read<GroupFeedBloc>();
    final state = bloc.state;

    if (pos.pixels <= pos.minScrollExtent + _loadTrigger) {
      if (state.hasMoreOlder && !state.isLoadingOlder) {
        bloc.add(LoadOlderGroupMessagesEvent(widget.groupId));
      }
    }

    if (pos.pixels >= pos.maxScrollExtent - _loadTrigger) {
      if (state.hasMoreUnread && !state.isLoadingUnread) {
        bloc.add(LoadNewerGroupMessagesEvent(widget.groupId));
      }
    }
    onReadScroll();

    final showJump =
        pos.maxScrollExtent - pos.pixels > kJumpToBottomTolerance;
    if (showJump != _showJumpButton) {
      setState(() => _showJumpButton = showJump);
    }
  }

  /// Pulls in anything newer, then jumps to the newest message. Reading is
  /// marked by [BottomReadMixin] once the bottom is reached with nothing left
  /// to load, so notes that were never shown are not marked read.
  void _jumpToLatest() {
    context.read<GroupFeedBloc>().add(
      LoadNewerGroupMessagesEvent(widget.groupId, isRefresh: true),
    );
    _scrollToBottom();
  }

  /// Over-pulling past the bottom edge re-checks the relay-synced store for
  /// unread messages that arrived after the feed opened.
  bool _onScrollNotification(ScrollNotification n) {
    if (n is OverscrollNotification && n.overscroll > 0) {
      final bloc = context.read<GroupFeedBloc>();
      if (!bloc.state.isLoadingUnread) {
        bloc.add(
          LoadNewerGroupMessagesEvent(widget.groupId, isRefresh: true),
        );
      }
    }
    return false;
  }

  /// Marks a message seen once it has been majority-visible.
  void _onMessageVisibility(String eventId, VisibilityInfo info) =>
      markIfOnScreen(
        eventId,
        info.visibleFraction,
        (id) => context.read<GroupFeedBloc>().add(MarkGroupMessageSeenEvent(id)),
      );

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _openThread(BuildContext ctx, NoteEntity msg, String groupName) {
    final bloc = ctx.read<GroupFeedBloc>();
    ctx.pushNamed(AppRoutes.thread, pathParameters: {'noteId': msg.id}).then((_) {
      // Pull any replies posted in the thread back in as newer messages,
      // without resetting the boundary anchor or scroll position.
      if (mounted) {
        bloc.add(
          LoadNewerGroupMessagesEvent(widget.groupId, isRefresh: true),
        );
        scheduleBottomCheck();
      }
    });
  }

  void _showGroupQrSheet(BuildContext context, GroupFeedState state) {
    final group = state.group;
    if (group == null) return;
    UniunQrCard.show(
      context,
      card: UniunQrCard.publicGroup(
        name: group.name,
        groupId: group.groupId,
        relays: group.relays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<GroupFeedBloc, GroupFeedState>(
      // Scroll to the bottom only when the user's own sent message lands.
      listenWhen: (prev, curr) =>
          curr.messages.length > prev.messages.length &&
          ((prev.isSending && !curr.isSending) || _followNewest),
      listener: (context, state) {
        _followNewest = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      },
      builder: (context, state) {
        contentChanged(state.messages.length);
        final groupName = state.group?.name ?? '';

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: context.custom.glassFill,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 4,
            leading: UniunBackButton(
              onPressed: () => context.popOrHome(),
            ),
            // # glyph + name (no "#" prefix — the icon conveys it). About rides
            // below as a subtitle. No member count (DESIGN.md §3.5).
            title: Row(
              children: [
                Icon(
                  Icons.tag_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (state.group?.about.isNotEmpty == true)
                        Text(
                          state.group!.about,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.custom.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (state.group != null) ...[
                IconButton(
                  onPressed: () => _showGroupQrSheet(context, state),
                  icon: Icon(
                    Icons.qr_code_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tooltip: l10n.groupShareQrTitle,
                ),
              ],
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: context.custom.borderSubtle),
            ),
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(context, state, groupName)),
              ComposerHost(
                hintText: l10n.groupMessageHint,
                isSending: state.isSending,
                entityContext: entityContextLines(state.messages),
                onSend: (text, refs, attachments) =>
                    context.read<GroupFeedBloc>().add(SendGroupMessageEvent(
                          groupId: widget.groupId,
                          content: text,
                          mentionRefs: refs,
                          attachments: attachments,
                        )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    GroupFeedState state,
    String groupName,
  ) {
    if (state.isLoading) {
      return Center(
        child: DropLoadingIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (state.status == GroupFeedStatus.error) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Something went wrong.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Be the first!',
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: BoundaryChatList<NoteEntity>(
            controller: _scrollController,
            notes: state.messages,
            boundaryIndex: state.boundaryIndex,
            openedAtBoundary: state.openedAtMiddle,
            unreadDivider: const NewNotesDivider(),
            bottomPadding: MediaQuery.of(context).padding.bottom + 8,
            itemBuilder: (ctx, msg) => _messageTile(ctx, msg, groupName),
          ),
        ),
        if (state.isLoadingOlder)
          const Positioned(top: 0, left: 0, right: 0, child: _EdgeSpinner()),
        if (state.isLoadingUnread)
          const Positioned(bottom: 0, left: 0, right: 0, child: _EdgeSpinner()),
        Positioned(
          right: 16,
          bottom: 12,
          child: BlocBuilder<UnreadCountCubit, int>(
            bloc: _unread,
            builder: (context, unread) => JumpToBottomButton(
              visible: _showJumpButton,
              unreadCount: unread,
              onPressed: _jumpToLatest,
              tooltip: AppLocalizations.of(context)!.jumpToLatest,
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageTile(BuildContext ctx, NoteEntity msg, String groupName) {
    return VisibilityDetector(
      key: ValueKey('chan-${msg.id}'),
      onVisibilityChanged: (info) => _onMessageVisibility(msg.id, info),
      child: NoteCard(
        key: ValueKey(msg.id),
        note: msg,
        onTap: () => _openThread(ctx, msg, groupName),
      ),
    );
  }
}

/// A small progress strip shown while an older/newer page is loading.
class _EdgeSpinner extends StatelessWidget {
  const _EdgeSpinner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: DropLoadingIndicator(
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
