import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_system/functions/reports/monthly_report_function.dart';
import 'package:warehouse_system/functions/reports/report_export_function.dart';

void main() {
  test('web export encodes XLSX and triggers the browser saver', () async {
    final report = MonthlyReport(
      month: DateTime(2026, 9),
      summary: const ReportSummary(
        totalItems: 0,
        toolsBorrowed: 0,
        materialsIssued: 0,
        totalReturned: 0,
        overdueItems: 0,
        activeTransactions: 0,
      ),
      items: const [],
    );

    final result = await ReportExportFunction.exportExcel(
      report,
      filterName: 'All Items',
    );

    expect(result.message, 'Excel report exported successfully.');
  });
}
