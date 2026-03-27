import 'package:flutter/material.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Welcome / landing screen.
/// No top app bar, no bottom nav — pure onboarding shell.
///
/// Flow:
///   "Create New Identity"  → YourIdentityKeysPage
///   "I Already Have a Key" → ImportIdentityPage
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── UNIUN brand ──────────────────────────────────────────
                Image.asset(
                  'assets/images/uniun-logo.png',
                  width: 72,
                  height: 72,
                ),
                const SizedBox(height: 12),
                const Text(
                  'UNIUN',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Hero tagline ─────────────────────────────────────────
                const Text(
                  'Your notes, your\nnetwork, your identity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 16),

                // thin accent divider
                Container(
                  width: 64,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                const SizedBox(height: 64),

                // ── Primary — Create New Identity ────────────────────────
                _PrimaryButton(
                  onPressed: () {
                    // Generate keypair here so both AboutYou and KeysPage
                    // can receive them as route arguments.
                    final keychain = Keychain.generate();
                    final npub = Nip19.encodePubkey(keychain.public);
                    final nsec = Nip19.encodePrivkey(keychain.private);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.aboutYou,
                      arguments: {'npub': npub, 'nsec': nsec},
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_rounded,
                          color: AppColors.onPrimary, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Create New Identity',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Secondary — Import existing key ──────────────────────
                _SecondaryButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.importIdentity),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_rounded,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'I Already Have a Key',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Learn more ───────────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    // TODO: open how-it-works page
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Learn how UNIUN works',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary, size: 16),
                    ],
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

// ── Button widgets ────────────────────────────────────────────────────────────

/// Blue gradient — primary action.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF005AB6).withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// White card with subtle border — secondary action.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
