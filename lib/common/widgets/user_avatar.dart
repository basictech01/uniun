import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Shared profile avatar used across the app (drawer header, top bar, DM rows,
/// settings card, etc.).
///
/// - If [photoUrl] is an HTTP/HTTPS URL → shows network image from Blossom server.
/// - Otherwise → shows a deterministic illustration from [seed] via avatar_plus.
///
/// [seed] should be the user's pubkeyHex or npub.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.seed,
    this.photoUrl,
    this.size = 40,
    this.borderRadius,
    this.showBorder = false,
  });

  final String seed;
  final String? photoUrl;
  final double size;
  final double? borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size / 2;
    final effectiveSeed = seed.isEmpty ? 'uniun' : seed;
    final hasPhoto = photoUrl != null &&
        photoUrl!.isNotEmpty &&
        (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://'));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.35),
                width: 1.5,
              )
            : null,
        color: AppColors.surfaceContainerLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => _generated(effectiveSeed),
            )
          : _generated(effectiveSeed),
    );
  }

  Widget _generated(String s) => AvatarPlus(
        s,
        width: size,
        height: size,
        trBackground: false,
      );
}
