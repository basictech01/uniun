import 'package:flutter/material.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Flutter splash screen — shown immediately after native splash.
/// Runs DI (Isar open) in parallel with a 1.2s minimum display.
/// Navigates to WelcomePage (or HomePage if already logged in).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    // DI + minimum splash time run in parallel
    await Future.wait([
      configureDependencies(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    if (!mounted) return;

    // TODO: check UserRepository.getActiveUser()
    // → if Right(user) → AppRoutes.home
    // → else → AppRoutes.welcome
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FadeTransition(
        opacity: _fade,
        child: const Center(
          child: Image(
            image: AssetImage('assets/images/splash.png'),
            width: 200,
          ),
        ),
      ),
    );
  }
}
