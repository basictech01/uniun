import 'package:flutter/material.dart';
import 'package:uniun/common/widgets/thread/unread_trail_mark.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/common/widgets/note_card/large_note_card.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/features/thread/widgets/thread_empty_states.dart';
import 'package:uniun/features/thread/widgets/thread_parent_context.dart';
import 'package:uniun/features/thread/widgets/thread_section_label.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// Shared thread layout used by the feed, group, private-group and DM
/// thread views. Pure UI: parent context → mentioned refs → root card →
/// replies list (each opening its own nested thread).
class ThreadConversationBody extends StatelessWidget {
  const ThreadConversationBody({
    super.key,
    required this.root,
    required this.profiles,
    required this.replies,
    required this.onOpenThread,
    this.parentNotes = const [],
    this.mentionedNotes = const [],
    this.replyCount,
    this.unreadMarkers = const {},
  });

  final NoteEntity root;
  final Map<String, ProfileEntity> profiles;
  final List<NoteEntity> parentNotes;
  final List<NoteEntity> mentionedNotes;
  final List<NoteEntity> replies;

  /// Reply count shown on the root card. Defaults to [replies] length.
  final int? replyCount;

  final void Function(String noteId) onOpenThread;

  /// Unread dots for notes inside a followed note's tree, by note id.
  final Map<String, ThreadUnreadMarker> unreadMarkers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Reference / parent context — a grey full-bleed band above the root
        // so the "context" zone reads distinctly from the white root + replies.
        // Content stays inset 16px to align with the root note's avatar below.
        if (parentNotes.isNotEmpty || mentionedNotes.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: context.custom.surfaceLow,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immediate NIP-10 parent (1 level only).
                  if (parentNotes.isNotEmpty)
                    ThreadParentContext(
                      notes: parentNotes,
                      profiles: profiles,
                      onNoteTap: onOpenThread,
                    ),
                  // Outgoing references — sibling group pointing at the root.
                  if (mentionedNotes.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                          top: parentNotes.isNotEmpty ? 14 : 0),
                      child: ThreadParentContext(
                        notes: mentionedNotes,
                        profiles: profiles,
                        isSiblingGroup: true,
                        onNoteTap: onOpenThread,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // ── Focused / root note ───────────────────────────────────────────────
        // Flat full-bleed (no card) so references → root → replies read as one
        // continuous surface — its own internal padding handles the gutter.
        SliverToBoxAdapter(
          child: LargeNoteCard(
            note: root,
            replyCount: replyCount ?? replies.length,
            contained: false,
          ),
        ),

        // ── Replies ───────────────────────────────────────────────────────────
        if (replies.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: ThreadEmptyReplies(),
          )
        else ...[
          SliverPadding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
            sliver: SliverToBoxAdapter(
              child: ThreadSectionLabel(
                '${AppLocalizations.of(context)!.threadReplies} · '
                '${replyCount ?? replies.length}',
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final reply = replies[i];
                  return Column(
                    key: ValueKey('reply-${reply.id}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UnreadTrailMark(marker: unreadMarkers[reply.id]),
                      NoteCard(
                        key: ValueKey(reply.id),
                        note: reply,
                        onTap: () => onOpenThread(reply.id),
                      ),
                    ],
                  );
                },
                childCount: replies.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
