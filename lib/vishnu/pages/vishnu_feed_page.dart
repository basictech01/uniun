import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/home/bloc/drawer_bloc.dart' as app_drawer;
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/vishnu/widgets/note_card.dart';

class VishnuFeedPage extends StatelessWidget {
  const VishnuFeedPage({super.key, required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return _VishnuFeedView(onOpenDrawer: onOpenDrawer);
  }
}

// ── Feed view ─────────────────────────────────────────────────────────────────

class _VishnuFeedView extends StatefulWidget {
  const _VishnuFeedView({required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  State<_VishnuFeedView> createState() => _VishnuFeedViewState();
}

class _VishnuFeedViewState extends State<_VishnuFeedView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<VishnuFeedBloc>().add(const LoadMoreFeedEvent());
    }
  }

  Future<void> _onRefresh() async {
    context.read<VishnuFeedBloc>().add(const RefreshFeedEvent());
    await context.read<VishnuFeedBloc>().stream.firstWhere(
          (s) => s.status != VishnuFeedStatus.loading,
          orElse: () => const VishnuFeedState(),
        );
  }

  Future<void> _toggleFollow(
    BuildContext ctx,
    String noteId,
    String contentPreview,
    bool isCurrentlyFollowed,
  ) async {
    final cubit = ctx.read<FollowedNotesCubit>();
    if (isCurrentlyFollowed) {
      await cubit.unfollowNote(noteId);
    } else {
      await cubit.followNote(noteId, contentPreview);
    }
    // Refresh drawer so the following section updates
    if (ctx.mounted) {
      ctx.read<app_drawer.DrawerBloc>().add(app_drawer.DrawerLoadEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          _FeedHeader(onOpenDrawer: widget.onOpenDrawer),

          // ── Feed list ────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<VishnuFeedBloc, VishnuFeedState>(
              builder: (context, feedState) {
                // Initial loading
                if (feedState.status == VishnuFeedStatus.loading &&
                    feedState.notes.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }

                // Error with no notes
                if (feedState.status == VishnuFeedStatus.error &&
                    feedState.notes.isEmpty) {
                  return _ErrorView(
                    message:
                        feedState.errorMessage ?? 'Something went wrong',
                    onRetry: () => context
                        .read<VishnuFeedBloc>()
                        .add(const LoadFeedEvent()),
                  );
                }

                // Empty feed
                if (feedState.notes.isEmpty) {
                  return const _EmptyFeedView();
                }

                // Feed list
                return BlocBuilder<FollowedNotesCubit, FollowedNotesState>(
                  builder: (context, followedState) {
                    final followedIds =
                        followedState.notes.map((n) => n.eventId).toSet();

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: feedState.notes.length +
                            (feedState.status ==
                                    VishnuFeedStatus.loadingMore
                                ? 1
                                : 0),
                        itemBuilder: (context, i) {
                          if (i == feedState.notes.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final note = feedState.notes[i];
                          final profile =
                              feedState.profiles[note.authorPubkey];
                          final replyCount =
                              feedState.replyCounts[note.id] ?? 0;
                          final isFollowed = followedIds.contains(note.id);

                          return NoteCard(
                            note: note,
                            profile: profile,
                            replyCount: replyCount,
                            isFollowed: isFollowed,
                            isSaved: feedState.savedIds.contains(note.id),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.thread,
                              arguments: note.id,
                            ),
                            onFollowTap: () => _toggleFollow(
                              context,
                              note.id,
                              note.content.length > 80
                                  ? '${note.content.substring(0, 80)}…'
                                  : note.content,
                              isFollowed,
                            ),
                            onSaveTap: () {
                              final bloc = context.read<VishnuFeedBloc>();
                              final saved = feedState.savedIds.contains(note.id);
                              if (saved) {
                                bloc.add(UnsaveFeedNoteEvent(note.id));
                              } else {
                                bloc.add(SaveFeedNoteEvent(note));
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed header ───────────────────────────────────────────────────────────────

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Drawer / logo button
          GestureDetector(
            onTap: onOpenDrawer,
            child: const Row(
              children: [
                Image(
                  image: AssetImage('assets/images/uniun-logo.png'),
                  height: 28,
                  width: 28,
                ),
                SizedBox(width: 8),
                Text(
                  'UNIUN',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Notifications bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.onSurface),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          // Avatar — shows logged-in user's actual profile picture
          GestureDetector(
            onTap: onOpenDrawer,
            child: BlocBuilder<app_drawer.DrawerBloc, app_drawer.DrawerState>(
              builder: (context, drawerState) {
                String? avatarUrl;
                String seed = '';
                if (drawerState is app_drawer.DrawerLoaded) {
                  avatarUrl = drawerState.avatarUrl;
                  seed = drawerState.pubkeyHex;
                }
                return UserAvatar(
                  seed: seed,
                  photoUrl: avatarUrl,
                  size: 36,
                  borderRadius: 10,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined,
              size: 52, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            l10n.vishnuNoNotes,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.vishnuCreateFirst,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.actionRetry),
          ),
        ],
      ),
    );
  }
}
