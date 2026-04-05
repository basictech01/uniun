import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
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

  Future<void> _saveAndContinue(BuildContext context, Map args, String nsec) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await getIt<ImportKeyUseCase>().call(nsec);
    if (!mounted) return;
    await result.fold(
      (failure) async => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keysFailedToSave(failure.toMessage()))),
      ),
      (user) async {
        // Save profile data collected in AboutYouPage
        final displayName = args['displayName'] as String? ?? '';
        final username = args['username'] as String? ?? '';
        final bio = args['bio'] as String? ?? '';
        if (displayName.isNotEmpty || username.isNotEmpty) {
          await getIt<SaveProfileUseCase>().call(ProfileEntity(
            pubkey: user.pubkeyHex,
            name: displayName.isEmpty ? null : displayName,
            username: username.isEmpty ? null : username,
            about: bio.isEmpty ? null : bio,
            updatedAt: DateTime.now(),
            lastSeenAt: DateTime(3000, 6, 1),
          ));
        }
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (r) => false,
        );
      },
    );
  }

  void _copyPub(String value) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _pubKeyCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.keysPublicCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyPriv(String value) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _privKeyCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.keysPrivateCopied),
        duration: const Duration(seconds: 2),
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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keysBackupSaved(file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keysBackupFailed)),
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
    final l10n = AppLocalizations.of(context)!;

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

                        Text(
                          l10n.keysTitle,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.keysSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),

                        SizedBox(height: midGap + 4),

                        KeyCard(
                          title: l10n.keysPublicKeyTitle,
                          subtitle: l10n.keysPublicKeySubtitle,
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
                                  title: l10n.keysPrivateKeyTitle,
                                  subtitle: l10n.keysPrivateKeySubtitle,
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
                                  warning: l10n.keysPrivateKeyWarning,
                                )
                              : const PrivKeyHint(key: ValueKey('hint')),
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap: canContinue
                              ? () => _saveAndContinue(context, args, nsec)
                              : null,
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
                                l10n.keysSaveAndContinue,
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
                              child: Text(
                                l10n.keysDownloadBackup,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded,
                                    size: 11, color: AppColors.outline),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.keysE2eEncrypted,
                                  style: const TextStyle(
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
