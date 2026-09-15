import 'package:flutter/foundation.dart';

import '../../functions/inventory/inventory_list_function.dart';
import '../../models/dashboard_summary.dart';
import '../../services/supabase_service.dart';

abstract final class DashboardLowStockFunction {
  static const _columns =
      'id, product_name, item_type, unit, total_stock, available_stock, borrowed_stock, low_stock_level, note, image_path, is_active, created_at, updated_at';

  static Future<List<DashboardLowStockItem>> load() async {
    try {
      final rows = await SupabaseService.client
          .from('items')
          .select(_columns)
          .eq('is_active', true);
      final items = rows
          .map(WarehouseItem.fromJson)
          .where(isLowStock)
          .map((item) => DashboardLowStockItem(item: item))
          .toList();
      items.sort(compareLowStock);
      return List.unmodifiable(items);
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD LOW STOCK ERROR: $error');
      debugPrint('$stackTrace');
      return const [];
    }
  }
}

bool isLowStock(WarehouseItem item) =>
    item.isActive && item.availableStock <= item.lowStockLevel;

int compareLowStock(DashboardLowStockItem first, DashboardLowStockItem second) {
  final outOfStock = (first.isOutOfStock ? 0 : 1).compareTo(
    second.isOutOfStock ? 0 : 1,
  );
  if (outOfStock != 0) return outOfStock;
  final available = first.availableStock.compareTo(second.availableStock);
  if (available != 0) return available;
  return first.productName.toLowerCase().compareTo(
    second.productName.toLowerCase(),
  );
}
