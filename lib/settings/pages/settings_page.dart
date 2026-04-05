import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/settings/cubit/settings_cubit.dart';
import 'package:uniun/settings/widgets/ai_card.dart';
import 'package:uniun/settings/widgets/alerts_card.dart';
import 'package:uniun/settings/widgets/identity_card.dart';
import 'package:uniun/settings/widgets/profile_card.dart';
import 'package:uniun/settings/widgets/section_label.dart';
import 'package:uniun/settings/widgets/settings_app_bar.dart';
import 'package:uniun/settings/widgets/storage_card.dart';
import 'package:uniun/settings/widgets/style_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>(),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SettingsAppBar(title: AppLocalizations.of(context)!.settingsTitle),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final l10n = AppLocalizations.of(context)!;
          return ListView(
            padding: const EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: 48,
            ),
            children: [
              // ── Account ───────────────────────────────────────────────────
              SettingsSectionLabel(l10n.settingsAccount),
              const SizedBox(height: 12),
              ProfileCard(state: state),

              const SizedBox(height: 16),

              // ── Identity ──────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsIdentity,
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
              IdentityCard(state: state),

              const SizedBox(height: 16),

              // ── AI · Shiv ─────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsAiShiv,
                icon: Icons.smart_toy_outlined,
              ),
              const SizedBox(height: 12),
              const AICard(),

              const SizedBox(height: 16),

              // ── Storage ───────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsStorage,
                icon: Icons.storage_rounded,
              ),
              const SizedBox(height: 12),
              const StorageCard(),

              const SizedBox(height: 16),

              // ── Alerts + Style ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSectionLabel(
                          l10n.settingsAlerts,
                          icon: Icons.notifications_outlined,
                        ),
                        const SizedBox(height: 12),
                        AlertsCard(state: state),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSectionLabel(
                          l10n.settingsStyle,
                          icon: Icons.palette_outlined,
                        ),
                        const SizedBox(height: 12),
                        const StyleCard(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Version ───────────────────────────────────────────────────
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
