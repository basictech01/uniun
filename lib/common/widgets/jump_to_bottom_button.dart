import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// Distance (in pixels) from the bottom edge within which a chat list counts as
/// "at the bottom". Past this, the [JumpToBottomButton] shows; within it, the
/// button hides. The small tolerance absorbs overscroll / rounding so the
/// button doesn't flicker right at the edge.
const double kJumpToBottomTolerance = 80;

/// A floating circular "scroll to latest" affordance used by the chat-like
/// surfaces (group feed, private group, DM). Purely presentational — the
/// parent owns the scroll state and decides [visible]; tapping calls
/// [onPressed] (which both scrolls to the newest message and marks the surface
/// read).
///
/// When hidden it scales + fades out and stops absorbing taps, so it never
/// blocks the message list underneath it.
class JumpToBottomButton extends StatelessWidget {
  const JumpToBottomButton({
    super.key,
    required this.visible,
    required this.onPressed,
    this.tooltip,
    this.unreadCount = 0,
  });

  /// Whether the button is shown. Driven by the parent's scroll position.
  final bool visible;

  /// Invoked on tap — scroll to the latest message and mark the surface read.
  final VoidCallback onPressed;

  /// Tooltip / semantics label (from l10n).
  final String? tooltip;

  /// Unread notes below the viewport; shown as a badge when above zero.
  final int unreadCount;

  static const Duration _anim = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: _anim,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: visible ? 1 : 0.6,
          duration: _anim,
          curve: Curves.easeOut,
          child: _button(context),
        ),
      ),
    );
  }

  Widget _button(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(color: context.custom.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 26,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );

    final tooltip = this.tooltip;
    final badged = Badge(
      isLabelVisible: unreadCount > 0,
      backgroundColor: colorScheme.primary,
      textColor: colorScheme.onPrimary,
      label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
      child: button,
    );
    return Semantics(
      button: true,
      label: tooltip,
      child: tooltip == null
          ? badged
          : Tooltip(message: tooltip, child: badged),
    );
  }
}
