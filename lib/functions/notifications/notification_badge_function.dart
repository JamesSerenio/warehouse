import '../../models/dashboard_summary.dart';
import '../settings/notification_settings_function.dart';

abstract final class NotificationBadgeFunction {
  static int calculate({
    required NotificationSettings settings,
    required List<DashboardLowStockItem> lowStockItems,
    required List<DashboardDueTodayItem> dueTodayItems,
  }) {
    final lowStockCount = settings.lowStockAlerts ? lowStockItems.length : 0;
    final dueTodayCount = settings.dueTodayReminders ? dueTodayItems.length : 0;
    return lowStockCount + dueTodayCount;
  }
}
