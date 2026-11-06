import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/drop_icon.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/brahma/utils/manas_icons.dart';
import 'package:uniun/l10n/app_localizations.dart';
/// "Learn how UNIUN works" — a simple, swipeable intro carousel reached from the
/// Welcome screen's learn-more link.
///
/// Six friendly slides (second brain → the three modules → knowledge graph →
/// your keys → offline & private → get started). Skip and the final "Get
/// started" both [context.pop] back to Welcome, so the keypair-generation path
/// stays solely on the Welcome screen.
class HowItWorksPage extends StatefulWidget {
  const HowItWorksPage({super.key});

  @override
  State<HowItWorksPage> createState() => _HowItWorksPageState();
}

class _HowItWorksPageState extends State<HowItWorksPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  /// Close the carousel. Normally it was pushed from Welcome, so we pop back;
  /// if it happens to be the root route (nothing to pop), go to Welcome.
  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final slides = <_Slide>[
      _Slide(
        hero: const _LogoHero(),
        title: l10n.howItWorksIntroTitle,
        body: l10n.howItWorksIntroBody,
      ),
      _Slide(
        hero: const _DeityHero(asset: 'assets/images/tabs/brahma.svg'),
        title: l10n.howItWorksBrahmaTitle,
        body: l10n.howItWorksBrahmaBody,
        features: [
          _Feature(
            icon: Icon(Icons.edit_note_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileNote,
            desc: l10n.howItWorksDescNote,
          ),
          _Feature(
            // Mirror the in-app Manas glyph (single source of truth) rather than
            // hardcoding it here, so the how-to tile tracks any change to it.
            icon: Icon(ManasIcons.fallback,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileManas,
            desc: l10n.howItWorksDescManas,
          ),
          _Feature(
            icon: Icon(Icons.hub_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileGraph,
            desc: l10n.howItWorksDescGraph,
          ),
        ],
      ),
      _Slide(
        hero: const _DeityHero(asset: 'assets/images/tabs/vishnu.svg'),
        title: l10n.howItWorksVishnuTitle,
        body: l10n.howItWorksVishnuBody,
        features: [
          _Feature(
            icon: Icon(Icons.person_outline_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTilePeople,
            desc: l10n.howItWorksDescPeople,
          ),
          _Feature(
            icon: Icon(Icons.tag_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileGroups,
            desc: l10n.howItWorksDescGroups,
          ),
          _Feature(
            icon: Icon(Icons.lock_outline_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTilePrivate,
            desc: l10n.howItWorksDescPrivate,
          ),
          _Feature(
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileDms,
            desc: l10n.howItWorksDescDms,
          ),
        ],
      ),
      _Slide(
        hero: const _DeityHero(asset: 'assets/images/tabs/shiva.svg'),
        title: l10n.howItWorksShivTitle,
        body: l10n.howItWorksShivBody,
        features: [
          _Feature(
            icon: DropIcon(size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileAdiyogi,
            desc: l10n.howItWorksDescAdiyogi,
          ),
          _Feature(
            icon: Icon(
              Icons.cyclone_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            name: l10n.howItWorksTileNataraj,
            desc: l10n.howItWorksDescNataraj,
          ),
          _Feature(
            icon: Icon(Icons.auto_mode_rounded,
                size: 24, color: Theme.of(context).colorScheme.primary),
            name: l10n.howItWorksTileGana,
            desc: l10n.howItWorksDescGana,
          ),
        ],
      ),
      _Slide(
        hero: const _GlowHero(icon: Icons.vpn_key_rounded),
        title: l10n.howItWorksKeysTitle,
        body: l10n.howItWorksKeysBody,
      ),
      _Slide(
        hero: const _GlowHero(icon: Icons.cloud_off_rounded),
        title: l10n.howItWorksPrivateTitle,
        body: l10n.howItWorksPrivateBody,
      ),
      _Slide(
        hero: const _GlowHero(icon: Icons.auto_awesome_rounded),
        title: l10n.howItWorksReadyTitle,
        body: l10n.howItWorksReadyBody,
      ),
    ];
    final isLast = _index == slides.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress dots (top) ──────────────────────────────────────
            const SizedBox(height: 20),
            _Dots(count: slides.length, index: _index),

            // ── Slides ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _SlideView(slide: slides[i]),
              ),
            ),

            // ── Next / Get started, with Skip below (hidden + inert on
            //    the last slide) ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UniunButton(
                    variant: UniunButtonVariant.hero,
                    onPressed: () => isLast ? _close(context) : _next(),
                    label: isLast
                        ? l10n.howItWorksGetStarted
                        : l10n.howItWorksNext,
                    trailing: isLast
                        ? null
                        : Icon(
                            Icons.arrow_forward_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: AnimatedOpacity(
                      opacity: isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: isLast ? null : () => _close(context),
                        child: Text(
                          l10n.howItWorksSkip,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.hero,
    required this.title,
    this.body,
    this.features,
  });

  final Widget hero;
  final String title;

  /// Short lead under the title. Optional.
  final String? body;

  /// Per-sub-feature sections (icon + name + description). Pillar slides only.
  final List<_Feature>? features;
}

/// One sub-feature row: its real in-app icon, its name, and a short description.
class _Feature {
  const _Feature({required this.icon, required this.name, required this.desc});

  final Widget icon;
  final String name;
  final String desc;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    // Scrollable + min-height so content centres on tall screens and never
    // overflows on short ones.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                slide.hero,
                SizedBox(height: slide.features == null ? 40 : 28),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  // Display serif (--font-display Newsreader) — the design
                  // system reserves this for brand/onboarding headlines.
                  // h1 28 · semibold · -0.02em tracking. Variable-font axes
                  // pin the weight + an optical size suited to display.
                  style: TextStyle(
                    fontFamily: 'Newsreader',
                    fontVariations: [
                      FontVariation('wght', 600),
                      FontVariation('opsz', 28),
                    ],
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.56,
                    height: 1.2,
                  ),
                ),
                if (slide.body != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    slide.body!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),
                ],
                if (slide.features != null) ...[
                  const SizedBox(height: 24),
                  for (final f in slide.features!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FeatureRow(feature: f),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Heroes ────────────────────────────────────────────────────────────────────

/// Soft radial brand glow — shared backdrop for every hero.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.06),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 0.75],
        ),
      ),
    );
  }
}

/// Logo over the brand glow with the gradient UNIUN wordmark — the intro hero.
class _LogoHero extends StatelessWidget {
  const _LogoHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const _GlowCircle(),
              SvgPicture.asset(
                'assets/images/uniun-logo-mark.svg',
                width: 96,
                height: 96,
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
          ).createShader(bounds),
          child: const Text(
            'UNIUN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single Material glyph in a tinted disc over the brand glow.
class _GlowHero extends StatelessWidget {
  const _GlowHero({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _GlowCircle(),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

/// A pillar hero: the module's large tab glyph (Brahma / Vishnu / Shiv — the
/// same bottom-nav icon) inside a tinted disc over the brand glow, so the user
/// learns to recognise the tab inside the app.
class _DeityHero extends StatelessWidget {
  const _DeityHero({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _GlowCircle(),
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: 72,
                height: 72,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One sub-feature section: an app-style rounded icon tile (the exact icon the
/// feature shows elsewhere in the app), its name, and a short description.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: feature.icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feature.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.desc,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Page dots ─────────────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
