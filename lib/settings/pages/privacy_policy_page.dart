import 'package:flutter/material.dart';
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
      appBar: const SettingsAppBar(title: 'Privacy & Policy'),
      body: Builder(
        builder: (context) {
          final topPad = MediaQuery.of(context).padding.top;
          return ListView(
            padding: EdgeInsets.only(
              top: topPad,
              left: 20,
              right: 20,
              bottom: 48,
            ),
            children: [
              // ── Intro ─────────────────────────────────────────────────────
              const Text(
                'Privacy & Policy',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'UNIUN is built on transparency. Your data stays on your device. '
                'Below is everything you need to know — no legal jargon.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              // ── Privacy Policy Card ───────────────────────────────────────
              _ExpandableSection(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy Policy',
                expanded: _privacyExpanded,
                onToggle: () =>
                    setState(() => _privacyExpanded = !_privacyExpanded),
                child: const _PrivacyPolicyContent(),
              ),

              const SizedBox(height: 16),

              // ── Terms Card ────────────────────────────────────────────────
              _ExpandableSection(
                icon: Icons.gavel_rounded,
                title: 'Terms of Use',
                expanded: _termsExpanded,
                onToggle: () =>
                    setState(() => _termsExpanded = !_termsExpanded),
                child: const _TermsContent(),
              ),

              const SizedBox(height: 32),

              // ── Footer ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Last updated: June 2025',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'privacy@uniun.app',
                          style: TextStyle(
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

              const Center(
                child: Text(
                  'UNIUN v1.0.0-beta',
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.outlineVariant),
        SizedBox(height: 12),

        _PolicySection(
          title: 'What We Store Locally',
          body:
              'UNIUN stores your notes, profile, saved items, channel messages, and settings directly on your device. '
              'This data is not sent to any server controlled by UNIUN.',
        ),

        _PolicySection(
          title: 'What Gets Shared Publicly',
          body:
              'When you publish a note or send a message in a public channel, that content is broadcast to Nostr relays. '
              'Nostr is an open public protocol — once published, your notes may be visible to anyone connected to those relays. '
              'UNIUN does not control third-party relays.',
        ),

        _PolicySection(
          title: 'Your Identity & Keys',
          body:
              'Your identity is a cryptographic key pair. Your public key is visible to others on the Nostr network. '
              'Your private key (nsec) is stored exclusively in your device\'s secure system keychain (iOS Keychain / Android Keystore). '
              'UNIUN never transmits your private key to any server.',
        ),

        _PolicySection(
          title: 'Local AI (Shiv)',
          body:
              'The Shiv AI assistant runs entirely on your device. It accesses only your locally saved notes. '
              'No note content is sent to any external AI service or API.',
        ),

        _PolicySection(
          title: 'Media & Blossom Servers',
          body:
              'If you attach images or media, they may be uploaded to a Blossom content server of your choice. '
              'UNIUN does not operate Blossom servers. Content uploaded there may be publicly accessible by design of the protocol.',
        ),

        _PolicySection(
          title: 'Direct Messages',
          body:
              'DMs are end-to-end encrypted using the Nostr NIP-17 standard. '
              'Only the intended recipient can read the message content. '
              'Message routing metadata may be visible to relays.',
        ),

        _PolicySection(
          title: 'Your Control',
          body:
              'You can delete your local data at any time from Settings. '
              'Because Nostr is a public protocol, notes already published to relays cannot be retracted — '
              'this is an intentional property of the network, not a limitation of the app.',
        ),

        _PolicySection(
          title: 'Contact',
          body: 'For privacy questions: privacy@uniun.app',
        ),
      ],
    );
  }
}

// ── Terms content ─────────────────────────────────────────────────────────────

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.outlineVariant),
        SizedBox(height: 12),

        _PolicySection(
          title: 'Your Responsibility',
          body:
              'You are solely responsible for all content you publish on UNIUN. '
              'By using the app, you agree not to post content that is illegal, abusive, harassing, or violates others\' rights.',
        ),

        _PolicySection(
          title: 'No Abuse or Spam',
          body:
              'Do not use UNIUN to spam, harass, impersonate others, or conduct automated activity that disrupts the Nostr network.',
        ),

        _PolicySection(
          title: 'Keep Your Private Key Safe',
          body:
              'Your private key (nsec) is your identity and login. If you lose it, your account cannot be recovered — '
              'UNIUN has no way to reset or recover private keys. Back it up in a secure location.',
        ),

        _PolicySection(
          title: 'Public Content on Relays',
          body:
              'Notes and channel messages you publish are sent to Nostr relays and may be visible to anyone on the network. '
              'Do not share sensitive personal information in public notes.',
        ),

        _PolicySection(
          title: 'App May Change',
          body:
              'UNIUN is in active development. Features, relay behavior, and policies may change over time. '
              'We will communicate significant updates within the app.',
        ),

        _PolicySection(
          title: 'No Warranty',
          body:
              'UNIUN is provided as-is. We make no guarantees about relay uptime, third-party server availability, '
              'or persistence of content on external relays.',
        ),
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
