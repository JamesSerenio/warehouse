import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardNotificationPreferences {
  const DashboardNotificationPreferences({
    required this.lowStockAlerts,
    required this.dueTodayReminders,
  });

  final bool lowStockAlerts;
  final bool dueTodayReminders;

  DashboardNotificationPreferences copyWith({
    bool? lowStockAlerts,
    bool? dueTodayReminders,
  }) => DashboardNotificationPreferences(
    lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
    dueTodayReminders: dueTodayReminders ?? this.dueTodayReminders,
  );
}

abstract final class DashboardNotificationFunction {
  static const _lowStockKey = 'dashboard_low_stock_alerts';
  static const _dueTodayKey = 'dashboard_due_today_reminders';

  static final preferences = ValueNotifier(
    const DashboardNotificationPreferences(
      lowStockAlerts: true,
      dueTodayReminders: true,
    ),
  );

  static Future<DashboardNotificationPreferences> load() async {
    final storage = await SharedPreferences.getInstance();
    final value = DashboardNotificationPreferences(
      lowStockAlerts: storage.getBool(_lowStockKey) ?? true,
      dueTodayReminders: storage.getBool(_dueTodayKey) ?? true,
    );
    preferences.value = value;
    return value;
  }

  static Future<void> setLowStockAlerts(bool enabled) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_lowStockKey, enabled);
    preferences.value = preferences.value.copyWith(lowStockAlerts: enabled);
  }

  static Future<void> setDueTodayReminders(bool enabled) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_dueTodayKey, enabled);
    preferences.value = preferences.value.copyWith(dueTodayReminders: enabled);
  }
}
