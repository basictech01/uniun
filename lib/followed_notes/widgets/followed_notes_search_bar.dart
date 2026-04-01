import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

class FollowedNotesSearchBar extends StatelessWidget {
  const FollowedNotesSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.onSurface,
        ),
        decoration: const InputDecoration(
          hintText: 'Search tracked notes...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.outline,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.outline,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
