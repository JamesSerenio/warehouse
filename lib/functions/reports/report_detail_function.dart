import 'monthly_report_function.dart';

abstract final class ReportDetailFunction {
  static List<ReportTransactionEntry> sortedHistory(MonthlyItemReport item) {
    final rows = [...item.history];
    rows.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return List.unmodifiable(rows);
  }
}
