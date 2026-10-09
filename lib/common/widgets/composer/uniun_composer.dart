import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:uniun/common/widgets/composer/markdown_formatting_toolbar.dart';
import 'package:uniun/common/widgets/composer/media_pick_helper.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Whether a [ComposerReference] points at a published note (id = Nostr event
/// id, hex) or at another draft (id = draft UUID). Drafts behave differently
/// at publish time — see `BrahmaCreateBloc._onPublishDraft`.
enum ComposerReferenceKind { note, draft }

/// A lightweight reference shown as a chip above the composer text.
/// [id] is the referenced event id (when [kind] is note) or draft UUID (when
/// draft); [label] is a human preview of it.
///
/// [authorPubkey] and [created] are optional metadata used by the reference
/// picker to render thread-style rows (avatar + name·time). They are ignored by
/// the composer chip, which only renders [label] (plus a "Draft" badge when
/// [kind] is draft).
class ComposerReference {
  const ComposerReference({
    required this.id,
    required this.label,
    this.kind = ComposerReferenceKind.note,
    this.authorPubkey,
    this.created,
  });

  final String id;
  final String label;
  final ComposerReferenceKind kind;
  final String? authorPubkey;
  final DateTime? created;
}

/// Shared chat-style composer used across the app (thread replies, group
/// thread replies, Brahma note creation).
///
/// Layout, top to bottom inside a single rounded card:
///   • optional "replying to" pill
///   • optional row of reference chips (shown like an attachment preview)
///   • the text field
///   • a control row: [avatar] [add-reference] … [draft] [send]
///
/// The avatar slot doubles as the future "switch to Shiv mode" button — pass
/// [onAvatarTap] to make it interactive.
class UniunComposer extends StatefulWidget {
  const UniunComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.avatarSeed,
    this.onSend,
    this.canSend = true,
    required this.hintText,
    this.avatarUrl,
    this.onAvatarTap,
    this.avatarOverride,
    this.onPickModel,
    this.chatPanel,
    this.references = const [],
    this.onRemoveReference,
    this.onAddReference,
    this.replyingToName,
    this.replyingToPreview,
    this.onClearReply,
    this.onDraft,
    this.draftLabel,
    this.draftIsPrimary = false,
    this.onTextChanged,
    this.isSending = false,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 6,
    this.applyBottomInset = true,
    this.markdownEnabled = false,
    this.onAttachMedia,
    this.attachments = const [],
    this.onRemoveAttachment,
    this.isAttachingMedia = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String avatarSeed;
  final String? avatarUrl;

  /// Tap on the send button. When null, the send button is hidden — used by
  /// surfaces (e.g. the share sheet) where sending is triggered elsewhere.
  final VoidCallback? onSend;
  final bool canSend;
  final String hintText;

  /// Tap on the avatar — opens the Manas-chat picker (WS4).
  final VoidCallback? onAvatarTap;

  /// Replaces the user avatar while in chat mode — shows the picked Manas /
  /// All-notes icon instead of the user's photo.
  final Widget? avatarOverride;

  /// When non-null (chat mode), shows a button that opens the AI model picker.
  final VoidCallback? onPickModel;

  /// When non-null, the composer is in chat mode: this panel (the Q&A + the
  /// streamed answer) renders inside the card, above the text field.
  final Widget? chatPanel;

  /// References currently attached, rendered as chips above the text.
  final List<ComposerReference> references;
  final void Function(String id)? onRemoveReference;

  /// Opens the reference picker. When null, the add-reference button is hidden.
  final VoidCallback? onAddReference;

  /// Reply-target context pill (group/thread replies).
  final String? replyingToName;

  /// Optional one-line snippet of the message being replied to, shown beneath
  /// the "Replying to …" header. When null the strip shows only the header.
  final String? replyingToPreview;
  final VoidCallback? onClearReply;

  /// Optional draft action (Brahma). When null, the draft button is hidden.
  final VoidCallback? onDraft;
  final String? draftLabel;

  /// Swaps the visual weight of the two actions: Draft becomes the filled
  /// primary and send drops to a muted circle. Brahma only — every chat
  /// surface keeps send as the primary action.
  final bool draftIsPrimary;

  final void Function(String)? onTextChanged;
  final bool isSending;
  final bool autofocus;

  /// Text-field height bounds. Larger [minLines] makes a taller input box.
  final int minLines;
  final int? maxLines;

  /// When docked at the bottom of a screen, pad for the keyboard / home
  /// indicator. Set false when the composer is anchored at the top.
  final bool applyBottomInset;

  /// Enables markdown editing: a toggle button in the control row (right of the
  /// add-reference button) that expands a collapsible formatting toolbar
  /// (B/I/code/list/quote/link) carrying a close button. Off by default to keep
  /// tight chat replies compact; turn on for chat composers and Brahma.
  final bool markdownEnabled;

  /// Opens a Photo / Video / File picker. When null, the attach button is
  /// hidden. Caller owns the picker → upload pipeline; this widget only
  /// renders the button and the resulting thumbnail row.
  final VoidCallback? onAttachMedia;

  /// Pending media the user has attached to this draft — held locally and
  /// uploaded to Blossom only on Send. Rendered as a thumbnail strip above the
  /// text field (preview straight from the in-memory bytes) with a × on each.
  final List<PickedMedia> attachments;
  final void Function(String sha256)? onRemoveAttachment;

  /// True while a freshly-picked file is being prepared (blurhash + dimensions
  /// computed off-thread). Renders a spinner placeholder in the attachment
  /// strip and disables the attach button so double-picks don't race.
  final bool isAttachingMedia;

  @override
  State<UniunComposer> createState() => _UniunComposerState();
}

class _UniunComposerState extends State<UniunComposer> {
  /// Whether the collapsible markdown formatting toolbar is expanded.
  bool _markdownExpanded = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Keyboard height when open, otherwise the bottom safe-area inset (home
    // indicator) so the composer never sits under the rounded screen corner.
    final bottom = !widget.applyBottomInset
        ? 0.0
        : media.viewInsets.bottom > 0
        ? media.viewInsets.bottom
        : media.viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 10, 10 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyingToName != null) ...[
            _ReplyBanner(
              name: widget.replyingToName!,
              preview: widget.replyingToPreview,
              onClear: widget.onClearReply,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.references.isNotEmpty) ...[
            _ReferenceRow(
              references: widget.references,
              onRemove: widget.onRemoveReference,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.attachments.isNotEmpty || widget.isAttachingMedia) ...[
            _AttachmentRow(
              attachments: widget.attachments,
              onRemove: widget.onRemoveAttachment,
              isAttaching: widget.isAttachingMedia,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.chatPanel != null) widget.chatPanel!,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onTextChanged,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // When the markdown toolbar is expanded it takes the place of the
          // control row, and the close button sits where the send button was.
          if (widget.markdownEnabled && _markdownExpanded)
            Row(
              children: [
                Expanded(
                  child: MarkdownFormattingToolbar(
                    controller: widget.controller,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _markdownExpanded = false),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onAvatarTap,
                  child:
                      widget.avatarOverride ??
                      UserAvatar(
                        seed: widget.avatarSeed,
                        photoUrl: widget.avatarUrl,
                        size: 34,
                        borderRadius: 17,
                      ),
                ),
                if (widget.onPickModel != null) ...[
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.smart_toy_rounded,
                    onTap: widget.onPickModel!,
                  ),
                ],
                if (widget.onAddReference != null) ...[
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.add_link_rounded,
                    onTap: widget.onAddReference!,
                    active: widget.references.isNotEmpty,
                  ),
                ],
                if (widget.onAttachMedia != null) ...[
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.add_photo_alternate_rounded,
                    onTap: widget.isAttachingMedia
                        ? () {}
                        : widget.onAttachMedia!,
                    active: widget.attachments.isNotEmpty,
                    busy: widget.isAttachingMedia,
                  ),
                ],
                if (widget.markdownEnabled) ...[
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.text_format_rounded,
                    onTap: () => setState(() => _markdownExpanded = true),
                  ),
                ],
                const Spacer(),
                // Order follows emphasis: the primary action takes the
                // rightmost slot. Colours alone would leave send sitting in
                // the primary position while Draft carried the accent.
                ...(widget.draftIsPrimary
                    ? [_sendButton(context), _draftButton(context)]
                    : [_draftButton(context), _sendButton(context)]),
              ],
            ),
        ],
      ),
    );
  }

  /// Null-safe so the row can order the two actions without repeating the
  /// `onDraft`/`onSend` presence checks at every position.
  Widget _draftButton(BuildContext context) {
    if (widget.onDraft == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        left: widget.draftIsPrimary ? 8 : 0,
        right: widget.draftIsPrimary ? 0 : 8,
      ),
      child: GestureDetector(
        onTap: widget.isSending ? null : widget.onDraft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: widget.draftIsPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.draftLabel ?? 'Draft',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.draftIsPrimary
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sendButton(BuildContext context) {
    if (widget.onSend == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: widget.canSend && !widget.isSending ? widget.onSend : null,
      child: AnimatedOpacity(
        opacity: widget.canSend ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.draftIsPrimary
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: widget.isSending
              ? Padding(
                  padding: const EdgeInsets.all(11),
                  child: DropLoadingIndicator(
                    color: widget.draftIsPrimary
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: widget.draftIsPrimary
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Colors.white,
                ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: busy
            ? Padding(
                padding: EdgeInsets.all(9),
                child: DropLoadingIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

/// Compact reply-context strip shown above the input: an accent bar, a
/// "Replying to @name" header, an optional one-line content [preview], and a ✕
/// to dismiss. The preview row is omitted when no snippet is supplied.
class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.name, this.preview, this.onClear});

  final String name;
  final String? preview;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snippet = preview?.trim() ?? '';
    final hasPreview = snippet.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: hasPreview ? 30 : 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.threadReplyingTo(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasPreview) ...[
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal thumbnail strip showing media the user has attached to the
/// current draft. Each tile shows the local image (if cached) or a mime icon
/// with a × overlay to remove.
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachments,
    this.onRemove,
    this.isAttaching = false,
  });

  final List<PickedMedia> attachments;
  final void Function(String sha256)? onRemove;
  final bool isAttaching;

  @override
  Widget build(BuildContext context) {
    final totalCount = attachments.length + (isAttaching ? 1 : 0);
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i < attachments.length) {
            return _AttachmentTile(media: attachments[i], onRemove: onRemove);
          }
          return const _UploadingTile();
        },
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 72,
        height: 72,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: SizedBox(
          width: 22,
          height: 22,
          child: DropLoadingIndicator(
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.media, this.onRemove});

  final PickedMedia media;
  final void Function(String sha256)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 72, height: 72, child: _preview(context)),
        ),
        if (media.isVideo)
          const Positioned.fill(
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => onRemove!(media.sha256),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Preview straight from the in-memory bytes — images render directly;
  /// videos show their first-frame blurhash (decoding a frame inline would be
  /// heavy); everything else falls back to a type icon.
  Widget _preview(BuildContext context) {
    if (media.isImage) {
      return Image.memory(
        media.bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _icon(context),
      );
    }
    if (media.isVideo && media.blurhash != null) {
      return BlurHash(hash: media.blurhash!);
    }
    return _icon(context);
  }

  Widget _icon(BuildContext context) {
    final IconData icon = media.isVideo
        ? Icons.movie_outlined
        : media.mime.startsWith('audio/')
        ? Icons.audiotrack_outlined
        : media.isImage
        ? Icons.image_outlined
        : Icons.insert_drive_file_outlined;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 28),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.references, this.onRemove});

  final List<ComposerReference> references;
  final void Function(String id)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: references.map((r) {
        final preview = r.label.trim();
        final label = preview.length > 30
            ? '${preview.substring(0, 30)}…'
            : preview.isEmpty
            ? r.id.substring(0, r.id.length < 8 ? r.id.length : 8)
            : preview;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                r.kind == ComposerReferenceKind.draft
                    ? Icons.edit_note_rounded
                    : Icons.link_rounded,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (r.kind == ComposerReferenceKind.draft) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.brahmaDraft.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
              if (onRemove != null) ...[
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () => onRemove!(r.id),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
