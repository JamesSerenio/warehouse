import 'package:flutter/foundation.dart';

import '../settings/notification_settings_function.dart';

export '../settings/notification_settings_function.dart'
    show NotificationSettings;

typedef DashboardNotificationPreferences = NotificationSettings;

abstract final class DashboardNotificationFunction {
  static ValueNotifier<NotificationSettings> get preferences =>
      NotificationSettingsFunction.preferences;

  static Future<NotificationSettings> load() =>
      NotificationSettingsFunction.load();

  static Future<void> setLowStockAlerts(bool enabled) =>
      NotificationSettingsFunction.setLowStockAlerts(enabled);

  static Future<void> setDueTodayReminders(bool enabled) =>
      NotificationSettingsFunction.setDueTodayReminders(enabled);
}
