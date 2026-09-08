import 'dart:ui';

import '../../functions/inventory/inventory_list_function.dart';

class TransactionDraftItem {
  const TransactionDraftItem({
    required this.item,
    this.quantity = 1,
    this.returnDate,
    this.returnTimeMinutes,
  });

  final WarehouseItem item;
  final int quantity;
  final DateTime? returnDate;
  final int? returnTimeMinutes;

  bool get requiresReturn =>
      item.itemType == 'tool' || item.itemType == 'equipment';

  TransactionDraftItem copyWith({
    int? quantity,
    DateTime? returnDate,
    int? returnTimeMinutes,
  }) {
    return TransactionDraftItem(
      item: item,
      quantity: quantity ?? this.quantity,
      returnDate: returnDate ?? this.returnDate,
      returnTimeMinutes: returnTimeMinutes ?? this.returnTimeMinutes,
    );
  }
}

class NewTransactionDraft {
  const NewTransactionDraft({
    required this.borrowerName,
    required this.contactNumber,
    required this.items,
    this.note,
  });

  final String borrowerName;
  final String contactNumber;
  final List<TransactionDraftItem> items;
  final String? note;
}

class TransactionStorageUnavailableException implements Exception {
  const TransactionStorageUnavailableException();

  String get message =>
      'Transaction database setup is required before transactions can be saved.';
}

abstract final class NewTransactionFunction {
  static Future<List<WarehouseItem>> loadAvailableItems() async {
    final items = await InventoryListFunction.loadItems();
    return items
        .where((item) => item.availableStock > 0)
        .toList(growable: false);
  }

  static List<WarehouseItem> searchItems(
    List<WarehouseItem> items,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return items
        .where((item) => item.productName.toLowerCase().contains(normalized))
        .take(8)
        .toList(growable: false);
  }

  static String? validateContact(String value) {
    final contact = value.trim();
    if (contact.isEmpty) return 'Contact number is required.';
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(contact)) {
      return 'Contact number must contain digits only.';
    }
    if (!RegExp(r'^(?:\+63|0)[0-9]{10}$').hasMatch(contact)) {
      return 'Enter a valid contact number.';
    }
    return null;
  }

  static String? validateDraft(NewTransactionDraft draft) {
    if (draft.borrowerName.trim().isEmpty) return 'Borrower name is required.';
    final contactError = validateContact(draft.contactNumber);
    if (contactError != null) return contactError;
    if (draft.items.isEmpty) return 'Please add at least one item.';

    for (final entry in draft.items) {
      if (entry.quantity < 1) {
        return 'Quantity for ${entry.item.productName} must be at least 1.';
      }
      if (entry.quantity > entry.item.availableStock) {
        return 'Only ${entry.item.availableStock} ${entry.item.unit} are available for ${entry.item.productName}.';
      }
      if (entry.requiresReturn &&
          (entry.returnDate == null || entry.returnTimeMinutes == null)) {
        return 'Complete the return date and time for ${entry.item.productName}.';
      }
    }
    return null;
  }

  static Future<void> confirmTransaction({
    required NewTransactionDraft draft,
    required List<Offset?> signaturePoints,
  }) async {
    // Transaction tables and signature storage are intentionally not assumed.
    // Connect this method only after the database schema is installed.
    throw const TransactionStorageUnavailableException();
  }
}
