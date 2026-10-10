import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/common/widgets/note_card/embedded_note_card.dart';
import 'package:uniun/common/widgets/note_card/media_attachment_view.dart';
import 'package:uniun/common/widgets/note_card/translation_footer.dart';
import 'package:uniun/common/widgets/note_card/expandable_note_text.dart';
import 'package:uniun/common/widgets/open_user_profile.dart';
import 'package:uniun/common/widgets/note_card/note_card_menu.dart';
import 'package:uniun/common/widgets/note_card/save_toggle.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/core/utils/formatters.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/features/share/pages/share_sheet_page.dart';

/// Self-contained note card. Owns its author profile, saved flag, and follow
/// flag via an internal [NoteCardCubit] (follow state is watched reactively
/// from Isar). Callers only pass the note and a tap handler.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onDelete,
  });

  final NoteEntity note;
  final VoidCallback onTap;

  /// Overrides the overflow menu's "Delete note" action. Null = default
  /// (suppress in the unified `Note` store). The Surrounding feed passes a
  /// deleter that removes the note from its own ephemeral store instead.
  final Future<Either<Failure, Unit>> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // A reused card must not keep a cubit bound to the previous note.
      key: ValueKey(note.id),
      create: (_) => getIt<NoteCardCubit>(param1: note),
      child: _NoteCardView(note: note, onTap: onTap, onDelete: onDelete),
    );
  }
}

class _NoteCardView extends StatelessWidget {
  const _NoteCardView({
    required this.note,
    required this.onTap,
    this.onDelete,
  });

  final NoteEntity note;
  final VoidCallback onTap;
  final Future<Either<Failure, Unit>> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NoteCardCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final custom = context.custom;
    // Only collapse-on-delete needs the whole card to rebuild. Everything else
    // is scoped to the dynamic leaves below (avatar / name / menu / action row)
    // via BlocSelector, so the markdown body, media and embed — all derived
    // purely from the immutable note — build once per item instead of on every
    // profile/saved/follow/own emit.
    return BlocSelector<NoteCardCubit, NoteCardState, bool>(
      selector: (s) => s.isRemoved,
      builder: (context, isRemoved) {
        if (isRemoved) return const SizedBox.shrink();
        return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: custom.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──────────────────────────────────────────────────
                BlocSelector<
                  NoteCardCubit,
                  NoteCardState,
                  ({String? photo, String name})
                >(
                  selector: (s) => (
                    photo: s.profile?.avatarUrl,
                    name: _displayName(
                      s.profile?.name,
                      s.profile?.username,
                      note.authorPubkey,
                    ),
                  ),
                  builder: (context, a) => UserAvatar(
                    seed: note.authorPubkey,
                    photoUrl: a.photo,
                    size: 40,
                    borderRadius: 20,
                    onTap: () => openUserProfile(
                      context,
                      note.authorPubkey,
                      hintName: a.name,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                BlocSelector<
                                  NoteCardCubit,
                                  NoteCardState,
                                  String
                                >(
                                  selector: (s) => _displayName(
                                    s.profile?.name,
                                    s.profile?.username,
                                    note.authorPubkey,
                                  ),
                                  builder: (context, name) => Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatTimeAgo(note.created),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: custom.textMuted,
                                  ),
                                ),
                                if (note.sourceLabel != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    note.sourcePrivateGroupId != null
                                        ? Icons.lock_outline
                                        : Icons.tag_rounded,
                                    size: 13,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      note.sourceLabel!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // ── Overflow menu (Delete / Block) ──────────────────
                          BlocSelector<
                            NoteCardCubit,
                            NoteCardState,
                            ({bool isOwn, String name})
                          >(
                            selector: (s) => (
                              isOwn: s.isOwnNote,
                              name: _displayName(
                                s.profile?.name,
                                s.profile?.username,
                                note.authorPubkey,
                              ),
                            ),
                            builder: (context, m) => NoteCardMenu(
                              cubit: cubit,
                              isOwnNote: m.isOwn,
                              displayName: m.name,
                              onDelete: onDelete,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Body — swaps to the translation when one is showing.
                      // Scoped to its own selector so translating one card
                      // doesn't rebuild the rest of the note.
                      if (note.content.isNotEmpty)
                        BlocSelector<NoteCardCubit, NoteCardState,
                            (String, bool)>(
                          selector: (s) => (
                            s.showsTranslation ? s.translation! : note.content,
                            s.isTranslating,
                          ),
                          builder: (context, data) {
                            final (body, isTranslating) = data;
                            return Opacity(
                              // Dim while the model works — the original stays
                              // readable instead of collapsing to a spinner.
                              opacity: isTranslating ? 0.45 : 1,
                              child: ExpandableNoteText(
                                text: body,
                                // Body text is selectable (long-press), but a simple tap
                                // is forwarded to the card's onTap so it still opens the
                                // thread — SelectableText would otherwise swallow it.
                                onTap: onTap,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: custom.textBody,
                                  height: 1.55,
                                ),
                              ),
                            );
                          },
                        ),
                      const TranslationFooter(),
                      if (note.quotedNote != null) ...[
                        if (note.content.isNotEmpty) const SizedBox(height: 8),
                        EmbeddedNoteCard(note: note.quotedNote),
                      ],

                      // ── Media attachments (NIP-92 imeta) ────────────────────
                      if (note.hasMedia) MediaAttachmentView(note: note),

                      // Hashtag chips
                      if (note.tTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: note.tTags
                              .take(3)
                              .map(
                                (t) => Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // ── Action row ────────────────────────────────────────
                      // Scoped to save / follow / own so toggling those updates the
                      // row without rebuilding the body above.
                      BlocSelector<
                        NoteCardCubit,
                        NoteCardState,
                        ({bool isOwn, bool saved, bool followed})
                      >(
                        selector: (s) => (
                          isOwn: s.isOwnNote,
                          saved: s.isSaved,
                          followed: s.isFollowed,
                        ),
                        builder: (context, a) => Row(
                          children: [
                            // Reply count
                            _ActionChip(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: '${note.cachedReplyCount}',
                              color: colorScheme.onSurfaceVariant,
                              onTap: onTap,
                            ),
                            const SizedBox(width: 28),

                            // Reference count — outgoing refs from the edge table.
                            // Reads as active (primary) when the note has any.
                            _ActionChip(
                              icon: Icons.link_rounded,
                              label: '${note.referenceCount}',
                              color: note.referenceCount > 0
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              onTap: onTap,
                            ),

                            // Save toggle — hidden on own notes (kept forever
                            // already; saving is for others').
                            if (!a.isOwn) ...[
                              const SizedBox(width: 28),
                              _ActionChip(
                                icon: a.saved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: a.saved
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                onTap: () => handleSaveToggle(context, cubit),
                              ),
                            ],
                            const SizedBox(width: 28),

                            // Watch / Watching — owned by the cubit
                            _ActionChip(
                              icon: a.followed
                                  ? Icons.visibility
                                  : Icons.visibility_outlined,
                              color: a.followed
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              onTap: () => cubit.toggleFollow(),
                            ),
                            const Spacer(),
                            _ActionChip(
                              icon: Icons.ios_share_rounded,
                              color: colorScheme.onSurfaceVariant,
                              onTap: () => ShareSheetPage.show(context, note),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Author display name from the (reactive) profile, falling back to a short
/// form of the pubkey. Top-level so the per-leaf [BlocSelector]s can call it.
String _displayName(String? name, String? username, String pubkey) =>
    name ?? username ?? _shortName(pubkey);

String _shortName(String pubkey) {
  if (pubkey.length <= 16) return pubkey;
  return '${pubkey.substring(0, 8)}...${pubkey.substring(pubkey.length - 4)}';
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          if (label != null) ...[
            const SizedBox(width: 5),
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
