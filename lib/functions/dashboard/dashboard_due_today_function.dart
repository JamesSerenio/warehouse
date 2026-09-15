import 'package:flutter/foundation.dart';

import '../../models/dashboard_summary.dart';
import '../../services/supabase_service.dart';

abstract final class DashboardDueTodayFunction {
  static Future<List<DashboardDueTodayItem>> load() async {
    try {
      final now = philippineDateTime(DateTime.now());
      final startUtc = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(hours: 8));
      final endUtc = startUtc.add(const Duration(days: 1));
      final rows = await SupabaseService.client
          .from('transaction_items')
          .select(
            'id, transaction_id, item_id, quantity, returned_quantity, expected_return_at, item_type, '
            'transactions(transaction_code, borrower_name, contact_number), '
            'items(product_name, unit, image_path)',
          )
          .inFilter('item_type', const ['tool', 'equipment'])
          .not('expected_return_at', 'is', null)
          .gte('expected_return_at', startUtc.toIso8601String())
          .lt('expected_return_at', endUtc.toIso8601String())
          .order('expected_return_at');

      final items = <DashboardDueTodayItem>[];
      for (final row in rows) {
        final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
        final returned = (row['returned_quantity'] as num?)?.toInt() ?? 0;
        final remaining = (quantity - returned).clamp(0, quantity);
        final expected = DateTime.tryParse(
          row['expected_return_at']?.toString() ?? '',
        );
        final itemId = row['item_id'];
        if (remaining <= 0 ||
            expected == null ||
            itemId == null ||
            !isDueTodayPhilippines(expected)) {
          continue;
        }
        final transaction =
            row['transactions'] as Map<String, dynamic>? ?? const {};
        final item = row['items'] as Map<String, dynamic>? ?? const {};
        final imagePath = item['image_path']?.toString().trim();
        items.add(
          DashboardDueTodayItem(
            transactionCode: transaction['transaction_code']?.toString() ?? '',
            borrowerName: transaction['borrower_name']?.toString() ?? '',
            contactNumber: transaction['contact_number']?.toString() ?? '',
            itemId: itemId as Object,
            productName: item['product_name']?.toString() ?? 'Unknown item',
            remainingQuantity: remaining,
            unit: item['unit']?.toString() ?? '',
            expectedReturnAt: expected,
            imageUrl: imagePath == null || imagePath.isEmpty
                ? null
                : SupabaseService.client.storage
                      .from('item-images')
                      .getPublicUrl(imagePath),
          ),
        );
      }
      items.sort(
        (first, second) =>
            first.expectedReturnAt.compareTo(second.expectedReturnAt),
      );
      return List.unmodifiable(items);
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD DUE TODAY ERROR: $error');
      debugPrint('$stackTrace');
      return const [];
    }
  }
}

DateTime philippineDateTime(DateTime value) =>
    value.toUtc().add(const Duration(hours: 8));

bool isDueTodayPhilippines(DateTime expected, {DateTime? now}) {
  final due = philippineDateTime(expected);
  final today = philippineDateTime(now ?? DateTime.now());
  return due.year == today.year &&
      due.month == today.month &&
      due.day == today.day;
}
