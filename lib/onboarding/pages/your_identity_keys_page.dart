import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/onboarding/widgets/key_card.dart';
import 'package:uniun/onboarding/widgets/onboarding_app_bar.dart';

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

  Future<void> _saveAndContinue(String nsec) async {
    final result = await getIt<UserRepository>().importKey(nsec);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save keys: \${failure.toString()}')),
      ),
      (_) => Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (r) => false,
      ),
    );
  }

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
                OnboardingAppBar(onBack: () => Navigator.pop(context)),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: topGap),

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

                        KeyCard(
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

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _pubKeyCopied
                              ? KeyCard(
                                  key: const ValueKey('priv'),
                                  title: 'Private Key',
                                  subtitle:
                                      'Never share this. Total access to your identity.',
                                  keyValue: nsec,
                                  icon: Icons.lock_rounded,
                                  iconColor: AppColors.error,
                                  iconBg:
                                      AppColors.error.withValues(alpha: 0.08),
                                  isSecret: true,
                                  isVisible: _nsecVisible,
                                  onToggle: () => setState(
                                      () => _nsecVisible = !_nsecVisible),
                                  isCopied: _privKeyCopied,
                                  onCopy: () => _copyPriv(nsec),
                                  warning:
                                      'Lose this key = lose your account forever.',
                                )
                              : const PrivKeyHint(key: ValueKey('hint')),
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap:
                              canContinue ? () => _saveAndContinue(nsec) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: canContinue
                                  ? AppColors.primary
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
