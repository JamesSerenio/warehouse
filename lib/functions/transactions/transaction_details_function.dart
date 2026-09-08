import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';

class TransactionDetails {
  const TransactionDetails({
    required this.id,
    required this.transactionCode,
    required this.borrowerName,
    required this.contactNumber,
    required this.status,
    required this.items,
    this.note,
    this.createdAt,
    this.signaturePath,
  });

  final Object id;
  final String transactionCode;
  final String borrowerName;
  final String contactNumber;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final String? signaturePath;
  final List<TransactionLineDetails> items;

  List<TransactionLineDetails> get returnableItems =>
      items.where((item) => item.requiresReturn).toList(growable: false);
  List<TransactionLineDetails> get materialItems =>
      items.where((item) => !item.requiresReturn).toList(growable: false);
  bool get hasRemainingReturnableItems =>
      returnableItems.any((item) => item.remainingQuantity > 0);

  factory TransactionDetails.fromJson(Map<String, dynamic> json) {
    final rawItems = json['transaction_items'] as List<dynamic>? ?? const [];
    return TransactionDetails(
      id: json['id'] as Object,
      transactionCode: json['transaction_code']?.toString() ?? '',
      borrowerName: json['borrower_name']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      signaturePath: json['signature_path']?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(TransactionLineDetails.fromJson)
          .toList(growable: false),
    );
  }
}

class TransactionLineDetails {
  const TransactionLineDetails({
    required this.id,
    required this.itemId,
    required this.productName,
    required this.itemType,
    required this.unit,
    required this.quantity,
    required this.returnedQuantity,
    required this.status,
    this.expectedReturnAt,
    this.imagePath,
  });

  final Object id;
  final Object itemId;
  final String productName;
  final String itemType;
  final String unit;
  final int quantity;
  final int returnedQuantity;
  final String status;
  final DateTime? expectedReturnAt;
  final String? imagePath;

  int get remainingQuantity => (quantity - returnedQuantity).clamp(0, quantity);
  bool get requiresReturn => itemType == 'tool' || itemType == 'equipment';
  String get itemTypeLabel => switch (itemType) {
    'tool' => 'Tool',
    'equipment' => 'Equipment',
    'material' => 'Material / Consumable',
    _ => itemType,
  };
  bool get isOverdue =>
      requiresReturn &&
      remainingQuantity > 0 &&
      expectedReturnAt != null &&
      expectedReturnAt!.isBefore(DateTime.now());
  String get displayStatus {
    if (isOverdue) return 'OVERDUE';
    if (remainingQuantity == 0) return 'COMPLETED';
    if (returnedQuantity > 0) return 'PARTIAL';
    return status.toUpperCase();
  }

  factory TransactionLineDetails.fromJson(Map<String, dynamic> json) {
    final item = json['items'] as Map<String, dynamic>? ?? const {};
    return TransactionLineDetails(
      id: json['id'] as Object,
      itemId: json['item_id'] as Object,
      productName: item['product_name']?.toString() ?? 'Unknown item',
      itemType: item['item_type']?.toString() ?? '',
      unit: item['unit']?.toString() ?? '',
      quantity: _integer(json['quantity']),
      returnedQuantity: _integer(json['returned_quantity']),
      status: json['status']?.toString() ?? 'active',
      expectedReturnAt: DateTime.tryParse(
        json['expected_return_at']?.toString() ?? '',
      ),
      imagePath: item['image_path']?.toString(),
    );
  }
}

abstract final class TransactionDetailsFunction {
  static Future<String?> createSignatureUrl(String? signaturePath) async {
    if (signaturePath == null || signaturePath.trim().isEmpty) return null;
    try {
      return await SupabaseService.client.storage
          .from('signatures')
          .createSignedUrl(signaturePath, 3600);
    } catch (error, stackTrace) {
      debugPrint('SIGNATURE URL ERROR: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }
}

int _integer(dynamic value) => value is num ? value.toInt() : 0;
