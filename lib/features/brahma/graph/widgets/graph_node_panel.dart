import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_stepper.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/markdown/note_markdown_body.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/common/widgets/note_card/media_attachment_view.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/utils/formatters.dart';
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// Slides up from the bottom when a graph node is tapped.
class GraphNodePanel extends StatelessWidget {
  const GraphNodePanel({
    super.key,
    required this.node,
    required this.onClose,
    this.profile,
    this.onEditTap,
    this.onPublishTap,
  });

  final GraphNodeData node;
  final VoidCallback onClose;
  final ProfileEntity? profile;

  final void Function(String draftId)? onEditTap;
  final void Function(String draftId)? onPublishTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDraft = node.type == GraphNodeType.draft;
    // Drafts render through their own card (note look + draft actions); only
    // saved/own nodes feed a NoteCard.
    final noteEntity = (!isDraft && node.created != null)
        ? NoteEntity(
            id: node.eventId,
            sig: node.sig ?? '',
            authorPubkey: node.authorPubkey ?? '',
            content: node.content,
            type: NoteType.text,
            eTagRefs: node.eTagRefs,
            pTagRefs: node.pTagRefs,
            tTags: node.tTags,
            created: node.created!,
            // Carry the enriched edge-table counts so the card's reference/
            // comment chips show the real numbers, not zeros.
            referenceCount: node.referenceCount,
            cachedReplyCount: node.cachedReplyCount,
            attachments: node.attachments,
          )
        : null;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.52,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header: type badge + close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TypeBadge(type: node.type, l10n: l10n),
                  const Spacer(),
                  const _ConnectionStepper(),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(Icons.close_rounded,
                        size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Draft → note-look card + draft actions; saved/own → NoteCard.
            if (isDraft)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: _DraftPreview(
                    node: node,
                    profile: profile,
                    onClose: onClose,
                    onEditTap: onEditTap,
                    onPublishTap: onPublishTap,
                    l10n: l10n,
                  ),
                ),
              )
            else if (noteEntity != null)
              Flexible(
                child: SingleChildScrollView(
                  child: NoteCard(
                    note: noteEntity,
                    // Replying inside the thread creates a new own note and
                    // bumps this note's reply count — neither of which the
                    // graph watches for, so reload on return (same pattern as
                    // the draft edit path). The reload preserves selectedNodeId,
                    // so the open panel re-reads the refreshed node itself.
                    onTap: () async {
                      final bloc = context.read<GraphBloc>();
                      await context.pushNamed(
                        AppRoutes.thread,
                        pathParameters: {'noteId': node.eventId},
                      );
                      if (bloc.isClosed) return;
                      bloc.add(LoadGraphEvent(
                        manasId: bloc.state.scopedManasId,
                        manasName: bloc.state.scopedManasName,
                      ));
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Walks the connections of the anchored node — the no-search way to follow a
/// note's edges. Hidden when the node has none.
class _ConnectionStepper extends StatelessWidget {
  const _ConnectionStepper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<GraphBloc, GraphState>(
      buildWhen: (prev, curr) =>
          prev.connectionAnchorId != curr.connectionAnchorId ||
          prev.connectionIndex != curr.connectionIndex,
      builder: (context, state) {
        final total = state.connectionOrder.length;
        if (total == 0) return const SizedBox.shrink();
        return GraphStepper(
          icon: Icons.link_rounded,
          current: state.connectionIndex + 1,
          total: total,
          positionLabel:
              l10n.graphStepPosition(state.connectionIndex + 1, total),
          prevTooltip: l10n.graphPrevConnection,
          nextTooltip: l10n.graphNextConnection,
          onStep: (delta) =>
              context.read<GraphBloc>().add(StepConnectedNodeEvent(delta)),
        );
      },
    );
  }
}

// ── Type badge ─────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.l10n});
  final GraphNodeType type;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      GraphNodeType.saved => (l10n.graphLegendSaved, context.custom.graphSaved),
      GraphNodeType.own   => (l10n.graphLegendOwn,   context.custom.graphOwn),
      GraphNodeType.draft => (l10n.graphLegendDraft, context.custom.graphDraft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Draft preview — default note look (avatar/name/media) + draft actions ──
class _DraftPreview extends StatelessWidget {
  const _DraftPreview({
    required this.node,
    required this.profile,
    required this.onClose,
    required this.l10n,
    this.onEditTap,
    this.onPublishTap,
  });
  final GraphNodeData node;
  final ProfileEntity? profile;
  final VoidCallback onClose;
  final void Function(String)? onEditTap;
  final void Function(String)? onPublishTap;
  final AppLocalizations l10n;

  String _shortName(String pubkey) {
    if (pubkey.length <= 16) return pubkey;
    return '${pubkey.substring(0, 8)}...${pubkey.substring(pubkey.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final draftId = node.eventId;
    final content = node.content;
    final isEmpty = content.trim().isEmpty;
    final hasMedia = node.attachments.isNotEmpty;
    final displayName = profile?.name ??
        profile?.username ??
        _shortName(node.authorPubkey ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Author row — same shape as a NoteCard header ──────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              seed: node.authorPubkey ?? draftId,
              photoUrl: profile?.avatarUrl,
              size: 40,
              borderRadius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (node.created != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatTimeAgo(node.created!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _DraftChip(label: l10n.graphLegendDraft),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (isEmpty && !hasMedia)
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (!isEmpty)
                    NoteMarkdownBody(
                      content: content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                  // ── Media (NIP-92, staged locally on this device) ──────
                  if (hasMedia)
                    MediaAttachmentView.fromBlobs(
                      attachments: node.attachments,
                    ),

                  // Hashtag chips
                  if (node.tTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: node.tTags
                          .take(3)
                          .map(
                            (t) => Text(
                              '#$t',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Draft actions ─────────────────────────────────────────────────
        Row(
          children: [
            _ActionBtn(
              label: l10n.graphDraftEdit,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              bgColor: Theme.of(context).colorScheme.surfaceContainerLow,
              onTap: () {
                onClose();
                onEditTap?.call(draftId);
              },
            ),
            const SizedBox(width: 8),
            // Publish keeps the panel open and shows a spinner while the note
            // uploads + publishes; the graph reload on success closes it.
            Expanded(
              child: BlocBuilder<BrahmaCreateBloc, BrahmaCreateState>(
                builder: (context, brahmaState) => _ActionBtn(
                  label: l10n.brahmaPublish,
                  color: Theme.of(context).colorScheme.onPrimary,
                  bgColor: Theme.of(context).colorScheme.primary,
                  fullWidth: true,
                  busy: brahmaState.isSubmitting,
                  onTap: brahmaState.isSubmitting
                      ? null
                      : () => onPublishTap?.call(draftId),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              label: l10n.graphDraftDelete,
              color: Theme.of(context).colorScheme.error,
              bgColor: Theme.of(context).colorScheme.errorContainer,
              onTap: () {
                onClose();
                context.read<GraphBloc>().add(DeleteDraftNodeEvent(draftId));
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Small "Draft" pill shown beside the author name so the note-look card still
/// reads as a draft.
class _DraftChip extends StatelessWidget {
  const _DraftChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.custom.graphDraft.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.custom.graphDraft,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.fullWidth = false,
    this.busy = false,
  });
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final bool fullWidth;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: busy
            ? Center(
                heightFactor: 1,
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: DropLoadingIndicator(size: 16, color: color),
                ),
              )
            : Text(
                label,
                textAlign: fullWidth ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
      ),
    );
  }
}
