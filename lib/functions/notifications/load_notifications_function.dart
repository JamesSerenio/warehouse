import '../../models/dashboard_summary.dart';
import 'due_today_notification_function.dart';
import 'low_stock_notification_function.dart';

class WarehouseNotifications {
  const WarehouseNotifications({
    required this.lowStockItems,
    required this.dueTodayItems,
  });

  final List<DashboardLowStockItem> lowStockItems;
  final List<DashboardDueTodayItem> dueTodayItems;
}

abstract final class LoadNotificationsFunction {
  static Future<WarehouseNotifications> load() async {
    final results = await Future.wait<Object>([
      LowStockNotificationFunction.load(),
      DueTodayNotificationFunction.load(),
    ]);
    return WarehouseNotifications(
      lowStockItems: results[0] as List<DashboardLowStockItem>,
      dueTodayItems: results[1] as List<DashboardDueTodayItem>,
    );
  }
}
