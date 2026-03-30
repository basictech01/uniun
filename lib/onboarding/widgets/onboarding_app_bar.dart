import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Shared top bar used across all onboarding screens.
/// Centers the UNIUN logo + wordmark; back arrow on the left.
class OnboardingAppBar extends StatelessWidget {
  const OnboardingAppBar({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary),
            onPressed: onBack,
          ),
          const Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage('assets/images/uniun-logo.png'),
                    height: 24,
                    width: 24,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'UNIUN',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
