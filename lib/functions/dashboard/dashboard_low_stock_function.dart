import 'package:flutter/foundation.dart';

import '../../models/dashboard_summary.dart';
import '../../services/supabase_service.dart';

abstract final class DashboardLowStockFunction {
  static Future<List<DashboardLowStockItem>> load() async {
    try {
      final rows = await SupabaseService.client
          .from('items')
          .select(
            'product_name, available_stock, low_stock_level, unit, image_path',
          )
          .eq('is_active', true);
      final items = rows
          .where((row) {
            final available = (row['available_stock'] as num?)?.toInt() ?? 0;
            final threshold = (row['low_stock_level'] as num?)?.toInt() ?? 0;
            return available <= threshold;
          })
          .map((row) {
            final imagePath = row['image_path']?.toString();
            return DashboardLowStockItem(
              productName: row['product_name']?.toString() ?? 'Unnamed item',
              availableStock: (row['available_stock'] as num?)?.toInt() ?? 0,
              unit: row['unit']?.toString() ?? '',
              imageUrl: imagePath == null || imagePath.isEmpty
                  ? null
                  : SupabaseService.client.storage
                        .from('item-images')
                        .getPublicUrl(imagePath),
            );
          })
          .toList();
      items.sort(
        (first, second) =>
            first.availableStock.compareTo(second.availableStock),
      );
      return items.take(5).toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD LOW STOCK ERROR: $error');
      debugPrint('$stackTrace');
      return const [];
    }
  }
}
