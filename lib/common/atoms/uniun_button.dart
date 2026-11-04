import 'package:flutter/material.dart';

/// Which of the app's button looks to draw. Each one reproduces a look the app
/// already had, so moving a screen onto [UniunButton] does not change it.
enum UniunButtonVariant {
  /// Flat primary, 48 px, radius 12: forms and sheets.
  primary,

  /// Gradient primary, 58 px, radius 16: onboarding.
  hero,

  /// White card with a hairline border, 58 px, radius 16: onboarding.
  secondary,

  /// Quiet filled button, radius 12: settings.
  tonal,

  /// [tonal] in the error colours: destructive settings actions.
  destructive,
}

/// The one button. `onPressed: null` or `loading: true` disables it.
class UniunButton extends StatelessWidget {
  const UniunButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = UniunButtonVariant.primary,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final UniunButtonVariant variant;

  /// Shown before the label.
  final Widget? icon;

  /// Shown after the label (e.g. an arrow).
  final Widget? trailing;

  /// Swaps the label for a spinner and ignores taps.
  final bool loading;

  /// Fill the available width; otherwise wrap the content.
  final bool expand;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final look = _Look.of(variant, scheme, enabled: _enabled);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: loading
          ? [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: look.foreground,
                ),
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
            child: Padding(
              padding: look.padding,
              child: Center(
                widthFactor: expand ? null : 1,
                heightFactor: look.height == null ? 1 : null,
                child: content,
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
  });

  final Color foreground;
  final TextStyle textStyle;
  final BoxDecoration decoration;
  final BorderRadius radius;
  final double? height;
  final EdgeInsets padding;

  factory _Look.of(
    UniunButtonVariant variant,
    ColorScheme scheme, {
    required bool enabled,
  }) {
    switch (variant) {
      case UniunButtonVariant.primary:
        final fg = scheme.onPrimary;
        return _Look(
          foreground: fg,
          height: 48,
          radius: BorderRadius.circular(12),
          textStyle: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: enabled ? scheme.primary : scheme.outlineVariant,
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
        );
      case UniunButtonVariant.tonal:
        return _quiet(scheme.surfaceContainerLow, scheme.onSurface);
      case UniunButtonVariant.destructive:
        return _quiet(scheme.errorContainer, scheme.onErrorContainer);
    }
  }

  static _Look _quiet(Color background, Color foreground) => _Look(
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
  );
}
