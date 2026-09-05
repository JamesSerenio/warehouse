import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class AddItemException implements Exception {
  const AddItemException(this.message);

  final String message;
}

abstract final class AddItemFunction {
  static Future<void> addItem({
    required String productName,
    required String itemType,
    required String unit,
    required int initialStock,
    required int lowStockLevel,
    String? note,
  }) async {
    final trimmedName = productName.trim();
    final trimmedUnit = unit.trim();
    final trimmedNote = note?.trim();

    if (trimmedName.isEmpty) {
      throw const AddItemException('Product name is required.');
    }
    if (!const {'tool', 'equipment', 'material'}.contains(itemType)) {
      throw const AddItemException('Please select a valid category.');
    }
    if (trimmedUnit.isEmpty) {
      throw const AddItemException('Unit is required.');
    }
    if (initialStock < 0 || lowStockLevel < 0) {
      throw const AddItemException('Stock quantities cannot be negative.');
    }

    Object? insertedItemId;
    try {
      final item = await SupabaseService.client
          .from('items')
          .insert({
            'product_name': trimmedName,
            'item_type': itemType,
            'unit': trimmedUnit,
            'total_stock': initialStock,
            'available_stock': initialStock,
            'borrowed_stock': 0,
            'low_stock_level': lowStockLevel,
            'note': trimmedNote == null || trimmedNote.isEmpty
                ? null
                : trimmedNote,
          })
          .select('id')
          .single();

      insertedItemId = item['id'];
      if (insertedItemId == null) {
        throw const AddItemException(
          'The saved item did not return a valid ID.',
        );
      }

      await SupabaseService.client.from('stock_movements').insert({
        'item_id': insertedItemId,
        'movement_type': 'initial_stock',
        'quantity': initialStock,
        'balance_after': initialStock,
        'reference_code': null,
        'note': 'Initial stock',
      });
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('ADD ITEM SUPABASE ERROR: ${error.message}');
      debugPrint('ADD ITEM SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');

      if (insertedItemId != null) {
        await _removeIncompleteItem(insertedItemId);
      }

      if (error.code == '23505' ||
          error.message.toLowerCase().contains('duplicate')) {
        throw const AddItemException(
          'An item with this product name already exists.',
        );
      }
      throw const AddItemException(
        'Unable to save the item. Please try again.',
      );
    } on AddItemException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ADD ITEM ERROR: $error');
      debugPrint('$stackTrace');
      if (insertedItemId != null) {
        await _removeIncompleteItem(insertedItemId);
      }
      throw const AddItemException(
        'Unable to connect. Check your internet connection and try again.',
      );
    }
  }

  static Future<void> _removeIncompleteItem(Object itemId) async {
    try {
      await SupabaseService.client.from('items').delete().eq('id', itemId);
    } catch (rollbackError, stackTrace) {
      debugPrint('ADD ITEM ROLLBACK ERROR: $rollbackError');
      debugPrint('$stackTrace');
    }
  }
}
