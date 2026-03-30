import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/drawer/bloc/drawer_bloc.dart' as app_drawer;

/// Left-side navigation drawer — standard Flutter Drawer inside Scaffold.
///
/// Sections:
///   Header   — user avatar + name + workspace
///   Nav      — Home, Saved Notes
///   Channels — public channels (Kind 40/42) — placeholder
///   DMs      — direct messages (Kind 14)    — placeholder
///   Apps     — AI Assistant shortcut
///   Footer   — Settings
class VishnuDrawer extends StatelessWidget {
  const VishnuDrawer({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  void _close(BuildContext context) => Navigator.pop(context);

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      width: 280,
      child: BlocBuilder<app_drawer.DrawerBloc, app_drawer.DrawerState>(
        builder: (context, state) {
          final loaded = state is app_drawer.DrawerLoaded ? state : null;
          return Column(
            children: [
              // ── Header ─────────────────────────────────────────────────────
              _DrawerHeader(
                name: loaded?.userName ?? '...',
                npub: loaded?.npub ?? '',
                pubkeyHex: loaded?.pubkeyHex ?? '',
                avatarUrl: loaded?.avatarUrl,
              ),

              // ── Scrollable body ─────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  children: [
                    // ── Main nav ──────────────────────────────────────────
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      active: true,
                      onTap: () => _close(context),
                    ),
                    _NavItem(
                      icon: Icons.bookmark_rounded,
                      label: 'Saved Notes',
                      onTap: () {
                        _close(context);
                        _showComingSoon(context, 'Saved Notes');
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Channels ──────────────────────────────────────────
                    _SectionHeader(
                      label: 'Channels',
                      onAdd: () => _showComingSoon(context, 'Create Channel'),
                    ),
                    const SizedBox(height: 4),
                    if ((loaded?.channels ?? []).isEmpty)
                      const _EmptyHint('No channels yet')
                    else
                      ...loaded!.channels.map((ch) => _ChannelRow(
                            channel: ch,
                            onTap: () {
                              _close(context);
                              _showComingSoon(context, '#${ch.name}');
                            },
                          )),

                    const SizedBox(height: 16),

                    // ── Direct Messages ───────────────────────────────────
                    _SectionHeader(
                      label: 'Direct Messages',
                      onAdd: () => _showComingSoon(context, 'New DM'),
                    ),
                    const SizedBox(height: 4),
                    if ((loaded?.dms ?? []).isEmpty)
                      const _EmptyHint('No messages yet')
                    else
                      ...loaded!.dms.map((dm) => _DmRow(
                            dm: dm,
                            onTap: () {
                              _close(context);
                              _showComingSoon(context, dm.name);
                            },
                          )),

                    const SizedBox(height: 16),

                    // ── Apps ──────────────────────────────────────────────
                    const _SectionHeader(label: 'Apps'),
                    const SizedBox(height: 4),
                    _AppRow(
                      label: 'AI Assistant',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF1A5CB8)],
                      ),
                      icon: Icons.smart_toy_rounded,
                      onTap: () {
                        _close(context);
                        onSwitchTab(2);
                      },
                    ),
                  ],
                ),
              ),

              // ── Footer / Settings ───────────────────────────────────────────
              _DrawerFooter(
                onSettings: () {
                  _close(context);
                  Navigator.pushNamed(context, AppRoutes.settings);
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
    this.avatarUrl,
  });

  final String name;
  final String npub;
  final String pubkeyHex;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              UserAvatar(
                seed: pubkeyHex,
                photoUrl: avatarUrl,
                size: 40,
                borderRadius: 10,
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'UNIUN Workspace',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            color: AppColors.onSurfaceVariant,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.onAdd});

  final String label;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.outline,
              ),
            ),
          ),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.outline),
            ),
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Channel row ────────────────────────────────────────────────────────────────

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onTap});
  final app_drawer.DrawerChannelItem channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            const Icon(Icons.tag_rounded, size: 18, color: AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      channel.hasUnread ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (channel.hasUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── DM row ─────────────────────────────────────────────────────────────────────

class _DmRow extends StatelessWidget {
  const _DmRow({required this.dm, required this.onTap});
  final app_drawer.DrawerDmItem dm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            UserAvatar(seed: dm.pubkey, photoUrl: dm.avatarUrl, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dm.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      dm.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dm.unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${dm.unreadCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── App row ────────────────────────────────────────────────────────────────────

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.label,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Gradient gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: AppColors.onPrimary),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.outlineVariant,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onSettings,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: const Row(
              children: [
                Icon(Icons.settings_rounded,
                    size: 20, color: AppColors.onSurfaceVariant),
                SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
