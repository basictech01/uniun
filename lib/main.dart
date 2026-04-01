import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/home/pages/home_page.dart';
import 'package:uniun/onboarding/pages/about_you_page.dart';
import 'package:uniun/followed_notes/pages/followed_note_feed_page.dart';
import 'package:uniun/followed_notes/pages/followed_notes_page.dart';
import 'package:uniun/followed_notes/note_intelligence_detail/pages/note_intelligence_page.dart';
import 'package:uniun/settings/pages/edit_profile_page.dart';
import 'package:uniun/settings/pages/privacy_policy_page.dart';
import 'package:uniun/settings/pages/settings_page.dart';
import 'package:uniun/onboarding/pages/import_identity_page.dart';
import 'package:uniun/onboarding/pages/splash_page.dart';
import 'package:uniun/onboarding/pages/welcome_page.dart';
import 'package:uniun/onboarding/pages/your_identity_keys_page.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash only until Flutter renders its first frame
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Remove native splash immediately → SplashPage takes over
  FlutterNativeSplash.remove();

  runApp(const UniunApp());
}

class UniunApp extends StatelessWidget {
  const UniunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIUN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.welcome: (_) => const WelcomePage(),
        AppRoutes.importIdentity: (_) => const ImportIdentityPage(),
        AppRoutes.yourIdentityKeys: (_) => const YourIdentityKeysPage(),
        AppRoutes.aboutYou: (_) => const AboutYouPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.editProfile: (_) => const EditProfilePage(),
        AppRoutes.privacyPolicy: (_) => const PrivacyPolicyPage(),
        AppRoutes.followedNotes: (_) => const FollowedNotesPage(),
        AppRoutes.followedNoteFeed: (ctx) => FollowedNoteFeedPage(
              eventId: ModalRoute.of(ctx)!.settings.arguments as String,
            ),
        AppRoutes.noteIntelligence: (ctx) => NoteIntelligencePage(
              noteId: ModalRoute.of(ctx)!.settings.arguments as String?,
            ),
      },
    );
  }
}
