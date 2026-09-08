import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';

abstract final class DashboardBorrowedFunction {
  static Future<int> load() async {
    try {
      final rows = await SupabaseService.client
          .from('items')
          .select('borrowed_stock')
          .eq('is_active', true)
          .inFilter('item_type', ['tool', 'equipment']);
      return rows.fold<int>(
        0,
        (total, row) => total + ((row['borrowed_stock'] as num?)?.toInt() ?? 0),
      );
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD BORROWED ERROR: $error');
      debugPrint('$stackTrace');
      return 0;
    }
  }
}
