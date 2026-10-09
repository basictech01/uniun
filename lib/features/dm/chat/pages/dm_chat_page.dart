import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_button.dart';
import 'package:uniun/common/qr/uniun_qr_card.dart';
import 'package:uniun/common/widgets/composer/composer_host.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/chat/boundary_chat_list.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/common/widgets/chat/bottom_read_mixin.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/common/widgets/jump_to_bottom_button.dart';
import 'package:uniun/common/widgets/chat/unread_count_cubit.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/domain/repositories/dm_conversation_repository.dart';
import 'package:uniun/features/dm/chat/bloc/dm_chat_bloc.dart';
import 'package:uniun/features/shiv/generation/chat_helpers.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class DmChatPage extends StatelessWidget {
  const DmChatPage({super.key, required this.otherPubkey});

  /// Recipient's hex pubkey (already normalised by the chatDm route).
  final String otherPubkey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<DmChatBloc>()..add(DmChatLoadEvent(otherPubkey: otherPubkey)),
      child: _DmChatView(otherPubkey: otherPubkey),
    );
  }
}

class _DmChatView extends StatefulWidget {
  const _DmChatView({required this.otherPubkey});
  final String otherPubkey;

  @override
  State<_DmChatView> createState() => _DmChatViewState();
}

class _DmChatViewState extends State<_DmChatView> with BottomReadMixin {
  final _scrollController = ScrollController();

  late final UnreadCountCubit _unread;

  @override
  ScrollController get readScrollController => _scrollController;

  @override
  void markContainerRead() =>
      context.read<DmChatBloc>().add(DmChatMarkAllSeenEvent());

  // To identify if a message is ours.
  String? _myPubkeyHex;
  String? _myNpub;
  String? _myAvatarUrl;
  List<String> _conversationRelays = const [];

  /// Whether the jump-to-latest button is showing (set when scrolled above the
  /// bottom).
  bool _showJumpButton = false;

  /// `created` of the oldest note that was unread when the chat opened; null
  /// when everything was read. Fixed for the life of the page.
  DateTime? _boundary;
  bool _boundaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _unread = UnreadCountCubit(
      getIt<WatchDmUnreadCountUseCase>().call(widget.otherPubkey),
    );
    _resolveActiveUser();
    _scrollController.addListener(_onScroll);
    getIt<GetDmOldestUnreadTimeUseCase>().call(widget.otherPubkey).then((r) {
      if (!mounted) return;
      setState(() {
        _boundary = r.getOrElse(() => null);
        _boundaryLoaded = true;
      });
    });
  }

  /// Reaching the newest note marks the conversation read.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    onReadScroll();

    final showJump = pos.maxScrollExtent - pos.pixels > kJumpToBottomTolerance;
    if (showJump != _showJumpButton) {
      setState(() => _showJumpButton = showJump);
    }
  }

  /// Jumps to the newest message and marks the conversation read.
  void _jumpToLatest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    context.read<DmChatBloc>().add(DmChatMarkAllSeenEvent());
  }

  void _onMessageVisibility(String eventId, VisibilityInfo info) =>
      markIfOnScreen(
        eventId,
        info.visibleFraction,
        (id) => context.read<DmChatBloc>().add(DmChatMarkSeenEvent(id)),
      );

  /// The conversation, oldest first, opened at the first note that was unread
  /// when the page opened.
  Widget _messageList(DmChatState state) {
    final oldestFirst = state.messages.reversed.toList(growable: false);
    final boundary = _boundary;
    final index = boundary == null
        ? oldestFirst.length
        : oldestFirst.indexWhere((m) => !m.created.isBefore(boundary));
    return BoundaryChatList<NoteEntity>(
      controller: _scrollController,
      notes: oldestFirst,
      boundaryIndex: index < 0 ? oldestFirst.length : index,
      openedAtBoundary: boundary != null,
      unreadDivider: const NewNotesDivider(),
      header: const _EncryptedNoticePill(),
      topPadding: 16,
      bottomPadding: 16,
      itemBuilder: (context, msg) => VisibilityDetector(
        key: ValueKey('dm-${msg.id}'),
        onVisibilityChanged: (info) => _onMessageVisibility(msg.id, info),
        // Same redesigned NoteCard as the feed/groups — it self-loads its
        // profile and resolves own-vs-other internally via NoteCardCubit.
        child: NoteCard(
          key: ValueKey(msg.id),
          note: msg,
          onTap: () => _openThread(context, msg.id),
        ),
      ),
    );
  }

  Future<void> _resolveActiveUser() async {
    final res = await getIt<GetActiveUserProfileUseCase>().call();
    if (mounted) {
      res.fold((_) {}, (profile) {
        setState(() {
          _myPubkeyHex = profile.pubkeyHex;
          _myNpub = Nip19.encodePubkey(profile.pubkeyHex);
          _myAvatarUrl = profile.avatarUrl;
        });
      });
    }
  }

  Future<void> _loadConversationRelays(String otherPubkeyHex) async {
    final result = await getIt<DmConversationRepository>()
        .getConversationByOtherPubkey(otherPubkeyHex);
    if (!mounted) return;
    setState(() {
      _conversationRelays = result.fold((_) => const [], (c) => c.relays);
    });
  }

  void _showQr(DmChatState state) {
    final otherPubkeyHex = state.otherPubkey;
    if (otherPubkeyHex == null || _myNpub == null) return;
    final partnerNpub = Nip19.encodePubkey(otherPubkeyHex);
    final partner = state.profiles[otherPubkeyHex];
    final me = _myPubkeyHex != null ? state.profiles[_myPubkeyHex!] : null;
    UniunQrCard.show(
      context,
      card: UniunQrCard.dmConversation(
        partnerNpub: partnerNpub,
        partnerName: partner?.name,
        partnerSeed: otherPubkeyHex,
        partnerAvatarUrl: partner?.avatarUrl,
        myNpub: _myNpub!,
        myName: me?.name,
        mySeed: _myPubkeyHex,
        myAvatarUrl: _myAvatarUrl,
        conversationRelays: _conversationRelays,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _unread.close();
    super.dispose();
  }

  void _openThread(BuildContext context, String messageId) {
    context
        .pushNamed(AppRoutes.thread, pathParameters: {'noteId': messageId})
        .then((_) {
          // Notes that arrived while the thread covered the chat.
          if (mounted) scheduleBottomCheck();
        });
  }

  /// Truncates a full npub to the `npub1q9x…k4ze` form shown under the name.
  String _shortNpub(String npub) => npub.length > 14
      ? '${npub.substring(0, 8)}…${npub.substring(npub.length - 4)}'
      : npub;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DmChatBloc, DmChatState>(
      listenWhen: (prev, curr) =>
          prev.otherPubkey != curr.otherPubkey ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        if (state.otherPubkey != null && _conversationRelays.isEmpty) {
          _loadConversationRelays(state.otherPubkey!);
        }
      },
      builder: (context, state) {
        // Nothing is on screen until the unread boundary is known.
        contentChanged(_boundaryLoaded ? state.messages.length : 0);
        final shortKey =
            state.otherPubkey != null && state.otherPubkey!.length > 12
            ? '${state.otherPubkey!.substring(0, 12)}...'
            : state.otherPubkey ?? 'Chat';

        final l10n = AppLocalizations.of(context)!;

        final otherPubkey = state.otherPubkey;
        final otherProfile = otherPubkey == null
            ? null
            : state.profiles[otherPubkey];
        final displayName = otherProfile?.name?.trim().isNotEmpty == true
            ? otherProfile!.name!.trim()
            : shortKey;
        final otherNpub = otherPubkey == null
            ? null
            : _shortNpub(Nip19.encodePubkey(otherPubkey));

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: context.custom.glassFill,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: UniunBackButton(onPressed: () => Navigator.pop(context)),
            titleSpacing: 0,
            title: Row(
              children: [
                UserAvatar(
                  seed: otherPubkey ?? 'dm',
                  photoUrl: otherProfile?.avatarUrl,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (otherNpub != null)
                        Text(
                          otherNpub,
                          style: TextStyle(
                            fontFamily: 'monospace',
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
              if (state.otherPubkey != null && _myNpub != null)
                UniunQrButton(
                  onTap: () => _showQr(state),
                  tooltip: l10n.dmShareKeysTooltip,
                ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.custom.borderSubtle,
              ),
            ),
          ),
          body: Column(
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
                          tooltip: AppLocalizations.of(context)!.jumpToLatest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ComposerHost(
                hintText: l10n.chatMessageHint,
                isSending: state.isSending,
                entityContext: entityContextLines(state.messages),
                onSend: (text, refs, attachments) =>
                    context.read<DmChatBloc>().add(
                      DmChatSendEvent(
                        content: text,
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

/// The end-to-end-encryption reassurance pill shown at the top of a DM
/// conversation (NIP-17). Mirrors the `DmChat.jsx` design-system mockup.
class _EncryptedNoticePill extends StatelessWidget {
  const _EncryptedNoticePill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.custom.surfaceLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 14, color: context.custom.success),
            const SizedBox(width: 6),
            Text(
              l10n.dmEncryptedNotice,
              style: TextStyle(fontSize: 12, color: context.custom.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
