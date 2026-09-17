import 'package:flutter/material.dart';

/// A focused pan + pinch-zoom canvas that does NOT trip Flutter's
/// `InteractiveViewer` assertion:
///
///   'package:flutter/.../interactive_viewer.dart': Failed assertion:
///   'scale != 0.0': is not true.
///
/// During a pinch, when the two pointers' span collapses to zero (e.g. the
/// iOS-simulator Option-pinch sweeps both synthetic touches through the
/// centre), `ScaleUpdateDetails.scale` reports `0.0`. The framework feeds that
/// straight into its matrix maths and asserts. There is no public hook to
/// filter the gesture scale before `InteractiveViewer`'s own recogniser sees
/// it, so we own the gesture handling here and guard the one missing case.
///
/// Scope: pan + focal-point zoom + scale clamp — the full set the graph canvases
/// need. No fling inertia, rotation, or boundary clamping (panning is free).
/// Because the scale is always clamped to `>= minScale (> 0)`, the transform is
/// never singular, so `Matrix4.inverted` (used to keep the focal point fixed)
/// can never blow up either — a second guard against the same class of bug.
class SafeInteractiveViewer extends StatefulWidget {
  const SafeInteractiveViewer({
    super.key,
    required this.child,
    this.minScale = 0.3,
    this.maxScale = 4.0,
    this.constrained = true,
    this.controller,
    this.onInteractionStart,
    this.onInteractionEnd,
  }) : assert(minScale > 0 && minScale <= maxScale);

  final Widget child;
  final double minScale;
  final double maxScale;

  /// When false the child is laid out at its intrinsic size (can exceed the
  /// viewport) and the excess is clipped — mirrors `InteractiveViewer`'s
  /// `constrained: false`.
  final bool constrained;

  /// Drives the camera from outside (animate to a point, restore a saved
  /// view). When null the viewer owns a private controller and the camera can
  /// only be moved by gesture. A supplied controller is NOT disposed here —
  /// the owner created it and keeps it.
  final TransformationController? controller;

  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  /// The scale factor to apply to the current transform for one gesture update,
  /// or `1.0` (no-op) when the gesture is degenerate.
  ///
  /// This is the root-cause guard: a `0.0` / non-finite [gestureScale] (the
  /// span-collapse case) — or any maths that would yield a `0`/non-finite
  /// change — resolves to `1.0` instead of corrupting the transform.
  @visibleForTesting
  static double computeScaleChange({
    required double currentScale,
    required double scaleStart,
    required double gestureScale,
    required double minScale,
    required double maxScale,
  }) {
    if (gestureScale == 0.0 || !gestureScale.isFinite) return 1.0;
    if (currentScale == 0.0 || !currentScale.isFinite) return 1.0;
    final double desired =
        (scaleStart * gestureScale).clamp(minScale, maxScale);
    final double change = desired / currentScale;
    if (change == 0.0 || !change.isFinite) return 1.0;
    return change;
  }

  @override
  State<SafeInteractiveViewer> createState() => _SafeInteractiveViewerState();
}

class _SafeInteractiveViewerState extends State<SafeInteractiveViewer> {
  late final TransformationController _controller =
      widget.controller ?? TransformationController();

  // Matrix scale at the start of the active gesture.
  double _scaleStart = 1.0;
  // Scene-space point under the gesture focal point; kept fixed while zooming.
  Offset _referenceFocalScene = Offset.zero;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Offset _toScene(Offset viewportPoint) {
    return MatrixUtils.transformPoint(
      Matrix4.inverted(_controller.value),
      viewportPoint,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStart = _controller.value.getMaxScaleOnAxis();
    _referenceFocalScene = _toScene(details.localFocalPoint);
    widget.onInteractionStart?.call();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double currentScale = _controller.value.getMaxScaleOnAxis();
    final double scaleChange = SafeInteractiveViewer.computeScaleChange(
      currentScale: currentScale,
      scaleStart: _scaleStart,
      gestureScale: details.scale,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
    );

    // Commit the scale before reading the focal scene point below (which
    // inverts `_controller.value`). On a pure pan (scaleChange == 1.0) skip the
    // write entirely so the translation block is the single matrix update.
    if (scaleChange != 1.0) {
      _controller.value = _controller.value.clone()
        ..scaleByDouble(scaleChange, scaleChange, scaleChange, 1);
    }

    // Translate so the scene point under the focal point stays put — gives
    // focal-point zoom and also handles one-finger pan (scaleChange == 1.0).
    final Offset focalSceneNow = _toScene(details.localFocalPoint);
    final Offset translation = focalSceneNow - _referenceFocalScene;
    _controller.value = _controller.value.clone()
      ..translateByDouble(translation.dx, translation.dy, 0, 1);
    _referenceFocalScene = _toScene(details.localFocalPoint);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.onInteractionEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = widget.constrained
        ? widget.child
        : OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.topLeft,
            child: widget.child,
          );

    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: ValueListenableBuilder<Matrix4>(
          valueListenable: _controller,
          child: content,
          builder: (context, matrix, child) => Transform(
            transform: matrix,
            child: child,
          ),
        ),
      ),
    );
  }
}
