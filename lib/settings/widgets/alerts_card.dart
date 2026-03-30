import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/settings/cubit/settings_cubit.dart';
import 'package:uniun/settings/widgets/settings_buttons.dart';

class AlertsCard extends StatelessWidget {
  const AlertsCard({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DM Alerts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              SettingsToggle(
                value: state.dmNotifications,
                onChanged: cubit.toggleDmNotifications,
              ),
            ],
          ),
          Divider(
            height: 20,
            color: AppColors.surfaceContainer.withValues(alpha: 0.5),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Channel Alerts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              SettingsToggle(
                value: state.channelAlerts,
                onChanged: cubit.toggleChannelAlerts,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
