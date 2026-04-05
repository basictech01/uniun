import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';
import 'package:uniun/thread/utils/thread_formatters.dart';

class ThreadRootNoteCard extends StatefulWidget {
  const ThreadRootNoteCard({
    super.key,
    required this.note,
    this.profile,
  });

  final NoteEntity note;
  final ProfileEntity? profile;

  @override
  State<ThreadRootNoteCard> createState() => _ThreadRootNoteCardState();
}

class _ThreadRootNoteCardState extends State<ThreadRootNoteCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    getIt<IsSavedNoteUseCase>()
        .call(widget.note.id)
        .then((r) => r.fold((_) {}, (v) {
              if (mounted) setState(() => _isSaved = v);
            }));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final followedState = context.watch<FollowedNotesCubit>().state;
    final isFollowed =
        followedState.notes.any((n) => n.eventId == widget.note.id);

    final profile = widget.profile;
    final displayName = profile?.name ??
        profile?.username ??
        threadShortPubkey(widget.note.authorPubkey);
    final handle = profile?.username != null
        ? '@${profile!.username}'
        : '@${threadShortPubkey(widget.note.authorPubkey)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              UserAvatar(
                seed: widget.note.authorPubkey,
                photoUrl: profile?.avatarUrl,
                size: 48,
                borderRadius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          threadTimeAgo(widget.note.created),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      handle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Text(
            widget.note.content,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.onSurface,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          // Hashtags
          if (widget.note.tTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.note.tTags
                  .take(5)
                  .map((t) => Text(
                        '#$t',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ))
                  .toList(),
            ),
          ],

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
              height: 1,
            ),
          ),

          // Action row — no like button
          Row(
            children: [
              ThreadActionChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${context.watch<ThreadBloc>().state.replies.length}',
                color: AppColors.onSurfaceVariant,
                onTap: () {},
              ),
              const SizedBox(width: 24),

              ThreadActionChip(
                icon: isFollowed ? Icons.link_rounded : Icons.add_link_rounded,
                label: isFollowed ? l10n.actionFollowing : l10n.actionFollow,
                color: isFollowed
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                onTap: () {
                  final cubit = context.read<FollowedNotesCubit>();
                  if (isFollowed) {
                    cubit.unfollowNote(widget.note.id);
                  } else {
                    cubit.followNote(
                      widget.note.id,
                      threadContentPreview(widget.note.content),
                    );
                  }
                },
              ),

              const Spacer(),

              // Save toggle — persisted to Isar
              GestureDetector(
                onTap: () async {
                  final nowSaved = !_isSaved;
                  setState(() => _isSaved = nowSaved); // optimistic
                  if (nowSaved) {
                    final result = await getIt<SaveNoteUseCase>().call(widget.note);
                    result.fold(
                      (_) { if (mounted) setState(() => _isSaved = false); },
                      (_) {},
                    );
                  } else {
                    final result = await getIt<UnsaveNoteUseCase>().call(widget.note.id);
                    result.fold(
                      (_) { if (mounted) setState(() => _isSaved = true); },
                      (_) {},
                    );
                  }
                },
                child: Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 22,
                  color:
                      _isSaved ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared action chip used in root card ──────────────────────────────────────

class ThreadActionChip extends StatelessWidget {
  const ThreadActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
