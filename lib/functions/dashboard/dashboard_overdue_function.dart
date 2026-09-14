import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';

abstract final class DashboardOverdueFunction {
  static Future<int> load() async {
    try {
      final rows = await SupabaseService.client
          .from('transaction_items')
          .select('quantity, returned_quantity')
          .inFilter('item_type', const ['tool', 'equipment'])
          .lt('expected_return_at', DateTime.now().toUtc().toIso8601String());
      return rows.where((row) {
        final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
        final returned = (row['returned_quantity'] as num?)?.toInt() ?? 0;
        return quantity - returned > 0;
      }).length;
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD OVERDUE ERROR: $error');
      debugPrint('$stackTrace');
      return 0;
    }
  }
}
