import 'package:flutter/foundation.dart';

import '../../models/dashboard_summary.dart';
import '../../services/supabase_service.dart';

abstract final class DashboardDueTodayFunction {
  static Future<List<DashboardDueTodayItem>> load() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final rows = await SupabaseService.client
          .from('transaction_items')
          .select(
            'quantity, returned_quantity, expected_return_at, item_type, '
            'transactions(transaction_code, borrower_name), '
            'items(product_name, unit)',
          )
          .inFilter('item_type', const ['tool', 'equipment'])
          .gte('expected_return_at', start.toUtc().toIso8601String())
          .lt('expected_return_at', end.toUtc().toIso8601String())
          .order('expected_return_at');

      return rows
          .map((row) {
            final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
            final returned = (row['returned_quantity'] as num?)?.toInt() ?? 0;
            final transaction =
                row['transactions'] as Map<String, dynamic>? ?? const {};
            final item = row['items'] as Map<String, dynamic>? ?? const {};
            return DashboardDueTodayItem(
              transactionCode:
                  transaction['transaction_code']?.toString() ?? '',
              borrowerName: transaction['borrower_name']?.toString() ?? '',
              productName: item['product_name']?.toString() ?? 'Unknown item',
              remainingQuantity: (quantity - returned).clamp(0, quantity),
              unit: item['unit']?.toString() ?? '',
              expectedReturnAt: DateTime.parse(
                row['expected_return_at'].toString(),
              ),
            );
          })
          .where((item) => item.remainingQuantity > 0)
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD DUE TODAY ERROR: $error');
      debugPrint('$stackTrace');
      return const [];
    }
  }
}
