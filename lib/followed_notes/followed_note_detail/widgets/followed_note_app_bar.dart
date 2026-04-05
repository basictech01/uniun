import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

class FollowedNoteAppBar extends StatelessWidget {
  const FollowedNoteAppBar({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.onSurface,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'UNIUN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
