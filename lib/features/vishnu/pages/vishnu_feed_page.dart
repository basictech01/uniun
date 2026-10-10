import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/floating_nav.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart' as app_drawer;
import 'package:uniun/features/vishnu/drawer/widgets/vishnu_drawer.dart';
import 'package:uniun/features/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/features/vishnu/widgets/new_notes_banner.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/note_thread_navigator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VishnuFeedPage extends StatefulWidget {
  const VishnuFeedPage({
    super.key,
    required this.currentIndex,
    required this.onSwitchTab,
  });
  final int currentIndex;
  final Future<void> Function(int) onSwitchTab;

  @override
  State<VishnuFeedPage> createState() => _VishnuFeedPageState();
}

class _VishnuFeedPageState extends State<VishnuFeedPage> {
  late final app_drawer.DrawerBloc _drawerBloc;
  // Bottom-nav visibility is a ValueNotifier (not setState) so scroll-driven
  // hide/show animates only the FloatingNav and never rebuilds the feed list.
  final ValueNotifier<bool> _navVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _drawerBloc = getIt<app_drawer.DrawerBloc>()
      ..add(app_drawer.DrawerLoadEvent());
  }

  @override
  void dispose() {
    _navVisible.dispose();
    _drawerBloc.close();
    super.dispose();
  }

  void _onScrollDirection(ScrollDirection direction) {
    // ValueNotifier ignores no-op writes, so no equality guard is needed and
    // ScrollDirection.idle leaves the last value untouched.
    if (direction == ScrollDirection.reverse) {
      _navVisible.value = false;
    } else if (direction == ScrollDirection.forward) {
      _navVisible.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<app_drawer.DrawerBloc>.value(
      value: _drawerBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        drawer: const VishnuDrawer(),
        onDrawerChanged: (isOpen) {
          if (isOpen) {
            _drawerBloc.add(app_drawer.DrawerLoadEvent());
          }
        },
        body: Stack(
          children: [
            _VishnuFeedView(onScrollDirection: _onScrollDirection),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _navVisible,
                child: FloatingNav(
                  currentIndex: widget.currentIndex,
                  onTap: widget.onSwitchTab,
                ),
                builder: (context, visible, child) => AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 1.5),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feed view ─────────────────────────────────────────────────────────────────

class _VishnuFeedView extends StatefulWidget {
  const _VishnuFeedView({required this.onScrollDirection});
  final void Function(ScrollDirection) onScrollDirection;

  @override
  State<_VishnuFeedView> createState() => _VishnuFeedViewState();
}

class _VishnuFeedViewState extends State<_VishnuFeedView> {
  final _scrollController = ScrollController();
  final Set<String> _everVisible = <String>{};
  // New-notes banner visibility — ValueNotifier so scroll updates rebuild only
  // the banner, not the ListView.
  final ValueNotifier<bool> _scrollingUp = ValueNotifier<bool>(false);

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
    _scrollingUp.dispose();
    super.dispose();
  }

  void _onScroll() {
    final dir = _scrollController.position.userScrollDirection;
    widget.onScrollDirection(dir);
    // The "new notes" button only surfaces while scrolling up toward the top;
    // it stays hidden while reading/scrolling down. Idle keeps the last state
    // (ValueNotifier ignores no-op writes).
    if (dir == ScrollDirection.forward) {
      _scrollingUp.value = true;
    } else if (dir == ScrollDirection.reverse) {
      _scrollingUp.value = false;
    }
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

  Future<void> _onLoadNewNotes() async {
    context.read<VishnuFeedBloc>().add(const LoadNewNotesEvent());
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Per-note visibility callback. Marks as seen once the user has had the
  /// note majority-visible at some point AND it has now left the viewport.
  /// Debounced via [_everVisible] + bloc's [_markedThisSession] set.
  void _onNoteVisibility(String eventId, VisibilityInfo info) {
    if (!mounted) return;
    if (info.visibleFraction >= 0.5) {
      _everVisible.add(eventId);
    } else if (info.visibleFraction == 0 && _everVisible.contains(eventId)) {
      context.read<VishnuFeedBloc>().add(MarkFeedItemSeenEvent(eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bottom inset is intentionally NOT reserved here: the feed extends
    // edge-to-edge behind the floating glass nav (the list adds its own bottom
    // padding for the inset + nav), so no white safe-area strip shows.
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          const _FeedHeader(),

          // ── Feed list ────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<VishnuFeedBloc, VishnuFeedState>(
              builder: (context, feedState) {
                // Initial loading
                if (feedState.status == VishnuFeedStatus.loading &&
                    feedState.items.isEmpty) {
                  return Center(
                    child: DropLoadingIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                // Error with no items
                if (feedState.status == VishnuFeedStatus.error &&
                    feedState.items.isEmpty) {
                  return _ErrorView(
                    message: feedState.errorMessage ?? 'Something went wrong',
                    onRetry: () => context.read<VishnuFeedBloc>().add(
                      const FeedOpenedEvent(),
                    ),
                  );
                }

                // Empty feed
                if (feedState.items.isEmpty) {
                  return const _EmptyFeedView();
                }

                // Feed list. NoteCard self-manages profile/saved/followed.
                return Builder(
                  builder: (context) {
                    return RefreshIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      onRefresh: _onRefresh,
                      child: Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 96,
                            ),
                              itemCount: feedState.items.length +
                                  (feedState.status ==
                                          VishnuFeedStatus.loadingMore
                                      ? 1
                                      : 0),
                              itemBuilder: (context, i) {
                                if (i == feedState.items.length) {
                                  return Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: DropLoadingIndicator(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  );
                                }

                                final note = feedState.items[i];

                                return VisibilityDetector(
                                  key: ValueKey('feed-${note.id}'),
                                  onVisibilityChanged: (info) =>
                                      _onNoteVisibility(note.id, info),
                                  child: NoteCard(
                                    key: ValueKey(note.id),
                                    note: note,
                                    onTap: () => openEventThread(
                                      context,
                                      note.id,
                                      openAsNote: () => context.pushNamed(
                                        AppRoutes.thread,
                                        pathParameters: {'noteId': note.id},
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          // Floating overlay — sits above the listview with
                          // no background of its own, so it doesn't steal
                          // vertical space when there's nothing new.
                          Positioned(
                            top: 4,
                            left: 0,
                            right: 0,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _scrollingUp,
                              builder: (context, scrollingUp, _) {
                                final showBanner =
                                    scrollingUp && feedState.newCount > 0;
                                return IgnorePointer(
                                  ignoring: !showBanner,
                                  child: NewNotesBanner(
                                    count: showBanner ? feedState.newCount : 0,
                                    onTap: _onLoadNewNotes,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Drawer / logo button
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/tabs/vishnu.svg',
                  height: 32,
                  width: 32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.vishnuFeedEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.vishnuFeedEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                // Re-reads Isar: followed accounts' notes land here once the
                // gateway has synced them, even if they predate this session.
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<VishnuFeedBloc>()
                      .add(const RefreshFeedEvent()),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.vishnuFeedEmptyRefresh),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.scanQr),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: Text(l10n.vishnuFeedEmptyCta),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
