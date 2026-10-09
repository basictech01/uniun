import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_router.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/share_intent/share_intent_service.dart';
import 'package:uniun/features/receive_share/widgets/shared_incoming.dart';
import 'package:uniun/domain/services/marmot_transport_service.dart';
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/features/mesh/service/mesh_service.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';
import 'package:uniun/features/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/features/vishnu/pages/vishnu_feed_page.dart';
import 'package:uniun/features/shiv/gana/engine/gana_engine.dart';
import 'package:uniun/features/shiv/gana/engine/gana_workmanager_bootstrap.dart';
import 'package:uniun/features/shiv/pages/shiv_page.dart';
import 'package:uniun/gateway/gateway.dart';

/// App shell — standard Flutter Scaffold + floating pill nav.
///   0 = Vishnu (feed)
///   1 = Brahma (graph — pushed as a full-screen route)
///   2 = Shiv   (AI assistant)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final VishnuFeedBloc _vishnuFeedBloc;
  late final ShareIntentService _shareIntent;

  // 0 = Vishnu, 2 = Shiv — index 1 navigates away so it never lives in the stack.
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _vishnuFeedBloc = getIt<VishnuFeedBloc>()..add(const FeedOpenedEvent());
    getIt<MarmotTransportService>().start();
    getIt<MeshService>().start();
    getIt<DocumentIndexer>().start();
    getIt<NoteEmbeddingTrigger>().nudge();
    GatewayBootstrap.start();
    // Inbound share: HomePage only mounts for an authenticated user with a live
    // navigator, so this is where we listen for warm-start shares and drain the
    // cold-start payload the app may have been launched with.
    _shareIntent = getIt<ShareIntentService>()..listen(_handleIncomingShare);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _shareIntent.consumeInitial();
      if (initial.isNotEmpty) _handleIncomingShare(initial);
    });
    // Bring up the foreground Gana engine (main-isolate singleton — no
    // separate isolate; see `gana_engine.dart` header for the rationale)
    // and initialize WorkManager for the bg-tick path.
    () async {
      await getIt<GanaEngine>().start();
      await GanaWorkmanagerBootstrap.initialize();
    }();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vishnuFeedBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Foreground engine stays the source of truth while the app is alive.
    // When backgrounded, schedule a one-shot WorkManager tick so interval
    // Ganas don't drift indefinitely while the app is suspended.
    if (state == AppLifecycleState.paused) {
      GanaWorkmanagerBootstrap.scheduleBackground();
    } else if (state == AppLifecycleState.resumed) {
      GanaWorkmanagerBootstrap.cancelBackground();
    }
  }

  /// Routes an inbound OS share to the receive-share sheet. Navigates via the
  /// root navigator so it works from this lifecycle callback.
  void _handleIncomingShare(List<SharedMediaFile> files) {
    final incoming = SharedIncoming.fromFiles(files);
    if (incoming.isEmpty) return;
    rootNavigatorKey.currentContext?.pushNamed(
      AppRoutes.receiveShare,
      extra: incoming,
    );
  }

  Future<void> _switchTab(int i) async {
    if (i == 1) {
      // Brahma is a pushed route, not a stack tab. Its FloatingNav can pop
      // back with an explicit tab index; pop on publish returns null → land
      // on Vishnu so the user sees their new note.
      final targetTab = await context.pushNamed<Object?>(AppRoutes.graph);
      _vishnuFeedBloc.add(const RefreshFeedEvent());
      final destination =
          targetTab is int && targetTab != 1 ? targetTab : 0;
      if (mounted) setState(() => _currentIndex = destination);
      return;
    }
    if (i == 0 && _currentIndex != 0) {
      _vishnuFeedBloc.add(const RefreshFeedEvent());
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VishnuFeedBloc>.value(value: _vishnuFeedBloc),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex == 2 ? 1 : 0,
          children: [
            VishnuFeedPage(
              currentIndex: _currentIndex,
              onSwitchTab: _switchTab,
            ),
            ShivPage(
              currentIndex: _currentIndex,
              onSwitchTab: _switchTab,
            ),
          ],
        ),
      ),
    );
  }
}
