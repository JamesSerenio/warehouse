import 'package:flutter/material.dart';

import 'animation_constants.dart';

class AnimatedFadeSlide extends StatelessWidget {
  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppAnimationDurations.normal,
    this.offset = const Offset(0, .03),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = reduceMotion
        ? const Duration(milliseconds: 1)
        : duration + delay;
    final delayFraction = effectiveDuration.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / effectiveDuration.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: effectiveDuration,
      curve: Curves.linear,
      child: child,
      builder: (context, progress, child) {
        final value = reduceMotion
            ? 1.0
            : ((progress - delayFraction) / (1 - delayFraction)).clamp(
                0.0,
                1.0,
              );
        final curved = AppAnimationCurves.standard.transform(value);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - curved), offset.dy * (1 - curved)),
            child: child,
          ),
        );
      },
    );
  }
}
