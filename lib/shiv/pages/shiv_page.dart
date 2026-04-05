import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Shiv AI assistant tab.
/// Model availability is guaranteed by [HomePage] before this tab is shown —
/// it intercepts the tab-2 tap, checks [GetActiveAIModelUseCase], and
/// pushes [AIModelSelectionPage] if no model is downloaded yet.
class ShivPage extends StatelessWidget {
  const ShivPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: replace with ShivChatPage once Phase 2 is implemented
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Icon(
          Icons.psychology_rounded,
          size: 64,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
