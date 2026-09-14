import 'monthly_report_function.dart';

enum ReportFilter {
  allItems,
  toolsEquipment,
  materials,
  borrowed,
  returned,
  overdue,
}

abstract final class ReportFilterFunction {
  static List<MonthlyItemReport> apply({
    required List<MonthlyItemReport> items,
    required String query,
    required ReportFilter filter,
  }) {
    final value = query.trim().toLowerCase();
    return items
        .where((item) {
          final searchable =
              item.productName.toLowerCase().contains(value) ||
              item.history.any(
                (entry) =>
                    entry.transactionCode.toLowerCase().contains(value) ||
                    entry.borrowerName.toLowerCase().contains(value),
              );
          if (!searchable) return false;
          return switch (filter) {
            ReportFilter.allItems => true,
            ReportFilter.toolsEquipment => !item.isMaterial,
            ReportFilter.materials => item.isMaterial,
            ReportFilter.borrowed =>
              !item.isMaterial && item.borrowedOrIssued > 0,
            ReportFilter.returned => !item.isMaterial && item.returned > 0,
            ReportFilter.overdue => item.status == ReportItemStatus.overdue,
          };
        })
        .toList(growable: false);
  }
}
