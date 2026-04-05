import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';

class ThreadSegmentedToggle extends StatelessWidget {
  const ThreadSegmentedToggle({super.key, required this.activeTab});
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Row(
            children: [
              _ToggleTab(label: l10n.threadReplies, index: 0, activeTab: activeTab),
              _ToggleTab(label: l10n.threadReferences, index: 1, activeTab: activeTab),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.index,
    required this.activeTab,
  });

  final String label;
  final int index;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    final active = index == activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            context.read<ThreadBloc>().add(SwitchTabEvent(index)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
