import 'package:flutter/material.dart';

abstract final class DrawerFunction {
  static void close(BuildContext context) => Navigator.of(context).pop();

  static bool isSelected({
    required String currentPage,
    required String itemPage,
  }) => currentPage == itemPage;

  static void handleSelection({
    required BuildContext context,
    required String currentPage,
    required String selectedPage,
    required ValueChanged<String> onNavigate,
  }) {
    close(context);
    if (!isSelected(currentPage: currentPage, itemPage: selectedPage)) {
      onNavigate(selectedPage);
    }
  }
}
