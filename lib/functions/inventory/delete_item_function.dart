import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';
import 'inventory_list_function.dart';

class DeleteItemException implements Exception {
  const DeleteItemException(this.message);
  final String message;
}

abstract final class DeleteItemFunction {
  static Future<void> archiveItem(WarehouseItem item) async {
    if (item.borrowedStock > 0) {
      throw DeleteItemException(
        'Cannot delete this item because ${item.borrowedStock} unit(s) are currently borrowed.',
      );
    }
    try {
      await SupabaseService.client
          .from('items')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.id);
    } catch (error, stackTrace) {
      debugPrint('ARCHIVE ITEM ERROR: $error');
      debugPrint('$stackTrace');
      throw const DeleteItemException('Unable to delete this item.');
    }
  }
}
