import 'package:flutter/material.dart';

import 'animation_constants.dart';

class AnimatedTabIcon extends StatelessWidget {
  const AnimatedTabIcon({
    super.key,
    required this.icon,
    this.selected = false,
    this.size = 23,
  });

  final IconData icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: selected ? .9 : 1, end: selected ? 1.08 : 1),
    duration: AppAnimationDurations.fast,
    curve: AppAnimationCurves.standard,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: Icon(icon, size: size),
  );
}
