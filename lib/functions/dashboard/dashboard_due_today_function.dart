import '../../models/dashboard_summary.dart';

abstract final class DashboardDueTodayFunction {
  static Future<List<DashboardDueTodayItem>> load() async {
    // Connect this function when transaction/due-date tables are added.
    return const [];
  }
}
