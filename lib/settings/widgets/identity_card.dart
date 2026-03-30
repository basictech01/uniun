import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/settings/cubit/settings_cubit.dart';

class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'This is your login & recovery method.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          IdentityRow(
            icon: Icons.key_rounded,
            label: 'View Public Key (npub)',
            trailing: Icons.chevron_right_rounded,
            onTap: () => _showNpub(context),
          ),
          IdentityRow(
            icon: Icons.visibility_off_outlined,
            label: state.nsecVisible
                ? 'Hide Private Key (nsec)'
                : 'Reveal Private Key (nsec)',
            trailing: state.nsecVisible
                ? Icons.visibility_off_rounded
                : Icons.chevron_right_rounded,
            onTap: () => context.read<SettingsCubit>().revealNsec(),
          ),
          if (state.nsecVisible && state.nsec != null)
            NsecRevealBox(nsec: state.nsec!),
          IdentityRow(
            icon: Icons.copy_rounded,
            label: 'Copy Public Key',
            trailing: Icons.file_copy_outlined,
            onTap: () {
              if (state.npub != null) {
                Clipboard.setData(ClipboardData(text: state.npub!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Public key copied')),
                );
              }
            },
          ),
          IdentityRow(
            icon: Icons.backup_rounded,
            label: 'Export Backup',
            trailing: Icons.download_rounded,
            onTap: () {
              // TODO: export backup
            },
          ),
          IdentityRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy & Policy',
            trailing: Icons.chevron_right_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
          ),
        ],
      ),
    );
  }

  void _showNpub(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Public Key (npub)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.npub ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: state.npub ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Public key copied')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class IdentityRow extends StatelessWidget {
  const IdentityRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Icon(trailing, size: 20, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class NsecRevealBox extends StatelessWidget {
  const NsecRevealBox({super.key, required this.nsec});

  final String nsec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_rounded,
                    size: 16, color: Color(0xFFBA1A1A)),
                SizedBox(width: 6),
                Text(
                  'Never share your private key',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              nsec,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: nsec));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Private key copied — keep it safe!'),
                  ),
                );
              },
              child: const Text(
                'Tap to copy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
