import '../../models/dashboard_summary.dart';
import 'dashboard_borrowed_function.dart';
import 'dashboard_due_today_function.dart';
import 'dashboard_low_stock_function.dart';
import 'dashboard_materials_issued_function.dart';
import 'dashboard_overdue_function.dart';
import 'dashboard_total_items_function.dart';

abstract final class DashboardSummaryFunction {
  static Future<DashboardSummary> load() async {
    final results = await Future.wait<Object>([
      DashboardTotalItemsFunction.load(),
      DashboardBorrowedFunction.load(),
      DashboardMaterialsIssuedFunction.load(),
      DashboardOverdueFunction.load(),
      DashboardLowStockFunction.load(),
      DashboardDueTodayFunction.load(),
    ]);
    return DashboardSummary(
      totalItems: results[0] as int,
      borrowedToolsEquipment: results[1] as int,
      materialsIssued: results[2] as int,
      overdue: results[3] as int,
      lowStockItems: results[4] as List<DashboardLowStockItem>,
      dueTodayItems: results[5] as List<DashboardDueTodayItem>,
    );
  }
}
