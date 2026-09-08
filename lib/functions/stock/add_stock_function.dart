import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';
import '../inventory/inventory_list_function.dart';

class AddStockException implements Exception {
  const AddStockException(this.message);
  final String message;
}

abstract final class AddStockFunction {
  static Future<void> addStock({
    required WarehouseItem item,
    required int quantity,
    required DateTime dateReceived,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw const AddStockException('Quantity must be greater than zero.');
    }
    final newTotal = item.totalStock + quantity;
    final newAvailable = item.availableStock + quantity;
    final normalizedNote = note?.trim();
    var itemUpdated = false;
    try {
      await SupabaseService.client
          .from('items')
          .update({
            'total_stock': newTotal,
            'available_stock': newAvailable,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.id);
      itemUpdated = true;
      await SupabaseService.client.from('stock_movements').insert({
        'item_id': item.id,
        'movement_type': 'add_stock',
        'quantity': quantity,
        'balance_after': newAvailable,
        'reference_code': null,
        'note': normalizedNote == null || normalizedNote.isEmpty
            ? null
            : normalizedNote,
        'created_at': dateReceived.toUtc().toIso8601String(),
      });
    } catch (error, stackTrace) {
      debugPrint('ADD STOCK ERROR: $error');
      debugPrint('$stackTrace');
      if (itemUpdated) {
        try {
          await SupabaseService.client
              .from('items')
              .update({
                'total_stock': item.totalStock,
                'available_stock': item.availableStock,
              })
              .eq('id', item.id);
        } catch (rollbackError, rollbackStackTrace) {
          debugPrint('ADD STOCK ROLLBACK ERROR: $rollbackError');
          debugPrint('$rollbackStackTrace');
        }
      }
      throw const AddStockException('Unable to add stock. Please try again.');
    }
  }
}
