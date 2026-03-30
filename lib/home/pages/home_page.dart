import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/drawer/bloc/drawer_bloc.dart' as app_drawer;
import 'package:uniun/drawer/widgets/vishnu_drawer.dart';
import 'package:uniun/home/widgets/floating_nav.dart';

/// App shell — standard Flutter Scaffold + Drawer + floating pill nav.
///   0 = Vishnu (feed)
///   1 = Brahma (create note)
///   2 = Shiv   (AI assistant)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final app_drawer.DrawerBloc _drawerBloc;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _drawerBloc = app_drawer.DrawerBloc()..add(app_drawer.DrawerLoadEvent());
  }

  @override
  void dispose() {
    _drawerBloc.close();
    super.dispose();
  }

  void _switchTab(int i) => setState(() => _currentIndex = i);
  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<app_drawer.DrawerBloc>.value(
      value: _drawerBloc,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        drawer: VishnuDrawer(onSwitchTab: _switchTab),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 88),
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _VishnuPlaceholder(onOpenDrawer: _openDrawer),
                  const _BrahmaPlaceholder(),
                  const _ShivPlaceholder(),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: FloatingNav(
                currentIndex: _currentIndex,
                onTap: _switchTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vishnu tab top bar ────────────────────────────────────────────────────────

class _VishnuPlaceholder extends StatelessWidget {
  const _VishnuPlaceholder({required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
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
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.onSurface),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
                BlocBuilder<app_drawer.DrawerBloc, app_drawer.DrawerState>(
                  builder: (context, state) {
                    final loaded =
                        state is app_drawer.DrawerLoaded ? state : null;
                    return GestureDetector(
                      onTap: onOpenDrawer,
                      child: UserAvatar(
                        seed: loaded?.pubkeyHex ?? '',
                        photoUrl: loaded?.avatarUrl,
                        size: 36,
                        borderRadius: 10,
                      ),
                    );
                  },
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
            Text('Brahma — Create Notes',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            SizedBox(height: 8),
            Text('Note composition coming soon.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
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
            Text('Shiv — AI Assistant',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            SizedBox(height: 8),
            Text('On-device AI coming soon.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
