import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// App shell — floating glassmorphism pill nav with three tabs:
///   0 = Vishnu (feed)
///   1 = Brahma (create note)
///   2 = Shiv   (AI assistant)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _tabs = [
    _VishnuPlaceholder(),
    _BrahmaPlaceholder(),
    _ShivPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // No bottomNavigationBar — we use a Stack overlay instead
      body: Stack(
        children: [
          // ── Tab body ────────────────────────────────────────────────────
          // Add bottom padding so content clears the floating nav
          Padding(
            padding: const EdgeInsets.only(bottom: 88),
            child: _tabs[_currentIndex],
          ),

          // ── Floating pill nav ───────────────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _FloatingNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating glassmorphism nav ─────────────────────────────────────────────────

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(icon: Icons.visibility_outlined, activeIcon: Icons.visibility_rounded, label: 'VISHNU'),
    _NavItem(icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded, label: 'BRAHMA'),
    _NavItem(icon: Icons.content_cut_outlined, activeIcon: Icons.content_cut_rounded, label: 'SHIV'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (i) => _NavTab(
                item: _items[i],
                selected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single tab in the nav ─────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 20 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab placeholder bodies ─────────────────────────────────────────────────────

class _VishnuPlaceholder extends StatelessWidget {
  const _VishnuPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Row(
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.onSurface),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondaryContainer,
                  child: const Icon(Icons.person_rounded,
                      size: 20, color: AppColors.secondary),
                ),
              ],
            ),
          ),

          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded,
                      size: 48, color: AppColors.outlineVariant),
                  SizedBox(height: 16),
                  Text(
                    'Hello from Vishnu 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your feed will appear here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrahmaPlaceholder extends StatelessWidget {
  const _BrahmaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_rounded,
                size: 48, color: AppColors.outlineVariant),
            SizedBox(height: 16),
            Text(
              'Brahma — Create Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Note composition coming soon.',
              style: TextStyle(
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

class _ShivPlaceholder extends StatelessWidget {
  const _ShivPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_cut_rounded,
                size: 48, color: AppColors.outlineVariant),
            SizedBox(height: 16),
            Text(
              'Shiv — AI Assistant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'On-device AI coming soon.',
              style: TextStyle(
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
