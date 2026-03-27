import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Shows the generated npub + nsec after profile setup.
/// Route args: Map{'npub': String, 'nsec': String}
///
/// Step-based reveal:
///   Step 0 — public key only (must copy to proceed)
///   Step 1 — private key revealed after pub is copied (must copy to proceed)
///   Step 2 — Save & Continue enabled after both keys copied
class YourIdentityKeysPage extends StatefulWidget {
  const YourIdentityKeysPage({super.key});

  @override
  State<YourIdentityKeysPage> createState() => _YourIdentityKeysPageState();
}

class _YourIdentityKeysPageState extends State<YourIdentityKeysPage> {
  bool _pubKeyCopied = false;
  bool _privKeyCopied = false;
  bool _nsecVisible = false;

  void _copyPub(String value) {
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _pubKeyCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Public key copied — now reveal your private key'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyPriv(String value) {
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _privKeyCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Private key copied — store it somewhere safe!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadBackup(String npub, String nsec) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/uniun_keys_backup.txt');
      await file.writeAsString(
        'UNIUN Identity Backup\n'
        '=====================\n\n'
        'Public Key (npub):\n$npub\n\n'
        'Private Key (nsec):\n$nsec\n\n'
        'WARNING: Never share your private key with anyone.\n'
        'Lose this file = lose access to your account forever.\n',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save backup')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final npub = args['npub'] as String? ?? 'npub1...';
    final nsec = args['nsec'] as String? ?? 'nsec1...';
    final canContinue = _pubKeyCopied && _privKeyCopied;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final topGap = h < 680 ? 8.0 : 16.0;
            final midGap = h < 680 ? 8.0 : 12.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OnboardingAppBar(onBack: () => Navigator.pop(context)),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: topGap),

                        // ── Heading ──────────────────────────────────────
                        const Text(
                          'Your Identity Keys',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'One is for sharing. One is for your eyes only.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),

                        SizedBox(height: midGap + 4),

                        // ── Public Key card ──────────────────────────────
                        _KeyCard(
                          title: 'Public Key',
                          subtitle: 'Share with others to receive messages.',
                          keyValue: npub,
                          icon: Icons.share_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primary.withValues(alpha: 0.08),
                          isSecret: false,
                          isVisible: true,
                          onToggle: null,
                          isCopied: _pubKeyCopied,
                          onCopy: () => _copyPub(npub),
                        ),

                        SizedBox(height: midGap),

                        // ── Private Key card (revealed after pub copied) ─
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _pubKeyCopied
                              ? _KeyCard(
                                  key: const ValueKey('priv'),
                                  title: 'Private Key',
                                  subtitle:
                                      'Never share this. Total access to your identity.',
                                  keyValue: nsec,
                                  icon: Icons.lock_rounded,
                                  iconColor: AppColors.error,
                                  iconBg: AppColors.error.withValues(alpha: 0.08),
                                  isSecret: true,
                                  isVisible: _nsecVisible,
                                  onToggle: () => setState(
                                      () => _nsecVisible = !_nsecVisible),
                                  isCopied: _privKeyCopied,
                                  onCopy: () => _copyPriv(nsec),
                                  warning:
                                      'Lose this key = lose your account forever.',
                                )
                              : _PrivKeyHint(key: const ValueKey('hint')),
                        ),

                        const Spacer(),

                        // ── Save & Continue ──────────────────────────────
                        GestureDetector(
                          onTap: canContinue
                              ? () => Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.home,
                                    (r) => false,
                                  )
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: canContinue
                                  ? AppColors.gradientPrimary
                                  : null,
                              color: canContinue
                                  ? null
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: canContinue
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.22),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Save & Continue',
                                style: TextStyle(
                                  color: canContinue
                                      ? AppColors.onPrimary
                                      : AppColors.outline,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _downloadBackup(npub, nsec),
                              child: const Text(
                                'Download Backup',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    size: 11, color: AppColors.outline),
                                SizedBox(width: 4),
                                Text(
                                  'E2E ENCRYPTED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Private key placeholder hint ──────────────────────────────────────────────

class _PrivKeyHint extends StatelessWidget {
  const _PrivKeyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.lock_rounded,
                color: AppColors.outlineVariant, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Copy your public key above to reveal your private key.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Key card ──────────────────────────────────────────────────────────────────

class _KeyCard extends StatelessWidget {
  const _KeyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.keyValue,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isSecret,
    required this.isVisible,
    required this.onToggle,
    required this.isCopied,
    required this.onCopy,
    this.warning,
  });

  final String title;
  final String subtitle;
  final String keyValue;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isSecret;
  final bool isVisible;
  final VoidCallback? onToggle;
  final bool isCopied;
  final VoidCallback onCopy;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final display =
        (isSecret && !isVisible) ? '• • • • • • • • • • • •' : keyValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isSecret && !isVisible
                          ? AppColors.onSurfaceVariant
                          : AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onToggle != null)
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      isVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isCopied ? null : onCopy,
                  child: isCopied
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 14,
                                color: AppColors.primary.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              'Copied',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COPY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(warning!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onErrorContainer,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingAppBar extends StatelessWidget {
  const _OnboardingAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary),
            onPressed: onBack,
          ),
          const Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage('assets/images/uniun-logo.png'),
                    height: 24,
                    width: 24,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'UNIUN',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
