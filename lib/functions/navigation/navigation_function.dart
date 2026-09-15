import 'package:flutter/material.dart';

import '../../screens/login_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/placeholder_screen.dart';
import '../../widgets/modals/add_item_modal.dart';
import '../../widgets/modals/enter_code_modal.dart';
import '../../widgets/modals/new_transaction_modal.dart';
import '../../widgets/modals/return_items_list_modal.dart';
import '../../widgets/modals/stock_history_modal.dart';

abstract final class NavigationFunction {
  static void goToDashboard(BuildContext context) => _openMainShell(context, 0);
  static void goToLogin(BuildContext context) =>
      _replaceAll(context, const LoginScreen());
  static void goToItems(BuildContext context) => _openMainShell(context, 2);
  static void goToBorrowed(BuildContext context) => _openMainShell(context, 1);
  static void goToAddItem(BuildContext context) => showAddItemModal(context);
  static void goToNewTransaction(BuildContext context) =>
      showNewTransactionModal(context);
  static void goToReturnItems(BuildContext context) =>
      showReturnItemsListModal(context);
  static void goToEnterCode(BuildContext context) =>
      showEnterCodeModal(context);
  static void goToStockHistory(BuildContext context) =>
      showStockHistoryModal(context);
  static void goToReports(BuildContext context) => _openMainShell(context, 3);
  static void goToMore(BuildContext context) => _openMainShell(context, 4);

  static void goToPage(BuildContext context, String page) {
    switch (page) {
      case 'Dashboard':
        goToDashboard(context);
      case 'Borrowed':
        goToBorrowed(context);
      case 'New Transaction':
        goToNewTransaction(context);
      case 'Return Items':
        goToReturnItems(context);
      case 'Enter Code':
      case 'Enter Transaction Code':
        goToEnterCode(context);
      case 'Items':
        goToItems(context);
      case 'Add Item':
        goToAddItem(context);
      case 'Stock History':
        goToStockHistory(context);
      case 'Reports':
        goToReports(context);
      case 'More':
        goToMore(context);
      default:
        _push(context, PlaceholderScreen(title: page));
    }
  }

  static void _openMainShell(BuildContext context, int index) =>
      _replaceAll(context, MainShell(initialIndex: index));

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
