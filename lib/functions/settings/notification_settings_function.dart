import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.lowStockAlerts,
    required this.dueTodayReminders,
  });

  final bool lowStockAlerts;
  final bool dueTodayReminders;

  NotificationSettings copyWith({
    bool? lowStockAlerts,
    bool? dueTodayReminders,
  }) => NotificationSettings(
    lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
    dueTodayReminders: dueTodayReminders ?? this.dueTodayReminders,
  );
}

abstract final class NotificationSettingsFunction {
  static const lowStockKey = 'low_stock_alerts_enabled';
  static const dueTodayKey = 'due_today_reminders_enabled';
  static const _legacyLowStockKey = 'dashboard_low_stock_alerts';
  static const _legacyDueTodayKey = 'dashboard_due_today_reminders';

  static final preferences = ValueNotifier(
    const NotificationSettings(lowStockAlerts: true, dueTodayReminders: true),
  );

  static Future<NotificationSettings> load() async {
    final storage = await SharedPreferences.getInstance();
    final lowStock =
        storage.getBool(lowStockKey) ??
        storage.getBool(_legacyLowStockKey) ??
        true;
    final dueToday =
        storage.getBool(dueTodayKey) ??
        storage.getBool(_legacyDueTodayKey) ??
        true;
    final value = NotificationSettings(
      lowStockAlerts: lowStock,
      dueTodayReminders: dueToday,
    );
    preferences.value = value;
    await Future.wait([
      storage.setBool(lowStockKey, lowStock),
      storage.setBool(dueTodayKey, dueToday),
    ]);
    return value;
  }

  static Future<void> setLowStockAlerts(bool enabled) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(lowStockKey, enabled);
    preferences.value = preferences.value.copyWith(lowStockAlerts: enabled);
  }

  static Future<void> setDueTodayReminders(bool enabled) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(dueTodayKey, enabled);
    preferences.value = preferences.value.copyWith(dueTodayReminders: enabled);
  }
}
