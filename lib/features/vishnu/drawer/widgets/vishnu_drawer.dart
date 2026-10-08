import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/qr/uniun_qr_card.dart';
import 'package:uniun/common/qr/uniun_qr_scanner_page.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/common/note_thread_navigator.dart';
import 'package:uniun/features/profile/pages/user_profile_page.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart' as app_drawer;
import 'package:uniun/features/vishnu/drawer/utils/drawer_search.dart';

class VishnuDrawer extends StatefulWidget {
  const VishnuDrawer({super.key});

  @override
  State<VishnuDrawer> createState() => _VishnuDrawerState();
}

class _VishnuDrawerState extends State<VishnuDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _close(BuildContext context) => Navigator.pop(context);

  // Reuses the exact per-surface navigation of the sectioned rows, switched on
  // the result's kind. Keeps the unified search list free of nav branching.
  Future<void> _onResultTap(
    BuildContext context,
    DrawerSearchResult result,
  ) async {
    switch (result.kind) {
      case DrawerSearchKind.group:
        _close(context);
        context.pushNamed(
          AppRoutes.groupDetail,
          pathParameters: {'groupId': result.id},
        );
      case DrawerSearchKind.privateGroup:
        _close(context);
        context.pushNamed(
          AppRoutes.privateGroupDetail,
          pathParameters: {'groupId': result.id},
        );
      case DrawerSearchKind.dm:
        _close(context);
        context.pushNamed(
          AppRoutes.chatDm,
          pathParameters: {'id': result.id},
        );
      case DrawerSearchKind.followedUser:
        _close(context);
        context.pushNamed(
          AppRoutes.userProfile,
          extra: UserProfileArgs(pubkeyHex: result.id),
        );
      case DrawerSearchKind.followedNote:
        _close(context);
        await openEventThread(
          context,
          result.id,
          openAsNote: () => context.pushNamed(
            AppRoutes.thread,
            pathParameters: {'noteId': result.id},
          ),
        );
        // ignore: use_build_context_synchronously
        if (context.mounted) {
          context.read<app_drawer.DrawerBloc>().add(app_drawer.DrawerLoadEvent());
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      width: 312,
      child: BlocBuilder<app_drawer.DrawerBloc, app_drawer.DrawerState>(
        builder: (context, state) {
          final loaded = state is app_drawer.DrawerLoaded ? state : null;
          final l10n = AppLocalizations.of(context)!;
          return Column(
            children: [
              _DrawerHeader(
                name: loaded?.userName ?? '...',
                npub: loaded?.npub ?? '',
                pubkeyHex: loaded?.pubkeyHex ?? '',
                avatarUrl: loaded?.avatarUrl,
                myRelays: loaded?.myRelays ?? const [],
                onScan: () => context.pushNamed(AppRoutes.scanQr),
              ),

              _DrawerSearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                onClear: () => setState(() {
                  _searchController.clear();
                  _query = '';
                }),
              ),

              Expanded(
                child: _query.trim().isNotEmpty
                    ? _SearchResultsList(
                        results: loaded == null
                            ? const <DrawerSearchResult>[]
                            : buildDrawerSearchResults(loaded, _query),
                        onTap: (r) => _onResultTap(context, r),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        children: [
                          // ── Main nav ────────────────────────────────────
                          _NavItem(
                            icon: Icons.home_rounded,
                            label: l10n.drawerHome,
                            active: true,
                            onTap: () => _close(context),
                          ),
                          _NavItem(
                            icon: Icons.bookmark_rounded,
                            label: l10n.drawerSavedNotes,
                            onTap: () {
                              _close(context);
                              context.pushNamed(AppRoutes.savedNotes);
                            },
                          ),
                          _NavItem(
                            icon: Icons.wifi_tethering_rounded,
                            label: l10n.drawerSurrounding,
                            onTap: () {
                              _close(context);
                              context.pushNamed(AppRoutes.surrounding);
                            },
                          ),

                          const SizedBox(height: 8),

                          // ── Direct messages ─────────────────────────────
                          _CollapsibleSection(
                            title: l10n.drawerDirectMessages,
                            itemCount: (loaded?.dms ?? []).length,
                            emptyHint: l10n.drawerNoMessages,
                            onAdd: () {
                              _close(context);
                              context.pushNamed(AppRoutes.createDm);
                            },
                            children: [
                              for (final dm in loaded?.dms ?? [])
                                _ListRow(
                                  leading: UserAvatar(
                                    seed: dm.pubkey,
                                    photoUrl: dm.avatarUrl,
                                    size: 32,
                                  ),
                                  title: dm.name,
                                  trailing: dm.unreadCount > 0
                                      ? _CountBadge(dm.unreadCount)
                                      : null,
                                  onTap: () {
                                    _close(context);
                                    context.pushNamed(
                                      AppRoutes.chatDm,
                                      pathParameters: {'id': dm.pubkey},
                                    );
                                  },
                                ),
                            ],
                          ),

                          // ── Groups ────────────────────────────────────
                          _CollapsibleSection(
                            title: l10n.drawerGroups,
                            itemCount: (loaded?.groups ?? []).length,
                            emptyHint: l10n.drawerNoGroups,
                            onAdd: () {
                              _close(context);
                              context.pushNamed(AppRoutes.groupEntry);
                            },
                            children: [
                              for (final ch in loaded?.groups ?? [])
                                _ListRow(
                                  leading: const _IconSquare(Icons.tag_rounded),
                                  title: ch.name,
                                  trailing: ch.unreadCount > 0 ? _CountBadge(ch.unreadCount) : null,
                                  onTap: () {
                                    _close(context);
                                    context.pushNamed(
                                      AppRoutes.groupDetail,
                                      pathParameters: {'groupId': ch.id},
                                    );
                                  },
                                ),
                            ],
                          ),

                          // ── Private groups ────────────────────────────
                          _CollapsibleSection(
                            title: l10n.drawerPrivateGroups,
                            itemCount: (loaded?.privateGroups ?? []).length,
                            emptyHint: l10n.drawerNoPrivateGroups,
                            onAdd: () {
                              _close(context);
                              context.pushNamed(AppRoutes.privateGroupEntry);
                            },
                            children: [
                              for (final ch in loaded?.privateGroups ?? [])
                                _ListRow(
                                  leading:
                                      const _IconSquare(Icons.lock_rounded),
                                  title: ch.name,
                                  subtitle: l10n.drawerPrivateLabel,
                                  trailing: ch.unreadCount > 0 ? _CountBadge(ch.unreadCount) : null,
                                  onTap: () {
                                    _close(context);
                                    context.pushNamed(
                                      AppRoutes.privateGroupDetail,
                                      pathParameters: {'groupId': ch.id},
                                    );
                                  },
                                ),
                            ],
                          ),

                          // ── Followed notes ──────────────────────────────
                          _CollapsibleSection(
                            title: l10n.drawerFollowingNotes,
                            itemCount: (loaded?.followedNotes ?? []).length,
                            emptyHint: l10n.drawerNoFollowedNotes,
                            children: [
                              for (final item in loaded?.followedNotes ?? [])
                                _ListRow(
                                  leading: const _IconSquare(Icons.link_rounded),
                                  title: item.contentPreview,
                                  trailing: item.newReferenceCount > 0
                                      ? _CountBadge(
                                          item.newReferenceCount,
                                          activity: true,
                                        )
                                      : null,
                                  onTap: () async {
                                    _close(context);
                                    await openEventThread(
                                      context,
                                      item.eventId,
                                      openAsNote: () => context.pushNamed(
                                        AppRoutes.thread,
                                        pathParameters: {'noteId': item.eventId},
                                      ),
                                    );
                                    // ignore: use_build_context_synchronously
                                    if (context.mounted) {
                                      context.read<app_drawer.DrawerBloc>().add(
                                          app_drawer.DrawerLoadEvent());
                                    }
                                  },
                                ),
                            ],
                          ),

                          // ── Following users ─────────────────────────────
                          _CollapsibleSection(
                            title: l10n.drawerFollowingSectionTitle,
                            itemCount: (loaded?.followedUsers ?? []).length,
                            emptyHint: l10n.drawerFollowingEmpty,
                            onAdd: () {
                              _close(context);
                              context.pushNamed(
                                AppRoutes.scanQr,
                                extra: UniunQrScanIntent.follow,
                              );
                            },
                            children: [
                              for (final user in loaded?.followedUsers ?? [])
                                _ListRow(
                                  leading: UserAvatar(
                                    seed: user.pubkey,
                                    photoUrl: user.avatarUrl,
                                    size: 32,
                                  ),
                                  title: user.name,
                                  onTap: () {
                                    _close(context);
                                    context.pushNamed(
                                      AppRoutes.userProfile,
                                      extra:
                                          UserProfileArgs(pubkeyHex: user.pubkey),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
              ),

              _DrawerFooter(
                onSettings: () {
                  _close(context);
                  context.pushNamed(AppRoutes.settings);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.name,
    required this.npub,
    required this.pubkeyHex,
    required this.myRelays,
    required this.onScan,
    this.avatarUrl,
  });

  final String name;
  final String npub;
  final String pubkeyHex;
  final String? avatarUrl;
  final List<String> myRelays;
  final VoidCallback onScan;

  void _showQr(BuildContext context) {
    if (npub.isEmpty) return;
    UniunQrCard.show(
      context,
      card: UniunQrCard.user(
        npub: npub,
        name: name,
        relays: myRelays,
        avatarSeed: pubkeyHex,
        avatarUrl: avatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 18, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                seed: pubkeyHex,
                photoUrl: avatarUrl,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QrActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: l10n.drawerMyQrCode,
                  onTap: () => _showQr(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QrActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: l10n.drawerScanCode,
                  onTap: onScan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Bordered "My QR code" / "Scan code" pill in the drawer header.
class _QrActionButton extends StatelessWidget {
  const _QrActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Collapsible section ────────────────────────────────────────────────────────
//
// One reusable section header + expandable body. Collapse default rule: a list
// with more than 3 items starts collapsed; 3 or fewer start expanded. Once the
// user taps the header their choice wins (and survives async item reloads,
// because the user toggle is preferred over the count-derived default).

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    required this.itemCount,
    required this.emptyHint,
    required this.children,
    this.onAdd,
  });

  final String title;
  final int itemCount;
  final String emptyHint;
  final List<Widget> children;
  final VoidCallback? onAdd;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  bool? _userExpanded;
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;

  bool get _expanded => _userExpanded ?? widget.itemCount <= 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _expanded ? 1 : 0,
    );
    _sizeFactor =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  // itemCount can change after an async reload; if the user hasn't toggled, the
  // count-derived default may flip, so re-sync the controller to it.
  @override
  void didUpdateWidget(covariant _CollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final target = _expanded ? 1.0 : 0.0;
    if (_controller.value == target) return;
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _toggle() {
    setState(() => _userExpanded = !_expanded);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: Theme.of(context).colorScheme.outline),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onAdd != null)
                InkWell(
                  onTap: widget.onAdd,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add_rounded,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        // Vertical accordion — clip height only. AnimatedCrossFade animated both
        // axes, which made rows appear to grow horizontally from center.
        SizeTransition(
          alignment: Alignment.topCenter,
          sizeFactor: _sizeFactor,
          child: Column(
            children: [
              if (widget.itemCount == 0)
                _EmptyHint(widget.emptyHint)
              else
                ...widget.children,
            ],
          ),
        ),
      ],
    );
  }
}

// ── Nav item ───────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── List row ───────────────────────────────────────────────────────────────────
//
// The shared drawer list row: leading avatar/icon-square + title (+ optional
// muted subtitle) + optional trailing badge. Used by every section.

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// Icon inside a tinted rounded square — group #, private lock, followed link.
class _IconSquare extends StatelessWidget {
  const _IconSquare(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
    );
  }
}

// Count pill. Filled (primary) for unread; tinted (activity) for reference counts.
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count, {this.activity = false});
  final int count;
  final bool activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: activity
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: activity ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// Small unread dot for surfaces that only carry a boolean (groups / private).
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ── Search field ───────────────────────────────────────────────────────────────
//
// Pinned just under the header. While it holds text the body below swaps to a
// unified result list (_SearchResultsList).

class _DrawerSearchField extends StatelessWidget {
  const _DrawerSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: color),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.drawerSearchHint,
          hintStyle: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.outline),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: Theme.of(context).colorScheme.outline),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 38),
          suffixIcon: controller.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Theme.of(context).colorScheme.outline),
                ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 38),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: border(Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
          enabledBorder:
              border(Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
          focusedBorder: border(Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

// ── Search results ─────────────────────────────────────────────────────────────
//
// Flat, mixed list of matches across every drawer surface. Each row carries a
// leading avatar (users / DMs) or type icon-square so intermixed kinds stay
// identifiable at a glance.

IconData _searchIconFor(DrawerSearchKind kind) {
  switch (kind) {
    case DrawerSearchKind.group:
      return Icons.tag_rounded;
    case DrawerSearchKind.privateGroup:
      return Icons.lock_rounded;
    case DrawerSearchKind.dm:
      return Icons.chat_bubble_outline_rounded;
    case DrawerSearchKind.followedNote:
      return Icons.link_rounded;
    case DrawerSearchKind.followedUser:
      return Icons.person_outline_rounded;
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.results, required this.onTap});

  final List<DrawerSearchResult> results;
  final void Function(DrawerSearchResult result) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          l10n.drawerSearchNoResults,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.outlineVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final r = results[i];
        // DMs and followed users both render as an avatar + name; a kind
        // subtitle keeps the two visually distinct in the mixed list.
        final hasAvatar = (r.kind == DrawerSearchKind.dm ||
                r.kind == DrawerSearchKind.followedUser);
        final String? subtitle = switch (r.kind) {
          DrawerSearchKind.dm => l10n.drawerSearchKindDm,
          DrawerSearchKind.followedUser => l10n.drawerSearchKindUser,
          _ => null,
        };
        return _ListRow(
          leading: hasAvatar
              ? UserAvatar(seed: r.id, photoUrl: r.avatarUrl, size: 32)
              : _IconSquare(_searchIconFor(r.kind)),
          title: r.label,
          subtitle: subtitle,
          trailing: r.hasUnread ? const _Dot() : null,
          onTap: () => onTap(r),
        );
      },
    );
  }
}

// ── Empty hint ─────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.outlineVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onSettings,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.settings_rounded,
                    size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.drawerSettings,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Theme.of(context).colorScheme.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
