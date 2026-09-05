import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class StockHistoryException implements Exception {
  const StockHistoryException(this.message);

  final String message;
}

class StockMovementRecord {
  const StockMovementRecord({
    required this.createdAt,
    required this.itemName,
    required this.movementType,
    required this.quantity,
    required this.balanceAfter,
    this.referenceCode,
  });

  final DateTime? createdAt;
  final String itemName;
  final String movementType;
  final num quantity;
  final num balanceAfter;
  final String? referenceCode;

  factory StockMovementRecord.fromJson(Map<String, dynamic> json) {
    final item = json['items'];
    final itemData = item is Map ? item : null;
    return StockMovementRecord(
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      itemName: itemData?['product_name']?.toString() ?? 'Unknown item',
      movementType: json['movement_type']?.toString() ?? 'adjustment',
      quantity: json['quantity'] is num ? json['quantity'] as num : 0,
      balanceAfter: json['balance_after'] is num
          ? json['balance_after'] as num
          : 0,
      referenceCode: json['reference_code']?.toString(),
    );
  }
}

abstract final class StockHistoryFunction {
  static Future<List<StockMovementRecord>> loadStockHistory() async {
    try {
      final rows = await SupabaseService.client
          .from('stock_movements')
          .select(
            'created_at, movement_type, quantity, balance_after, '
            'reference_code, items(product_name)',
          )
          .order('created_at', ascending: false);

      return rows
          .map((row) => StockMovementRecord.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('STOCK HISTORY SUPABASE ERROR: ${error.message}');
      debugPrint('STOCK HISTORY SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const StockHistoryException(
        'Unable to load stock history. Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('STOCK HISTORY ERROR: $error');
      debugPrint('$stackTrace');
      throw const StockHistoryException(
        'Unable to connect. Check your internet connection.',
      );
    }
  }
}
