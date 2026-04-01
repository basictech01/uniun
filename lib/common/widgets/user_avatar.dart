import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

// Avatar URLs come exclusively from Blossom (HTTP/HTTPS) or are generated
// from the pubkey via avatar_plus. Local file paths are never stored.
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
