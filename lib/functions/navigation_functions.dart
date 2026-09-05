import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/placeholder_screen.dart';

abstract final class NavigationFunctions {
  static void goToDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  static void goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static void goToInventory(BuildContext context) =>
      _goToPlaceholder(context, 'Inventory');

  static void goToAddItem(BuildContext context) =>
      _goToPlaceholder(context, 'Add Item');

  static void goToAddStock(BuildContext context) =>
      _goToPlaceholder(context, 'Add Stock');

  static void goToNewTransaction(BuildContext context) =>
      _goToPlaceholder(context, 'New Transaction');

  static void goToReturnItems(BuildContext context) =>
      _goToPlaceholder(context, 'Return Items');

  static void goToEnterCode(BuildContext context) =>
      _goToPlaceholder(context, 'Enter Transaction Code');

  static void goToStockHistory(BuildContext context) =>
      _goToPlaceholder(context, 'Stock History');

  static void goToReports(BuildContext context) =>
      _goToPlaceholder(context, 'Reports');

  static void goToSettings(BuildContext context) =>
      _goToPlaceholder(context, 'Settings');

  static void goToPage(BuildContext context, String page) {
    switch (page) {
      case 'Dashboard':
        goToDashboard(context);
      case 'New Transaction':
        goToNewTransaction(context);
      case 'Return Items':
        goToReturnItems(context);
      case 'Enter Code':
      case 'Enter Transaction Code':
        goToEnterCode(context);
      case 'Inventory':
        goToInventory(context);
      case 'Add Item':
        goToAddItem(context);
      case 'Add Stock':
        goToAddStock(context);
      case 'Stock History':
        goToStockHistory(context);
      case 'Reports':
        goToReports(context);
      case 'Settings':
        goToSettings(context);
      default:
        _goToPlaceholder(context, page);
    }
  }

  static void _goToPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlaceholderScreen(title: title)),
    );
  }
}
