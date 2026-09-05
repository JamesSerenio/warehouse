import 'package:flutter/material.dart';

Future<T?> showWarehouseModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 500,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Close modal',
    barrierColor: const Color(0xA608213B),
    transitionDuration: const Duration(milliseconds: 260),
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
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .90, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
