import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class InventoryListException implements Exception {
  const InventoryListException(this.message);
  final String message;
}

class WarehouseItem {
  const WarehouseItem({
    required this.id,
    required this.productName,
    required this.itemType,
    required this.unit,
    required this.totalStock,
    required this.availableStock,
    required this.borrowedStock,
    required this.lowStockLevel,
    required this.isActive,
    this.note,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });
  final Object id;
  final String productName;
  final String itemType;
  final String unit;
  final int totalStock;
  final int availableStock;
  final int borrowedStock;
  final int lowStockLevel;
  final bool isActive;
  final String? note;
  final String? imagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get typeLabel => switch (itemType) {
    'tool' => 'Tool',
    'equipment' => 'Equipment',
    'material' => 'Material / Consumable',
    _ => itemType,
  };
  String? get imageUrl => imagePath == null || imagePath!.isEmpty
      ? null
      : SupabaseService.client.storage
            .from('item-images')
            .getPublicUrl(imagePath!);
  bool get isLowStock => availableStock <= lowStockLevel;

  factory WarehouseItem.fromJson(Map<String, dynamic> json) => WarehouseItem(
    id: json['id'] as Object,
    productName: json['product_name']?.toString() ?? '',
    itemType: json['item_type']?.toString() ?? '',
    unit: json['unit']?.toString() ?? '',
    totalStock: _integer(json['total_stock']),
    availableStock: _integer(json['available_stock']),
    borrowedStock: _integer(json['borrowed_stock']),
    lowStockLevel: _integer(json['low_stock_level']),
    isActive: json['is_active'] as bool? ?? true,
    note: json['note']?.toString(),
    imagePath: json['image_path']?.toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
  );
}

abstract final class InventoryListFunction {
  static const _columns =
      'id, product_name, item_type, unit, total_stock, available_stock, borrowed_stock, low_stock_level, note, image_path, is_active, created_at, updated_at';

  static Future<List<WarehouseItem>> loadItems() async {
    try {
      final rows = await SupabaseService.client
          .from('items')
          .select(_columns)
          .eq('is_active', true)
          .order('product_name');
      return rows.map(WarehouseItem.fromJson).toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('ITEM LIST SUPABASE ERROR: ${error.message}');
      debugPrint('ITEM LIST SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const InventoryListException('Unable to load items.');
    } catch (error, stackTrace) {
      debugPrint('ITEM LIST ERROR: $error');
      debugPrint('$stackTrace');
      throw const InventoryListException(
        'Unable to connect. Check your internet connection.',
      );
    }
  }

  static Future<WarehouseItem> loadItem(Object itemId) async {
    try {
      final row = await SupabaseService.client
          .from('items')
          .select(_columns)
          .eq('id', itemId)
          .single();
      return WarehouseItem.fromJson(row);
    } catch (error, stackTrace) {
      debugPrint('VIEW ITEM ERROR: $error');
      debugPrint('$stackTrace');
      throw const InventoryListException('Unable to refresh item details.');
    }
  }
}

int _integer(dynamic value) => value is num ? value.toInt() : 0;
