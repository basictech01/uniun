import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';

class ThreadReplyComposer extends StatelessWidget {
  const ThreadReplyComposer({
    super.key,
    required this.state,
    required this.controller,
    required this.focusNode,
    this.avatarUrl,
    this.pubkeySeed = '',
  });

  final ThreadState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? avatarUrl;
  final String pubkeySeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: Colors.white.withValues(alpha: 0.90),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Replying to @name" pill
          if (state.replyingToId != null && state.replyingToName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.threadReplyingTo(state.replyingToName!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => context
                          .read<ThreadBloc>()
                          .add(const SetReplyTargetEvent()),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

          // Composer row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                UserAvatar(
                  seed: pubkeySeed,
                  photoUrl: avatarUrl,
                  size: 32,
                  borderRadius: 16,
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: state.replyingToName != null
                          ? l10n.threadReplyTo(state.replyingToName!)
                          : l10n.threadReplyToThis,
                      hintStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (v) => context
                        .read<ThreadBloc>()
                        .add(UpdateReplyTextEvent(v)),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),

                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.image_outlined,
                      size: 20, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.alternate_email_rounded,
                      size: 20, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: 10),

                // Post button
                GestureDetector(
                  onTap: state.canPost
                      ? () => context
                          .read<ThreadBloc>()
                          .add(const PostReplyEvent())
                      : null,
                  child: AnimatedOpacity(
                    opacity: state.canPost ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF1672df)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: state.postStatus == ThreadPostStatus.posting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              l10n.threadPost,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
