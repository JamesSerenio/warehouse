import '../../models/dashboard_summary.dart';
import '../dashboard/dashboard_low_stock_function.dart';

abstract final class LowStockNotificationFunction {
  static Future<List<DashboardLowStockItem>> load() =>
      DashboardLowStockFunction.load();
}
