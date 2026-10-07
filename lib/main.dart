import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/core/router/app_router.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/core/theme/app_theme_mode.dart';
import 'package:uniun/domain/services/note_embedding_worker.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';
import 'package:uniun/core/theme/theme_cubit.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/domain/services/marmot_transport_service.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/features/mesh/engine/mesh_engine_main.dart';
import 'package:uniun/features/mesh/service/mesh_service.dart';

/// Entry point for the **headless mesh `FlutterEngine`**, invoked natively by the
/// Android foreground service / the iOS-macOS AppDelegate. It MUST live in the root
/// library (alongside `main`) because native `DartEntrypoint` / `run(withEntrypoint:)`
/// resolve entry-point function names only in the root library. Delegates to
/// [runMeshEngine]; `@pragma('vm:entry-point')` keeps it past tree-shaking.
@pragma('vm:entry-point')
Future<void> meshEngineMain() => runMeshEngine();

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await _ensureDownloaderCacheDir();
  // flutter_gemma 1.0.0: release builds are silent automatically (the plugin
  // gates every log on `kDebugMode`). In debug, keep `info` — lifecycle and
  // errors, no prompts/output. Bump to `verbose` only when actively chasing a
  // model bug.
  FlutterGemma.logLevel = kReleaseMode
      ? GemmaLogLevel.none
      : GemmaLogLevel.info;
  // 1.0.0 split the monolith — the core registers no engine on its own. We
  // ship .task models (MediaPipe — DeepSeek R1) and .litertlm models
  // (LiteRT-LM — Qwen3 0.6B, Gemma 4 E2B/E4B), plus the LiteRT embedder
  // used by the Shiv RAG pipeline.
  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );
  // Loads PDFium, which PdfrxTextSource needs to pull the text layer out of an
  // attached PDF for the Shiv RAG index. Idempotent.
  await pdfrxFlutterInitialize();
  // Preserve native splash only until Flutter renders its first frame
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await configureDependencies();
  getIt<MarmotTransportService>().start();
  // Offline multi-transport mesh (LAN → BLE → Multipeer). No-op unless the user has
  // opted in and is logged in. MeshService waits for the app to be foreground before
  // touching the native host (Android's foreground-service start rule).
  getIt<MeshService>().start();

  // Keeps Shiv's index of documents and images (on own and saved notes) in
  // step with the media cache. The first launch after an upgrade works
  // through the existing backlog — OCR and embedding, one file at a time;
  // after that it only reacts to new files and saves.
  getIt<DocumentIndexer>().start();

  // Embeds any note still waiting for a vector from a previous run (killed app,
  // embedder not ready). One cheap query when nothing is waiting.
  getIt<NoteEmbeddingWorker>().nudge();

  // Resolve the startup locale synchronously (the AppSettingsStore singleton is
  // already pre-resolved) so the first frame renders in the right language with
  // no flicker. Runtime switches go through LocaleCubit → SetAppLocaleUseCase.
  final initialLocale = LocaleCubit.resolveInitial(
    savedCode: getIt<AppSettingsStore>().localeCode,
    systemLocales: binding.platformDispatcher.locales,
  );

  // Same reasoning for theme: read once, sync, so the first frame renders in
  // the right theme. Null (never picked) ⇒ AppThemeMode.system.
  final initialThemeMode =
      getIt<AppSettingsStore>().themeMode ?? AppThemeMode.system;

  // Remove native splash immediately → SplashPage takes over
  FlutterNativeSplash.remove();

  runApp(UniunApp(
    initialLocale: initialLocale,
    initialThemeMode: initialThemeMode,
  ));
}

/// `background_downloader` (used by flutter_gemma to fetch models) stores its
/// partial-download temp files under `<Caches>/<bundleId>/` but does not create
/// that bundle-id subfolder on sandboxed Apple platforms. Without it the
/// download fails with `PathNotFoundException ... errno = 2`. Create it up front.
Future<void> _ensureDownloaderCacheDir() async {
  if (!Platform.isMacOS && !Platform.isIOS) return;
  try {
    final cacheDir = await getApplicationCacheDirectory();
    final dir = Directory(p.join(cacheDir.path, 'in.uniun.app'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  } catch (_) {
    // Best-effort: if this fails the download will surface its own error.
  }
}

class UniunApp extends StatelessWidget {
  const UniunApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  /// The locale resolved synchronously at startup (see `main`). Seeds
  /// [LocaleCubit]; the user can change it at runtime from the welcome screen,
  /// the language picker, or Settings.
  final Locale initialLocale;

  /// The theme mode resolved synchronously at startup (see `main`). Seeds
  /// [ThemeCubit]; the user can change it at runtime from Settings.
  final AppThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocaleCubit(
            getIt<SetAppLocaleUseCase>(),
            initial: initialLocale,
          ),
        ),
        BlocProvider(
          create: (_) => ThemeCubit(
            getIt<SetThemeModeUseCase>(),
            initial: initialThemeMode,
          ),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, AppThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                title: 'UNIUN',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en'), Locale('hi')],
                locale: locale,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode.materialThemeMode,
                routerConfig: appRouter,
                builder: (context, child) {
                  // Global tap-outside-to-dismiss-keyboard. HitTestBehavior.opaque
                  // is required — the default (deferToChild) means taps on empty
                  // space never reach this GestureDetector. translucent leaves
                  // bubbling intact so list scrolls / button taps still work.
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      final focus = FocusManager.instance.primaryFocus;
                      if (focus != null && focus.hasFocus) focus.unfocus();
                    },
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
