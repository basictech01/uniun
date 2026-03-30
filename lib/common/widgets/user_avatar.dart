import 'dart:io';

import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Shared profile avatar used across the app (drawer header, top bar, DM rows,
/// settings card, etc.).
///
/// - If [photoUrl] is provided and loads successfully → shows network image.
/// - Otherwise → shows a deterministic illustration from [seed] via avatar_plus.
///
/// [seed] should be the user's pubkeyHex, npub, or any stable identifier.
/// [shape] controls circular vs rounded-rect clipping.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.seed,
    this.photoUrl,
    this.size = 40,
    this.borderRadius,
    this.showBorder = false,
  });

  /// Stable string used to generate the deterministic avatar illustration.
  final String seed;

  /// If non-null, shows this image instead of the generated avatar.
  final String? photoUrl;

  /// Width and height of the avatar.
  final double size;

  /// Corner radius. Defaults to circular (size / 2) when null.
  final double? borderRadius;

  /// Whether to show a subtle border ring.
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size / 2;
    final effectiveSeed = seed.isEmpty ? 'uniun' : seed;

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
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? _photoWidget(photoUrl!, effectiveSeed)
          : _generated(effectiveSeed),
    );
  }

  Widget _photoWidget(String url, String fallbackSeed) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _generated(fallbackSeed),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => _generated(fallbackSeed),
    );
  }

  Widget _generated(String s) => AvatarPlus(
        s,
        width: size,
        height: size,
        trBackground: false,
      );
}
