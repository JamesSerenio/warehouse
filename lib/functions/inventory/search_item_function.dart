import 'inventory_list_function.dart';

abstract final class SearchItemFunction {
  static List<WarehouseItem> filter({
    required List<WarehouseItem> items,
    required String query,
    String? itemType,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return items
        .where((item) {
          final matchesType = itemType == null || item.itemType == itemType;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.productName.toLowerCase().contains(normalizedQuery) ||
              item.unit.toLowerCase().contains(normalizedQuery) ||
              item.typeLabel.toLowerCase().contains(normalizedQuery);
          return matchesType && matchesQuery;
        })
        .toList(growable: false);
  }
}
