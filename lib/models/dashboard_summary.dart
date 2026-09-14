class DashboardSummary {
  const DashboardSummary({
    required this.totalItems,
    required this.borrowedToolsEquipment,
    required this.materialsIssued,
    required this.overdue,
    required this.lowStockItems,
    required this.dueTodayItems,
  });

  final int totalItems;
  final int borrowedToolsEquipment;
  final int materialsIssued;
  final int overdue;
  final List<DashboardLowStockItem> lowStockItems;
  final List<DashboardDueTodayItem> dueTodayItems;
}

class DashboardLowStockItem {
  const DashboardLowStockItem({
    required this.productName,
    required this.availableStock,
    required this.unit,
    this.imageUrl,
  });

  final String productName;
  final int availableStock;
  final String unit;
  final String? imageUrl;
}

class DashboardDueTodayItem {
  const DashboardDueTodayItem({
    required this.transactionCode,
    required this.borrowerName,
    required this.productName,
    required this.remainingQuantity,
    required this.unit,
    required this.expectedReturnAt,
  });

  final String transactionCode;
  final String borrowerName;
  final String productName;
  final int remainingQuantity;
  final String unit;
  final DateTime expectedReturnAt;
}
