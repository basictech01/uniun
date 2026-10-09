import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/l10n/app_language.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/core/router/app_routes.dart';

/// Welcome / landing screen.
/// No top app bar, no bottom nav — pure onboarding shell.
///
/// Flow:
///   "Create Your Avatar"  → AboutYouPage (generate a new keypair)
///   "Restore Your Avatar" → ImportIdentityPage (import an existing nsec)
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Language picker (EN / हिन्दी toggle + "More languages") ────
            _LanguageBar(l10n: l10n),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── UNIUN brand (glow + logo + wordmark + subtitle) ──────
                      const _BrandBlock(),
                      const SizedBox(height: 12),
                      _Subtitle(l10n: l10n),

                      const SizedBox(height: 28),

                      // ── Trimurti pillars ─────────────────────────────────────
                      _TrimurtiPillars(l10n: l10n),

                      const SizedBox(height: 44),

                      // ── Primary — Create Your Avatar ─────────────────────────
                      _PrimaryButton(
                        onPressed: () {
                          // Generate keypair here so both AboutYou and KeysPage
                          // can receive them as route arguments.
                          final keychain = Keychain.generate();
                          final npub = Nip19.encodePubkey(keychain.public);
                          final nsec = Nip19.encodePrivkey(keychain.private);
                          context.pushNamed(
                            AppRoutes.aboutYou,
                            extra: {
                              'npub': npub,
                              'nsec': nsec,
                              'pubkeyHex': keychain.public,
                            },
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.welcomeCreateIdentity,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Secondary — Restore existing key ─────────────────────
                      _SecondaryButton(
                        onPressed: () =>
                            context.pushNamed(AppRoutes.importIdentity),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.vpn_key_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.welcomeImportKey,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Learn more ───────────────────────────────────────────
                      GestureDetector(
                        onTap: () => context.pushNamed(AppRoutes.howItWorks),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.welcomeLearnHow,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand block ───────────────────────────────────────────────────────────────

/// Logo over a soft radial brand glow, with the gradient UNIUN wordmark below.
class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // soft radial glow
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.18),
                      Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.06),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.45, 0.75],
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/images/uniun-logo-mark.svg',
                width: 88,
                height: 88,
              ),
            ],
          ),
        ),
        // gradient wordmark
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ).createShader(bounds),
          child: const Text(
            'UNIUN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Your decentralized **second brain**" — muted lead, brand-blue emphasis.
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.welcomeSubtitleLead,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: l10n.welcomeSubtitleEmphasis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trimurti pillars ──────────────────────────────────────────────────────────

/// Three equal-width pillars — Brahma · Vishnu · Shiv — inside one bordered,
/// faint-blue-tinted card with thin dividers.
class _TrimurtiPillars extends StatelessWidget {
  const _TrimurtiPillars({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      width: 1,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
    );
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
          ),
          // soft brand glow radiating behind the pillar card
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.18),
              blurRadius: 36,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _Pillar(
              deity: l10n.welcomePillarBrahma,
              role: l10n.welcomeRoleCreate,
              iconAsset: 'assets/images/tabs/brahma.svg',
            ),
            divider,
            _Pillar(
              deity: l10n.welcomePillarVishnu,
              role: l10n.welcomeRoleReflect,
              iconAsset: 'assets/images/tabs/vishnu.svg',
            ),
            divider,
            _Pillar(
              deity: l10n.welcomePillarShiv,
              role: l10n.welcomeRoleTransform,
              iconAsset: 'assets/images/tabs/shiva.svg',
            ),
          ],
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.deity,
    required this.role,
    required this.iconAsset,
  });

  final String deity;
  final String role;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              deity,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              role.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Button widgets ────────────────────────────────────────────────────────────

/// Gradient primary — primary action.
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
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.28),
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
        height: 58,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
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

// ── Language picker ───────────────────────────────────────────────────────────

/// Top-of-screen language controls: a compact EN / हिन्दी segmented toggle,
/// with a "More languages" link to the full picker.
class _LanguageBar extends StatelessWidget {
  const _LanguageBar({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _LanguageToggle(),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.pushNamed(AppRoutes.selectLanguage),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.welcomeMoreLanguages,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-segment pill bound to [LocaleCubit]. Other supported languages remain
/// available in the full picker without crowding the welcome screen.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final active = context.watch<LocaleCubit>().activeLanguage;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in const [AppLanguage.english, AppLanguage.hindi])
            _Segment(
              label: lang.nativeName,
              selected: lang == active,
              onTap: () => context.read<LocaleCubit>().setLanguage(lang),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
