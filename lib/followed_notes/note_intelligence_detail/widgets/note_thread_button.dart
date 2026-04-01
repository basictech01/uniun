import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

class NoteThreadButton extends StatelessWidget {
  const NoteThreadButton({
    super.key,
    required this.replyCount,
    required this.onPressed,
  });

  final int replyCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.forum_rounded, size: 18),
        label: Text(
          'View Thread ($replyCount replies)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
