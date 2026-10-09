import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/widgets/chat/boundary_chat_list.dart';
import 'package:uniun/common/widgets/chat/bottom_read_mixin.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_button.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/qr/uniun_qr_card.dart';
import 'package:uniun/common/widgets/composer/composer_host.dart';
import 'package:uniun/common/widgets/jump_to_bottom_button.dart';
import 'package:uniun/common/widgets/chat/unread_count_cubit.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/features/private_groups/detail/bloc/private_group_detail_bloc.dart';
import 'package:uniun/features/shiv/generation/chat_helpers.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/nav_extensions.dart';
import 'package:uniun/l10n/app_localizations.dart';

class PrivateGroupDetailPage extends StatelessWidget {
  final String groupId;
  const PrivateGroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<PrivateGroupDetailBloc>(param1: groupId),
        ),
      ],
      child: _PrivateGroupDetailView(groupId: groupId),
    );
  }
}

class _PrivateGroupDetailView extends StatefulWidget {
  const _PrivateGroupDetailView({required this.groupId});
  final String groupId;

  @override
  State<_PrivateGroupDetailView> createState() =>
      _PrivateGroupDetailViewState();
}

class _PrivateGroupDetailViewState extends State<_PrivateGroupDetailView>
    with BottomReadMixin {
  final _scrollController = ScrollController();

  late final UnreadCountCubit _unread;

  @override
  ScrollController get readScrollController => _scrollController;

  @override
  void markContainerRead() => context.read<PrivateGroupDetailBloc>().add(
    MarkAllPrivateGroupSeenEvent(),
  );

  /// Whether the jump-to-latest button is showing (set when scrolled above the
  /// bottom).
  bool _showJumpButton = false;

  /// `created` of the oldest note that was unread when the page opened; null
  /// when everything was read. Fixed for the life of the page.
  DateTime? _boundary;
  bool _boundaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _unread = UnreadCountCubit(
      getIt<WatchPrivateGroupUnreadCountUseCase>().call(widget.groupId),
    );
    _scrollController.addListener(_onScroll);
    getIt<GetPrivateGroupOldestUnreadTimeUseCase>().call(widget.groupId).then((
      r,
    ) {
      if (!mounted) return;
      setState(() {
        _boundary = r.getOrElse(() => null);
        _boundaryLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _unread.close();
    super.dispose();
  }

  /// Reaching the bottom (newest message) marks the whole group read.
  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    onReadScroll();

    final showJump = pos.maxScrollExtent - pos.pixels > kJumpToBottomTolerance;
    if (showJump != _showJumpButton) {
      setState(() => _showJumpButton = showJump);
    }
  }

  /// Jumps to the newest message and marks the whole group read.
  void _jumpToLatest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    context.read<PrivateGroupDetailBloc>().add(MarkAllPrivateGroupSeenEvent());
  }

  /// The group, oldest first, opened at the first note that was unread when the
  /// page opened.
  Widget _messageList(PrivateGroupDetailState state) {
    final boundary = _boundary;
    final index = boundary == null
        ? state.messages.length
        : state.messages.indexWhere((m) => !m.created.isBefore(boundary));
    return BoundaryChatList<NoteEntity>(
      controller: _scrollController,
      notes: state.messages,
      boundaryIndex: index < 0 ? state.messages.length : index,
      openedAtBoundary: boundary != null,
      unreadDivider: const NewNotesDivider(),
      topPadding: 16,
      bottomPadding: 16,
      itemBuilder: (context, msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // NoteCard self-loads its author profile.
        child: VisibilityDetector(
          key: ValueKey('pc-${msg.id}'),
          onVisibilityChanged: (info) => _onMessageVisibility(msg.id, info),
          child: NoteCard(
            key: ValueKey(msg.id),
            note: msg,
            onTap: () => _openThread(context, msg.id),
          ),
        ),
      ),
    );
  }

  void _onMessageVisibility(String eventId, VisibilityInfo info) =>
      markIfOnScreen(
        eventId,
        info.visibleFraction,
        (id) => context.read<PrivateGroupDetailBloc>().add(
          MarkPrivateGroupMessageSeenEvent(id),
        ),
      );

  void _openThread(BuildContext context, String messageId) {
    context
        .pushNamed(AppRoutes.thread, pathParameters: {'noteId': messageId})
        .then((_) {
          // Notes that arrived while the thread covered the chat.
          if (mounted) scheduleBottomCheck();
        });
  }

  void _showJoinRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<PrivateGroupDetailBloc>(),
          child: BlocBuilder<PrivateGroupDetailBloc, PrivateGroupDetailState>(
            builder: (ctx, state) {
              return _JoinRequestsSheet(
                requests: state.joinRequests,
                profiles: state.profiles,
                isApproving: state.isApproving,
                onApprove: (keyPackage) {
                  ctx.read<PrivateGroupDetailBloc>().add(
                    ApproveJoinRequestEvent(keyPackage),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrivateGroupDetailBloc, PrivateGroupDetailState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        if (state.isLeft) {
          context.goNamed(AppRoutes.home);
        }
      },
      builder: (context, state) {
        // Nothing is on screen until the unread boundary is known.
        contentChanged(_boundaryLoaded ? state.messages.length : 0);
        final title = state.group?.name ?? "Private Group";
        final requestsCount = state.joinRequests.length;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: UniunBackButton(onPressed: () => context.popOrHome()),
            titleSpacing: 0,
            title: Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              if (state.isAdmin)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.group_add_rounded),
                      onPressed: () => _showJoinRequests(context),
                    ),
                    if (requestsCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$requestsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              if (state.group != null) ...[
                UniunQrButton(
                  onTap: () => UniunQrCard.show(
                    context,
                    card: UniunQrCard.privateGroup(
                      name: state.group!.name,
                      groupId: state.groupId,
                      relays: state.group!.relays,
                    ),
                  ),
                  tooltip: AppLocalizations.of(
                    context,
                  )!.privateGroupShareQrTooltip,
                ),
              ],
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'leave') {
                    context.read<PrivateGroupDetailBloc>().add(
                      LeavePrivateGroupEvent(),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'leave',
                    child: Text(
                      AppLocalizations.of(context)!.privateGroupLeaveAction,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: state.isPendingApproval
              ? const _PendingApprovalView()
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          state.isLoading && state.messages.isEmpty ||
                                  !_boundaryLoaded
                              ? const Center(child: DropLoadingIndicator())
                              : _messageList(state),
                          Positioned(
                            right: 16,
                            bottom: 12,
                            child: BlocBuilder<UnreadCountCubit, int>(
                              bloc: _unread,
                              builder: (context, unread) => JumpToBottomButton(
                                visible: _showJumpButton,
                                unreadCount: unread,
                                onPressed: _jumpToLatest,
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.jumpToLatest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ComposerHost(
                      hintText: AppLocalizations.of(context)!.chatMessageHint,
                      entityContext: entityContextLines(state.messages),
                      onSend: (text, refs, attachments) =>
                          context.read<PrivateGroupDetailBloc>().add(
                            SendPrivateGroupMessageEvent(
                              text,
                              mentionRefs: refs,
                              attachments: attachments,
                            ),
                          ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PendingApprovalView extends StatelessWidget {
  const _PendingApprovalView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.privateGroupPendingApprovalTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.privateGroupPendingApprovalBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinRequestsSheet extends StatelessWidget {
  const _JoinRequestsSheet({
    required this.requests,
    required this.profiles,
    required this.isApproving,
    required this.onApprove,
  });

  final List requests;
  final Map<String, ProfileEntity> profiles;
  final bool isApproving;
  final void Function(String keyPackageB64) onApprove;

  String _shortNpub(String pubkeyHex) {
    try {
      final npub = Nip19.encodePubkey(pubkeyHex);
      if (npub.length <= 18) return npub;
      return '${npub.substring(0, 10)}…${npub.substring(npub.length - 6)}';
    } catch (_) {
      return '${pubkeyHex.substring(0, 8)}…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.group_add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.pendingRequestsTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (requests.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pendingRequestsSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 36,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pendingRequestsEmpty,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final req = requests[i];
                    final pubkey = req.senderPubkey as String;
                    final profile = profiles[pubkey];
                    final name = (profile?.name?.trim().isNotEmpty == true)
                        ? profile!.name!
                        : l10n.pendingRequestsNewMember;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            seed: pubkey,
                            photoUrl: profile?.avatarUrl,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _shortNpub(pubkey),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isApproving
                                ? null
                                : () {
                                    onApprove(req.keyPackageB64 as String);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isApproving
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: DropLoadingIndicator(
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(
                                    l10n.pendingRequestsApprove,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
