import 'package:flutter/material.dart';

import 'animation_constants.dart';

Future<T?> showAnimatedWarehouseModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 500,
  bool barrierDismissible = true,
}) {
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Close modal',
    barrierColor: const Color(0xA608213B),
    transitionDuration: reduceMotion
        ? const Duration(milliseconds: 1)
        : AppAnimationDurations.modal,
    pageBuilder: (context, animation, secondaryAnimation) {
      final size = MediaQuery.sizeOf(context);
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth.clamp(0, size.width * .94).toDouble(),
              maxHeight: size.height * .90,
            ),
            child: Material(
              color: Colors.transparent,
              child: Builder(builder: builder),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppAnimationCurves.modal,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
