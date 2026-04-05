import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/followed_notes/followed_note_detail/cubit/followed_note_detail_cubit.dart';
import 'package:uniun/followed_notes/followed_note_detail/widgets/note_header_card.dart';
import 'package:uniun/followed_notes/followed_note_detail/widgets/followed_note_app_bar.dart';
import 'package:uniun/followed_notes/followed_note_detail/widgets/note_references_section.dart';
import 'package:uniun/followed_notes/followed_note_detail/widgets/note_thread_button.dart';

class FollowedNoteDetailPage extends StatelessWidget {
  const FollowedNoteDetailPage({super.key, required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FollowedNoteDetailCubit>()..load(noteId),
      child: const _FollowedNoteDetailView(),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _FollowedNoteDetailView extends StatelessWidget {
  const _FollowedNoteDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: BlocBuilder<FollowedNoteDetailCubit, FollowedNoteDetailState>(
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  FollowedNoteAppBar(onBack: () => Navigator.pop(context)),
                  if (state.status == FollowedNoteDetailStatus.loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    )
                  else if (state.status == FollowedNoteDetailStatus.error)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          state.errorMessage ?? AppLocalizations.of(context)!.followedNoteFailedToLoad,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else if (state.note != null)
                    _NoteContent(state: state),
                ],
              ),
              if (state.note != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomActionBar(
                    onViewThread: () => Navigator.pushNamed(
                      context,
                      AppRoutes.thread,
                      arguments: state.note!.id,
                    ),
                    onAddComment: () => Navigator.pushNamed(
                      context,
                      AppRoutes.thread,
                      arguments: state.note!.id,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Content sliver ────────────────────────────────────────────────────────────

class _NoteContent extends StatelessWidget {
  const _NoteContent({required this.state});
  final FollowedNoteDetailState state;

  String _displayName(String pubkey, Map<String, ProfileEntity> profiles) {
    final p = profiles[pubkey];
    return p?.name ?? p?.username ?? '${pubkey.substring(0, 8)}…';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = state.note!;
    final profile = state.profile;
    final authorName = profile?.name ??
        profile?.username ??
        '${note.authorPubkey.substring(0, 8)}…';

    final allProfiles = {
      if (profile != null) note.authorPubkey: profile,
      ...state.replyProfiles,
    };

    final replyEntries = state.replies
        .map((r) => ReferenceEntry(
              title: _displayName(r.authorPubkey, allProfiles),
              subtitle: r.content.length > 100
                  ? r.content.substring(0, 100)
                  : r.content,
            ))
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          NoteHeaderCard(
            authorName: authorName,
            authorPubkey: note.authorPubkey,
            avatarUrl: profile?.avatarUrl,
            content: note.content,
            hashtags: note.tTags,
            timestamp: note.created,
            commentCount: state.replies.length,
          ),
          const SizedBox(height: 28),

          if (replyEntries.isNotEmpty) ...[
            NoteReferencesSection(
              title: l10n.followedNoteReferencedBy,
              references: replyEntries,
              style: ReferenceSectionStyle.grid,
              badge: '${replyEntries.length} REPLIES',
            ),
            const SizedBox(height: 28),
          ],

          if (state.replies.isNotEmpty)
            NoteThreadSection(
              continuationText: state.replies.first.content.length > 100
                  ? '${state.replies.first.content.substring(0, 100)}…'
                  : state.replies.first.content,
              replyCount: state.replies.length,
              lastUpdated: _timeAgo(state.replies.first.created),
            ),
        ]),
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onViewThread,
    required this.onAddComment,
  });

  final VoidCallback onViewThread;
  final VoidCallback onAddComment;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceContainerLow.withValues(alpha: 0),
            AppColors.surfaceContainerLow.withValues(alpha: 0.96),
            AppColors.surfaceContainerLow,
          ],
          stops: const [0, 0.3, 0.7],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onViewThread,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hub_rounded,
                        color: AppColors.onPrimary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.followedNoteViewThread,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAddComment,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_comment_rounded,
                color: AppColors.onSurface,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
