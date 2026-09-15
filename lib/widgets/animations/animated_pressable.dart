import 'package:flutter/material.dart';

import 'animation_constants.dart';

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.015,
    this.pressedScale = .98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressedScale;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scale = _pressed
        ? widget.pressedScale
        : _hovered
        ? widget.hoverScale
        : 1.0;
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: widget.onTap == null
          ? null
          : (_) => setState(() => _hovered = true),
      onExit: widget.onTap == null
          ? null
          : (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: reduceMotion ? 1 : scale,
          duration: reduceMotion
              ? const Duration(milliseconds: 1)
              : AppAnimationDurations.press,
          curve: AppAnimationCurves.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
