import 'package:flutter/material.dart';

import '../animations/animated_modal.dart';

Future<T?> showWarehouseModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 500,
  bool barrierDismissible = true,
}) {
  return showAnimatedWarehouseModal<T>(
    context: context,
    builder: builder,
    maxWidth: maxWidth,
    barrierDismissible: barrierDismissible,
  );
}
