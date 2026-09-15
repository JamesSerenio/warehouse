import '../functions/inventory/inventory_list_function.dart';

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
  const DashboardLowStockItem({required this.item});

  final WarehouseItem item;
  String get productName => item.productName;
  int get availableStock => item.availableStock;
  int get lowStockLevel => item.lowStockLevel;
  String get unit => item.unit;
  String? get imageUrl => item.imageUrl;
  bool get isOutOfStock => availableStock == 0;
}

class DashboardDueTodayItem {
  const DashboardDueTodayItem({
    required this.transactionCode,
    required this.borrowerName,
    required this.contactNumber,
    required this.itemId,
    required this.productName,
    required this.remainingQuantity,
    required this.unit,
    required this.expectedReturnAt,
    this.imageUrl,
  });

  final String transactionCode;
  final String borrowerName;
  final String contactNumber;
  final Object itemId;
  final String productName;
  final int remainingQuantity;
  final String unit;
  final DateTime expectedReturnAt;
  final String? imageUrl;
}
