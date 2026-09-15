import 'package:flutter/material.dart';

import '../../widgets/modals/notifications_modal.dart';
import '../settings/notification_settings_function.dart';
import 'load_notifications_function.dart';

abstract final class OpenNotificationsFunction {
  static Future<void> open(BuildContext context) async {
    final results = await Future.wait<Object>([
      NotificationSettingsFunction.load(),
      LoadNotificationsFunction.load(),
    ]);
    if (!context.mounted) return;
    final settings = results[0] as NotificationSettings;
    final notifications = results[1] as WarehouseNotifications;
    await showNotificationsModal(
      context,
      lowStockItems: notifications.lowStockItems,
      dueTodayItems: notifications.dueTodayItems,
      showLowStock: settings.lowStockAlerts,
      showDueToday: settings.dueTodayReminders,
    );
  }
}
