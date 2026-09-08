import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class EditItemException implements Exception {
  const EditItemException(this.message);
  final String message;
}

abstract final class EditItemFunction {
  static Future<void> editItem({
    required Object itemId,
    required String productName,
    required String itemType,
    required String unit,
    required int lowStockLevel,
    String? note,
  }) async {
    final name = productName.trim();
    final normalizedUnit = unit.trim();
    final normalizedNote = note?.trim();
    if (name.isEmpty) {
      throw const EditItemException('Product name is required.');
    }
    if (!const {'tool', 'equipment', 'material'}.contains(itemType)) {
      throw const EditItemException('Please select a valid category.');
    }
    if (normalizedUnit.isEmpty) {
      throw const EditItemException('Unit is required.');
    }
    if (lowStockLevel < 0) {
      throw const EditItemException('Low stock level cannot be negative.');
    }
    try {
      await SupabaseService.client
          .from('items')
          .update({
            'product_name': name,
            'item_type': itemType,
            'unit': normalizedUnit,
            'low_stock_level': lowStockLevel,
            'note': normalizedNote == null || normalizedNote.isEmpty
                ? null
                : normalizedNote,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('EDIT ITEM SUPABASE ERROR: ${error.message}');
      debugPrint('$stackTrace');
      if (error.code == '23505') {
        throw const EditItemException('An item with this name already exists.');
      }
      throw const EditItemException('Unable to save item changes.');
    } catch (error, stackTrace) {
      debugPrint('EDIT ITEM ERROR: $error');
      debugPrint('$stackTrace');
      throw const EditItemException('Unable to save item changes.');
    }
  }
}
