import 'package:flutter/material.dart';

import '../../screens/add_stock_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/enter_code_screen.dart';
import '../../screens/inventory_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/new_transaction_screen.dart';
import '../../screens/placeholder_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/return_items_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/stock_history_screen.dart';
import '../../widgets/modals/add_item_modal.dart';

abstract final class NavigationFunction {
  static void goToDashboard(BuildContext context) =>
      _replaceAll(context, const DashboardScreen());
  static void goToLogin(BuildContext context) =>
      _replaceAll(context, const LoginScreen());
  static void goToInventory(BuildContext context) =>
      _push(context, const InventoryScreen());
  static void goToAddItem(BuildContext context) => showAddItemModal(context);
  static void goToAddStock(BuildContext context) =>
      _push(context, const AddStockScreen());
  static void goToNewTransaction(BuildContext context) =>
      _push(context, const NewTransactionScreen());
  static void goToReturnItems(BuildContext context) =>
      _push(context, const ReturnItemsScreen());
  static void goToEnterCode(BuildContext context) =>
      _push(context, const EnterCodeScreen());
  static void goToStockHistory(BuildContext context) =>
      _push(context, const StockHistoryScreen());
  static void goToReports(BuildContext context) =>
      _push(context, const ReportsScreen());
  static void goToSettings(BuildContext context) =>
      _push(context, const SettingsScreen());

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
        _push(context, PlaceholderScreen(title: page));
    }
  }

  static void _replaceAll(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (_) => false,
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
