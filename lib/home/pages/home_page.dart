import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/brahma/pages/brahma_create_page.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/home/bloc/drawer_bloc.dart' as app_drawer;
import 'package:uniun/home/widgets/vishnu_drawer.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/home/widgets/floating_nav.dart';
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/vishnu/pages/vishnu_feed_page.dart';

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
  late final VishnuFeedBloc _vishnuFeedBloc;
  late final FollowedNotesCubit _followedNotesCubit;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _drawerBloc = getIt<app_drawer.DrawerBloc>()..add(app_drawer.DrawerLoadEvent());
    // Create once here so we can refresh it when switching back to tab 0
    _vishnuFeedBloc = getIt<VishnuFeedBloc>()..add(const LoadFeedEvent());
    _followedNotesCubit = getIt<FollowedNotesCubit>()..load();
  }

  @override
  void dispose() {
    _drawerBloc.close();
    _vishnuFeedBloc.close();
    _followedNotesCubit.close();
    super.dispose();
  }

  void _switchTab(int i) {
    // Refresh the feed whenever returning to Vishnu from another tab
    // — keeps it up-to-date after creating a note in Brahma
    if (i == 0 && _currentIndex != 0) {
      _vishnuFeedBloc.add(const RefreshFeedEvent());
    }
    setState(() => _currentIndex = i);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<app_drawer.DrawerBloc>.value(value: _drawerBloc),
        BlocProvider<VishnuFeedBloc>.value(value: _vishnuFeedBloc),
        BlocProvider<FollowedNotesCubit>.value(value: _followedNotesCubit),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        // false = keyboard doesn't push the floating nav pill up
        resizeToAvoidBottomInset: false,
        drawer: VishnuDrawer(onSwitchTab: _switchTab),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 88),
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  VishnuFeedPage(onOpenDrawer: _openDrawer),
                  BrahmaCreatePage(onPublished: () => _switchTab(0)),
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

class _ShivPlaceholder extends StatelessWidget {
  const _ShivPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.content_cut_rounded,
                size: 48, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              l10n.homeShivTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeShivComingSoon,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
