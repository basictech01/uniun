import 'package:avatar_plus/avatar_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:uniun/core/constants/app_constants.dart';
import 'package:uniun/core/theme/app_theme.dart';

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
    final effectiveSeed = seed.isEmpty ? AppConstants.kAppName : seed;
    final isNetwork = photoUrl != null &&
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
      child: isNetwork
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              placeholder: (_, __) => _generated(effectiveSeed),
              errorWidget: (_, __, ___) => _generated(effectiveSeed),
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
