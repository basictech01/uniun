import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/features/shiv/chat/cubit/chat_image_support_cubit.dart';
import 'package:uniun/common/widgets/drop_icon.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/features/shiv/chat/tree/pages/shiv_branch_tree_page.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_history_drawer.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_input_composer.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_message_bubble.dart';

/// The active conversation chat screen.
/// Header: SHIV title + thread title + history icon + tree icon.
/// No branch/continue buttons in bubbles — that's handled via the tree view.
class ShivChatPage extends StatefulWidget {
  const ShivChatPage({super.key, required this.onDrawerChanged});
  final ValueChanged<bool> onDrawerChanged;

  @override
  State<ShivChatPage> createState() => _ShivChatPageState();
}

class _ShivChatPageState extends State<ShivChatPage> {
  final _scrollController = ScrollController();

  /// Whether the active model can read images (shows the attach button).
  late final ChatImageSupportCubit _imageSupport =
      getIt<ChatImageSupportCubit>()..refresh();

  @override
  void dispose() {
    _imageSupport.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ShivAIBloc, ShivAIState>(
      listenWhen: (prev, curr) => curr.messages.length != prev.messages.length,
      listener: (context, state) => _scrollToBottom(),
      // Per-token `streamingContent` changes must NOT rebuild this whole tree
      // (header + ListView + input composer). The live bubble subscribes to
      // streamingContent on its own via [_StreamingBubble]; everything else
      // only needs to rebuild on these structural changes.
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.messages != c.messages ||
          p.activeConversation != c.activeConversation ||
          p.lastTurnSourceNoteIds != c.lastTurnSourceNoteIds ||
          p.lastTurnSourceChunkIds != c.lastTurnSourceChunkIds,
      builder: (context, state) {
        final isStreaming = state.status == ShivChatStatus.streaming;
        final conv = state.activeConversation;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            resizeToAvoidBottomInset: false,
            drawer: const ShivHistoryDrawer(),
            onDrawerChanged: widget.onDrawerChanged,
            // Builder gives a context descended from this Scaffold so
            // Scaffold.of(ctx).openDrawer() targets the correct drawer.
            body: Builder(
              builder: (ctx) => Column(
                children: [
                  _ShivChatHeader(
                    threadTitle:
                        conv?.title ?? l10n.shivDefaultConversationTitle,
                    onBack: () => context.read<ShivAIBloc>().add(
                      const ShivAIEvent.closeConversation(),
                    ),
                    onHistoryTap: () => Scaffold.of(ctx).openDrawer(),
                    onTreeTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ShivAIBloc>(),
                            child: const ShivBranchTreePage(),
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: state.messages.isEmpty && !isStreaming
                        ? const _EmptyChat()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            itemCount: state.messages.length,
                            itemBuilder: (context, i) {
                              final msg = state.messages[i];
                              final isLast = i == state.messages.length - 1;
                              final isAssistant =
                                  msg.role == MessageRole.assistant;
                              final isLastAssistant = isLast && isAssistant;
                              // The live-streaming bubble subscribes to
                              // streamingContent itself so only it rebuilds per
                              // token — the rest of this list stays put.
                              if (isStreaming && isLastAssistant) {
                                return _StreamingBubble(
                                  key: ValueKey(msg.messageId),
                                  message: msg,
                                  sourceNoteIds: state.lastTurnSourceNoteIds,
                                  sourceChunkIds: state.lastTurnSourceChunkIds,
                                );
                              }
                              return ShivMessageBubble(
                                key: ValueKey(msg.messageId),
                                message: msg,
                                isLastAssistant: isLastAssistant,
                                sourceNoteIds: isLastAssistant
                                    ? state.lastTurnSourceNoteIds
                                    : const [],
                                sourceChunkIds: isLastAssistant
                                    ? state.lastTurnSourceChunkIds
                                    : const [],
                              );
                            },
                          ),
                  ),
                  BlocBuilder<ChatImageSupportCubit, bool>(
                    bloc: _imageSupport,
                    builder: (context, supportsImages) => ShivInputComposer(
                      isStreaming: isStreaming,
                      supportsImages: supportsImages,
                      onModelSheetClosed: () => _imageSupport.refresh(),
                      onSend: (text, manasIds, images) =>
                          context.read<ShivAIBloc>().add(
                            ShivAIEvent.sendMessage(
                              text,
                              manasIds: manasIds,
                              images: images,
                            ),
                          ),
                      onStop: () => context.read<ShivAIBloc>().add(
                        const ShivAIEvent.stopStreaming(),
                      ),
                    ),
                  ),
                ],
              ), // close Builder
            ),
          ),
        );
      },
    );
  }
}

// ── Streaming bubble ─────────────────────────────────────────────────────────

/// Wraps the live assistant bubble in a [BlocSelector] on `streamingContent`,
/// so token updates rebuild ONLY this bubble — not the page's header, list, or
/// input composer (which are gated out by the page's `buildWhen`).
class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({
    super.key,
    required this.message,
    required this.sourceNoteIds,
    required this.sourceChunkIds,
  });

  final ShivMessageEntity message;
  final List<String> sourceNoteIds;
  final List<String> sourceChunkIds;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ShivAIBloc, ShivAIState, String?>(
      selector: (s) => s.streamingContent,
      builder: (context, streaming) => ShivMessageBubble(
        message: message,
        streamingContent: streaming ?? '',
        isLastAssistant: true,
        sourceNoteIds: sourceNoteIds,
        sourceChunkIds: sourceChunkIds,
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ShivChatHeader extends StatelessWidget {
  const _ShivChatHeader({
    required this.threadTitle,
    required this.onBack,
    required this.onHistoryTap,
    required this.onTreeTap,
  });

  final String threadTitle;
  final VoidCallback onBack;
  final VoidCallback onHistoryTap;
  final VoidCallback onTreeTap;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(left: 8, right: 8, top: top + 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back — return to the Shiv home (closes the active conversation).
          _HeaderIcon(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            tooltip: l10n.actionBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              threadTitle,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Conversation history — opens the history drawer sheet.
          _HeaderIcon(
            icon: Icons.history_rounded,
            onTap: onHistoryTap,
            tooltip: l10n.shivConversationsTooltip,
          ),
          // Tree — branch graph for this conversation
          _HeaderIcon(
            assetPath: 'assets/images/network_node.svg',
            onTap: onTreeTap,
            tooltip: l10n.shivBranchTreeTooltip,
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    this.icon,
    this.assetPath,
    this.child,
    required this.onTap,
    required this.tooltip,
  }) : assert(icon != null || assetPath != null || child != null);

  final IconData? icon;
  final String? assetPath;
  final Widget? child;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child:
              child ??
              (assetPath != null
                  ? SvgPicture.asset(
                      assetPath!,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: DropIcon(
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.shivEmptyTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.shivEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
