import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import 'inventory_list_function.dart';

class EditItemException implements Exception {
  const EditItemException(this.message);
  final String message;
}

abstract final class EditItemFunction {
  static Future<WarehouseItem> updateItem({
    required Object itemId,
    required String productName,
    required String itemType,
    required String unit,
    required int totalStock,
    required int lowStockLevel,
    String? note,
    String? correctionReason,
  }) async {
    final name = productName.trim();
    final normalizedUnit = unit.trim();
    final normalizedNote = note?.trim();
    final normalizedReason = correctionReason?.trim();

    if (name.isEmpty) {
      throw const EditItemException('Product name is required.');
    }
    if (!const {'tool', 'equipment', 'material'}.contains(itemType)) {
      throw const EditItemException('Please select a valid category.');
    }
    if (normalizedUnit.isEmpty) {
      throw const EditItemException('Unit is required.');
    }
    if (totalStock < 0) {
      throw const EditItemException('Total stock cannot be negative.');
    }
    if (lowStockLevel < 0) {
      throw const EditItemException('Low stock level cannot be negative.');
    }

    try {
      final result = await SupabaseService.client.rpc(
        'update_item_with_stock_correction',
        params: {
          'p_item_id': itemId.toString(),
          'p_product_name': name,
          'p_item_type': itemType,
          'p_unit': normalizedUnit,
          'p_total_stock': totalStock,
          'p_low_stock_level': lowStockLevel,
          'p_note': normalizedNote == null || normalizedNote.isEmpty
              ? null
              : normalizedNote,
          'p_correction_reason':
              normalizedReason == null || normalizedReason.isEmpty
              ? null
              : normalizedReason,
        },
      );

      if (result is! Map) {
        throw const EditItemException('The updated item could not be loaded.');
      }
      return WarehouseItem.fromJson(Map<String, dynamic>.from(result));
    } on EditItemException {
      rethrow;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('EDIT ITEM SUPABASE ERROR: ${error.message}');
      debugPrint('EDIT ITEM SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');

      final message = error.message;
      if (message.contains('currently borrowed')) {
        throw EditItemException(_cleanDatabaseMessage(message));
      }
      if (message.contains('quantity already issued')) {
        throw const EditItemException(
          'Total stock cannot be lower than the quantity already issued.',
        );
      }
      if (message.contains('reason for the stock correction')) {
        throw const EditItemException(
          'Please enter a reason for the stock correction.',
        );
      }
      if (error.code == '23505') {
        throw const EditItemException('An item with this name already exists.');
      }
      if (error.code == '42883') {
        throw const EditItemException(
          'Stock correction is not configured. Run the required Supabase SQL.',
        );
      }
      throw const EditItemException('Unable to save item changes.');
    } catch (error, stackTrace) {
      debugPrint('EDIT ITEM ERROR: $error');
      debugPrint('$stackTrace');
      throw const EditItemException('Unable to save item changes.');
    }
  }

  static String _cleanDatabaseMessage(String message) {
    final start = message.indexOf('Total stock cannot');
    return start >= 0 ? message.substring(start) : message;
  }
}
