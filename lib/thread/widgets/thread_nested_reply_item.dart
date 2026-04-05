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

class ThreadNestedReplyItem extends StatefulWidget {
  const ThreadNestedReplyItem({
    super.key,
    required this.reply,
    this.profile,
    required this.onReplyTap,
    required this.nestedReplies,
    required this.allProfiles,
    required this.replyCounts,
    this.depth = 0,
    /// Whether this item is the last sibling at its level.
    /// When false a thread line is drawn below the avatar to connect to the
    /// next sibling.
    this.isLastSibling = true,
  });

  final NoteEntity reply;
  final ProfileEntity? profile;
  final VoidCallback onReplyTap;
  final Map<String, List<NoteEntity>> nestedReplies;
  final Map<String, ProfileEntity> allProfiles;
  final Map<String, int> replyCounts;
  final int depth;
  final bool isLastSibling;

  @override
  State<ThreadNestedReplyItem> createState() => _ThreadNestedReplyItemState();
}

class _ThreadNestedReplyItemState extends State<ThreadNestedReplyItem> {
  bool _isSaved = false;
  bool _showChildren = true;

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
  void didUpdateWidget(ThreadNestedReplyItem old) {
    super.didUpdateWidget(old);
    final myChildren = widget.nestedReplies[widget.reply.id] ?? [];
    final oldChildren = old.nestedReplies[old.reply.id] ?? [];
    if (myChildren.length > oldChildren.length) {
      setState(() => _showChildren = true);
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

    final children = widget.nestedReplies[widget.reply.id] ?? [];
    final replyCount = widget.replyCounts[widget.reply.id] ?? children.length;
    final hasChildren = children.isNotEmpty;
    final hasReplies = replyCount > 0 || hasChildren;
    // Show a vertical line below the avatar when:
    // - there are children about to be rendered below, OR
    // - this is NOT the last sibling (next sibling follows at the same level)
    final showLine =
        (hasChildren && _showChildren) || !widget.isLastSibling;

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + optional sibling/child thread line
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  UserAvatar(
                    seed: widget.reply.authorPubkey,
                    photoUrl: profile?.avatarUrl,
                    size: 32,
                    borderRadius: 16,
                  ),
                  if (showLine)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: widget.isLastSibling && !hasChildren ? 0 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${threadTimeAgo(widget.reply.created)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.reply.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onReplyTap,
                          child: const Icon(Icons.reply_rounded,
                              size: 16, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        if (hasReplies)
                          GestureDetector(
                            onTap: () {
                              // If children not yet loaded (beyond BFS depth),
                              // fetch them now on first expand
                              if (!_showChildren && !hasChildren) {
                                context.read<ThreadBloc>().add(
                                      ExpandReplyEvent(widget.reply.id),
                                    );
                              }
                              setState(() => _showChildren = !_showChildren);
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Text(
                                  '$replyCount',
                                  style: const TextStyle(
                                    fontSize: 11,
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
                            size: 16,
                            color: _isSaved
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Recursive children
                    if (_showChildren && hasChildren) ...[
                      const SizedBox(height: 8),
                      ...List.generate(children.length, (i) {
                        final child = children[i];
                        final isLast = i == children.length - 1;
                        final name =
                            widget.allProfiles[child.authorPubkey]?.name ??
                                threadShortPubkey(child.authorPubkey);
                        return ThreadNestedReplyItem(
                          key: ValueKey(child.id),
                          reply: child,
                          profile: widget.allProfiles[child.authorPubkey],
                          nestedReplies: widget.nestedReplies,
                          allProfiles: widget.allProfiles,
                          replyCounts: widget.replyCounts,
                          depth: widget.depth + 1,
                          isLastSibling: isLast,
                          onReplyTap: () {
                            context.read<ThreadBloc>().add(
                                  SetReplyTargetEvent(
                                    replyToId: child.id,
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
