import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';

abstract final class DashboardTotalItemsFunction {
  static Future<int> load() async {
    try {
      final rows = await SupabaseService.client
          .from('items')
          .select('id')
          .eq('is_active', true);
      return rows.length;
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD TOTAL ITEMS ERROR: $error');
      debugPrint('$stackTrace');
      return 0;
    }
  }
}
