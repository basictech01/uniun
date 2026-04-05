import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/brahma/pages/brahma_create_page.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';
import 'package:uniun/home/bloc/drawer_bloc.dart' as app_drawer;
import 'package:uniun/home/widgets/vishnu_drawer.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/home/widgets/floating_nav.dart';
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/vishnu/pages/vishnu_feed_page.dart';
import 'package:uniun/shiv/pages/shiv_page.dart';

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

  Future<void> _switchTab(int i) async {
    if (i == 0 && _currentIndex != 0) {
      _vishnuFeedBloc.add(const RefreshFeedEvent());
    }

    // When tapping Shiv tab, check if a model is downloaded first.
    // If not, send the user to the selection screen instead of switching tabs.
    if (i == 2 && _currentIndex != 2) {
      final result = await getIt<GetActiveAIModelUseCase>().call();
      final hasModel = result.fold((_) => false, (m) => m != null);
      if (!hasModel && mounted) {
        await Navigator.of(context).pushNamed(AppRoutes.aiModelSelection);
        // After returning, re-check — only switch to Shiv if they downloaded one
        final result2 = await getIt<GetActiveAIModelUseCase>().call();
        final nowHasModel = result2.fold((_) => false, (m) => m != null);
        if (!nowHasModel || !mounted) return;
      }
    }

    if (mounted) setState(() => _currentIndex = i);
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
                  const ShivPage(),
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
