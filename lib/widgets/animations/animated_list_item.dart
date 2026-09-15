import 'package:flutter/material.dart';

import 'animated_fade_slide.dart';

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedFadeSlide(
    delay: Duration(milliseconds: 30 * index.clamp(0, 9)),
    offset: const Offset(0, .025),
    child: child,
  );
}
