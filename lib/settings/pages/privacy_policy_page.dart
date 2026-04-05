import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/constants/app_constants.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/settings/widgets/settings_app_bar.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _privacyExpanded = true;
  bool _termsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: SettingsAppBar(title: AppLocalizations.of(context)!.privacyPageTitle),
      body: Builder(
        builder: (context) {
          final topPad = MediaQuery.of(context).padding.top;
          final l10n = AppLocalizations.of(context)!;
          return ListView(
            padding: EdgeInsets.only(
              top: topPad,
              left: 20,
              right: 20,
              bottom: 48,
            ),
            children: [
              // ── Intro ─────────────────────────────────────────────────────
              Text(
                l10n.privacyIntroTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.privacyIntroBody,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              // ── Privacy Policy Card ───────────────────────────────────────
              _ExpandableSection(
                icon: Icons.lock_outline_rounded,
                title: l10n.privacyExpandPrivacy,
                expanded: _privacyExpanded,
                onToggle: () =>
                    setState(() => _privacyExpanded = !_privacyExpanded),
                child: _PrivacyPolicyContent(),
              ),

              const SizedBox(height: 16),

              // ── Terms Card ────────────────────────────────────────────────
              _ExpandableSection(
                icon: Icons.gavel_rounded,
                title: l10n.privacyExpandTerms,
                expanded: _termsExpanded,
                onToggle: () =>
                    setState(() => _termsExpanded = !_termsExpanded),
                child: _TermsContent(),
              ),

              const SizedBox(height: 32),

              // ── Footer ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.privacyLastUpdated,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppConstants.kPrivacyEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  l10n.appVersion,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.outline,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Expandable section ────────────────────────────────────────────────────────

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
        ],
      ),
    );
  }
}

// ── Privacy Policy content ────────────────────────────────────────────────────

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.outlineVariant),
        const SizedBox(height: 12),
        _PolicySection(title: l10n.privacyStoredLocallyTitle, body: l10n.privacyStoredLocallyBody),
        _PolicySection(title: l10n.privacySharedPubliclyTitle, body: l10n.privacySharedPubliclyBody),
        _PolicySection(title: l10n.privacyIdentityKeysTitle, body: l10n.privacyIdentityKeysBody),
        _PolicySection(title: l10n.privacyLocalAiTitle, body: l10n.privacyLocalAiBody),
        _PolicySection(title: l10n.privacyMediaTitle, body: l10n.privacyMediaBody),
        _PolicySection(title: l10n.privacyDmsTitle, body: l10n.privacyDmsBody),
        _PolicySection(title: l10n.privacyControlTitle, body: l10n.privacyControlBody),
        _PolicySection(title: l10n.privacyContactTitle, body: l10n.privacyContactBody),
      ],
    );
  }
}

// ── Terms content ─────────────────────────────────────────────────────────────

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.outlineVariant),
        const SizedBox(height: 12),
        _PolicySection(title: l10n.termsResponsibilityTitle, body: l10n.termsResponsibilityBody),
        _PolicySection(title: l10n.termsNoAbuseTitle, body: l10n.termsNoAbuseBody),
        _PolicySection(title: l10n.termsPrivateKeyTitle, body: l10n.termsPrivateKeyBody),
        _PolicySection(title: l10n.termsPublicContentTitle, body: l10n.termsPublicContentBody),
        _PolicySection(title: l10n.termsAppMayChangeTitle, body: l10n.termsAppMayChangeBody),
        _PolicySection(title: l10n.termsNoWarrantyTitle, body: l10n.termsNoWarrantyBody),
      ],
    );
  }
}

// ── Shared section item ───────────────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 14,
                margin: const EdgeInsets.only(top: 3, right: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
