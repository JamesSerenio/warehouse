import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';

abstract final class DashboardMaterialsIssuedFunction {
  static Future<int> load() async {
    try {
      final rows = await SupabaseService.client
          .from('stock_movements')
          .select('quantity')
          .eq('movement_type', 'material_issued');
      return rows.fold<int>(
        0,
        (total, row) => total + ((row['quantity'] as num?)?.abs().toInt() ?? 0),
      );
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD MATERIALS ISSUED ERROR: $error');
      debugPrint('$stackTrace');
      return 0;
    }
  }
}
