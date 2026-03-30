import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      create: (_) => SettingsCubit(),
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
      extendBodyBehindAppBar: true,
      appBar: const SettingsAppBar(title: 'Settings'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final topPad = MediaQuery.of(context).padding.top + 64;
          return ListView(
            padding: EdgeInsets.only(
              top: topPad,
              left: 20,
              right: 20,
              bottom: 48,
            ),
            children: [
              // ── Account ───────────────────────────────────────────────────
              const SettingsSectionLabel('Account'),
              const SizedBox(height: 12),
              ProfileCard(state: state),

              const SizedBox(height: 16),

              // ── Identity ──────────────────────────────────────────────────
              const SettingsSectionLabel(
                'Identity',
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
              IdentityCard(state: state),

              const SizedBox(height: 16),

              // ── AI · Shiv ─────────────────────────────────────────────────
              const SettingsSectionLabel(
                'AI · Shiv',
                icon: Icons.smart_toy_outlined,
              ),
              const SizedBox(height: 12),
              AICard(state: state),

              const SizedBox(height: 16),

              // ── Storage ───────────────────────────────────────────────────
              const SettingsSectionLabel(
                'Storage',
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
                        const SettingsSectionLabel(
                          'Alerts',
                          icon: Icons.notifications_outlined,
                        ),
                        const SizedBox(height: 12),
                        AlertsCard(state: state),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSectionLabel(
                          'Style',
                          icon: Icons.palette_outlined,
                        ),
                        SizedBox(height: 12),
                        StyleCard(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Version ───────────────────────────────────────────────────
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
