import 'package:flutter/material.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';

/// Which of the app's button looks to draw. The first five reproduce looks the
/// app already had; every one can be tuned with the override parameters of
/// [UniunButton].
enum UniunButtonVariant {
  /// Flat primary, radius 12: forms and sheets.
  primary,

  /// Gradient primary, 58 px, radius 16: onboarding.
  hero,

  /// White card with a hairline border, 58 px, radius 16: onboarding.
  secondary,

  /// Quiet filled button, radius 12: settings.
  tonal,

  /// [tonal] in the error colours: destructive actions.
  destructive,

  /// Transparent with a primary outline, radius 12.
  outlined,

  /// Primary text on an 8 % primary tint, radius 12.
  soft,
}

/// How tall a [UniunButtonVariant.primary] / [UniunButtonVariant.outlined] /
/// [UniunButtonVariant.soft] button is. The onboarding variants have their own
/// fixed height, and [UniunButtonVariant.tonal] / [UniunButtonVariant.destructive]
/// size to their text.
enum UniunButtonSize {
  /// 36 px, 14 px semi-bold label: toolbars, list rows.
  compact,

  /// 48 px, 15 px semi-bold label: sheets and dialogs.
  regular,

  /// 52 px, 16 px bold label: page-level submits.
  large,
}

/// The one button. `onPressed: null` or `loading: true` disables it.
class UniunButton extends StatelessWidget {
  const UniunButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = UniunButtonVariant.primary,
    this.size = UniunButtonSize.regular,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.height,
    this.padding,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final UniunButtonVariant variant;
  final UniunButtonSize size;

  /// Shown before the label.
  final Widget? icon;

  /// Shown after the label (e.g. an arrow).
  final Widget? trailing;

  /// Swaps the label for a spinner and ignores taps.
  final bool loading;

  /// Fill the available width; otherwise wrap the content.
  final bool expand;

  /// Overrides for the variant's colours, corner radius, height, inner padding
  /// and label style. Unset values come from the variant and [size].
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final look =
        _Look.of(
          variant,
          scheme,
          size: size,
          enabled: _enabled,
          loading: loading,
        ).tuned(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          borderColor: borderColor,
          borderRadius: borderRadius,
          height: height,
          padding: padding,
          textStyle: textStyle,
        );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: loading
          ? [
              SizedBox(
                width: 20,
                height: 20,
                child: DropLoadingIndicator(size: 20, color: look.foreground),
              ),
            ]
          : [
              if (icon != null) ...[icon!, const SizedBox(width: 10)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: look.textStyle,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      child: Container(
        height: look.height,
        width: expand ? double.infinity : null,
        decoration: look.decoration,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: look.radius,
            onTap: _enabled ? onPressed : null,
            child: Opacity(
              opacity: look.dimmed ? 0.5 : 1,
              child: Padding(
                padding: look.padding,
                child: Center(
                  widthFactor: expand ? null : 1,
                  heightFactor: look.height == null ? 1 : null,
                  child: IconTheme(
                    data: IconThemeData(color: look.foreground),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Look {
  const _Look({
    required this.foreground,
    required this.textStyle,
    required this.decoration,
    required this.radius,
    this.height,
    this.padding = EdgeInsets.zero,
    this.dimmed = false,
  });

  final Color foreground;
  final TextStyle textStyle;
  final BoxDecoration decoration;
  final BorderRadius radius;
  final double? height;
  final EdgeInsetsGeometry padding;

  /// Disabled (not loading) variants without their own disabled colour.
  final bool dimmed;

  factory _Look.of(
    UniunButtonVariant variant,
    ColorScheme scheme, {
    required UniunButtonSize size,
    required bool enabled,
    required bool loading,
  }) {
    final disabled = !enabled && !loading;
    final sized = switch (size) {
      UniunButtonSize.compact => (
        h: 36.0,
        fontSize: 14.0,
        weight: FontWeight.w600,
      ),
      UniunButtonSize.regular => (
        h: 48.0,
        fontSize: 15.0,
        weight: FontWeight.w600,
      ),
      UniunButtonSize.large => (
        h: 52.0,
        fontSize: 16.0,
        weight: FontWeight.w700,
      ),
    };
    switch (variant) {
      case UniunButtonVariant.primary:
        final fg = scheme.onPrimary;
        return _Look(
          foreground: fg,
          height: sized.h,
          radius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: TextStyle(
            color: fg,
            fontSize: sized.fontSize,
            fontWeight: sized.weight,
          ),
          decoration: BoxDecoration(
            color: enabled
                ? scheme.primary
                : loading
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case UniunButtonVariant.hero:
        final fg = scheme.onPrimary;
        return _Look(
          foreground: fg,
          height: 58,
          radius: BorderRadius.circular(16),
          textStyle: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          dimmed: disabled,
        );
      case UniunButtonVariant.secondary:
        final fg = scheme.onSurface;
        return _Look(
          foreground: fg,
          height: 58,
          radius: BorderRadius.circular(16),
          textStyle: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          dimmed: disabled,
        );
      case UniunButtonVariant.tonal:
        return _quiet(
          scheme.surfaceContainerLow,
          scheme.onSurface,
          dimmed: disabled,
        );
      case UniunButtonVariant.destructive:
        return _quiet(
          scheme.errorContainer,
          scheme.onErrorContainer,
          dimmed: disabled,
        );
      case UniunButtonVariant.outlined:
        return _Look(
          foreground: scheme.primary,
          height: sized.h,
          radius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: TextStyle(
            color: scheme.primary,
            fontSize: sized.fontSize,
            fontWeight: sized.weight,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline),
          ),
          dimmed: disabled,
        );
      case UniunButtonVariant.soft:
        return _Look(
          foreground: scheme.primary,
          height: sized.h,
          radius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: TextStyle(
            color: scheme.primary,
            fontSize: sized.fontSize,
            fontWeight: sized.weight,
          ),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          dimmed: disabled,
        );
    }
  }

  static _Look _quiet(
    Color background,
    Color foreground, {
    required bool dimmed,
  }) => _Look(
    foreground: foreground,
    radius: BorderRadius.circular(12),
    padding: const EdgeInsets.symmetric(vertical: 12),
    textStyle: TextStyle(
      color: foreground,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    dimmed: dimmed,
  );

  /// Applies the caller's overrides on top of the variant's look.
  _Look tuned({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderRadius,
    double? height,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
  }) {
    final fg = foregroundColor ?? foreground;
    final r = borderRadius == null
        ? radius
        : BorderRadius.circular(borderRadius);
    final base = decoration;
    return _Look(
      foreground: fg,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      radius: r,
      dimmed: dimmed,
      textStyle: this.textStyle.copyWith(color: fg).merge(textStyle),
      decoration: BoxDecoration(
        color: backgroundColor ?? base.color,
        gradient: backgroundColor == null ? base.gradient : null,
        borderRadius: r,
        border: borderColor != null
            ? Border.all(color: borderColor)
            : base.border,
        boxShadow: base.boxShadow,
      ),
    );
  }
}
