import '../../models/dashboard_summary.dart';
import '../dashboard/dashboard_due_today_function.dart';

abstract final class DueTodayNotificationFunction {
  static Future<List<DashboardDueTodayItem>> load() =>
      DashboardDueTodayFunction.load();
}
