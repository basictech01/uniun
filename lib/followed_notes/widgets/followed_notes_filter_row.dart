import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

enum FollowedNotesFilter { all, updated, unread }

class FollowedNotesFilterRow extends StatelessWidget {
  const FollowedNotesFilterRow({
    super.key,
    required this.active,
    required this.onChanged,
  });
  final FollowedNotesFilter active;
  final ValueChanged<FollowedNotesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: active == FollowedNotesFilter.all,
            onTap: () => onChanged(FollowedNotesFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Updated',
            selected: active == FollowedNotesFilter.updated,
            onTap: () => onChanged(FollowedNotesFilter.updated),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Unread',
            selected: active == FollowedNotesFilter.unread,
            onTap: () => onChanged(FollowedNotesFilter.unread),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.onPrimary
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
