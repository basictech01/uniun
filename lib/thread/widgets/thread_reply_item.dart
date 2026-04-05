import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';
import 'package:uniun/thread/utils/thread_formatters.dart';
import 'package:uniun/thread/widgets/thread_nested_reply_item.dart';

class ThreadReplyItem extends StatefulWidget {
  const ThreadReplyItem({
    super.key,
    required this.reply,
    this.profile,
    required this.nestedReplies,
    required this.nestedProfiles,
    required this.allNestedReplies,
    required this.replyCounts,
    required this.replyCount,
    required this.showThreadLine,
    required this.onReplyTap,
  });

  final NoteEntity reply;
  final ProfileEntity? profile;
  final List<NoteEntity> nestedReplies;
  final Map<String, ProfileEntity> nestedProfiles;
  final Map<String, List<NoteEntity>> allNestedReplies;
  final Map<String, int> replyCounts;
  final int replyCount;
  final bool showThreadLine;
  final VoidCallback onReplyTap;

  @override
  State<ThreadReplyItem> createState() => _ThreadReplyItemState();
}

class _ThreadReplyItemState extends State<ThreadReplyItem> {
  bool _isSaved = false;
  bool _showNested = false;

  @override
  void initState() {
    super.initState();
    getIt<IsSavedNoteUseCase>()
        .call(widget.reply.id)
        .then((r) => r.fold((_) {}, (v) {
              if (mounted) setState(() => _isSaved = v);
            }));
  }

  @override
  void didUpdateWidget(ThreadReplyItem old) {
    super.didUpdateWidget(old);
    if (widget.nestedReplies.length > old.nestedReplies.length) {
      setState(() => _showNested = true);
    }
  }

  Future<void> _toggleSave() async {
    final nowSaved = !_isSaved;
    setState(() => _isSaved = nowSaved);
    if (nowSaved) {
      final result = await getIt<SaveNoteUseCase>().call(widget.reply);
      result.fold(
        (_) { if (mounted) setState(() => _isSaved = false); },
        (_) {},
      );
    } else {
      final result = await getIt<UnsaveNoteUseCase>().call(widget.reply.id);
      result.fold(
        (_) { if (mounted) setState(() => _isSaved = true); },
        (_) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final displayName = profile?.name ??
        profile?.username ??
        threadShortPubkey(widget.reply.authorPubkey);

    final showLine = widget.showThreadLine ||
        (widget.nestedReplies.isNotEmpty && _showNested);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thread line column
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  UserAvatar(
                    seed: widget.reply.authorPubkey,
                    photoUrl: profile?.avatarUrl,
                    size: 40,
                    borderRadius: 20,
                  ),
                  if (showLine)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${threadTimeAgo(widget.reply.created)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reply.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Actions
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onReplyTap,
                          child: const Icon(Icons.reply_rounded,
                              size: 18, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 20),
                        if (widget.replyCount > 0)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showNested = !_showNested),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.replyCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleSave,
                          child: Icon(
                            _isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                            color: _isSaved
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Nested replies
                    if (_showNested && widget.nestedReplies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...List.generate(widget.nestedReplies.length, (i) {
                        final nested = widget.nestedReplies[i];
                        final isLast = i == widget.nestedReplies.length - 1;
                        final name =
                            widget.nestedProfiles[nested.authorPubkey]?.name ??
                                threadShortPubkey(nested.authorPubkey);
                        return ThreadNestedReplyItem(
                          key: ValueKey(nested.id),
                          reply: nested,
                          profile: widget.nestedProfiles[nested.authorPubkey],
                          nestedReplies: widget.allNestedReplies,
                          allProfiles: widget.nestedProfiles,
                          replyCounts: widget.replyCounts,
                          depth: 0,
                          isLastSibling: isLast,
                          onReplyTap: () {
                            context.read<ThreadBloc>().add(
                                  SetReplyTargetEvent(
                                    replyToId: nested.id,
                                    replyToName: name,
                                  ),
                                );
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
