import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_theme.dart';

class ThreadAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ThreadAppBar({super.key});

  @override
  Size get preferredSize {
    // Include status-bar height so the Scaffold body starts below both
    // the status bar and the toolbar — prevents content overlapping the notch.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final statusBarHeight = view.padding.top / view.devicePixelRatio;
    return Size.fromHeight(kToolbarHeight + statusBarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.80),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.threadTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.onSurfaceVariant),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.onSurfaceVariant),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
