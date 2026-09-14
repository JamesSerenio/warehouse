import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../functions/inventory/inventory_list_function.dart';
import '../../services/supabase_service.dart';
import 'generate_code_function.dart';

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

  DateTime? get expectedReturnAt {
    if (!requiresReturn || returnDate == null || returnTimeMinutes == null) {
      return null;
    }
    return DateTime(
      returnDate!.year,
      returnDate!.month,
      returnDate!.day,
      returnTimeMinutes! ~/ 60,
      returnTimeMinutes! % 60,
    );
  }

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

class CreatedTransaction {
  const CreatedTransaction({required this.id, required this.transactionCode});

  final Object id;
  final String transactionCode;
}

class CreateTransactionException implements Exception {
  const CreateTransactionException(this.message);
  final String message;
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
      if (entry.requiresReturn && entry.expectedReturnAt == null) {
        return 'Complete the return date and time for ${entry.item.productName}.';
      }
    }
    return null;
  }

  static Future<CreatedTransaction> confirmTransaction({
    required NewTransactionDraft draft,
    required Uint8List signaturePng,
  }) async {
    final validation = validateDraft(draft);
    if (validation != null) throw CreateTransactionException(validation);
    if (signaturePng.isEmpty) {
      throw const CreateTransactionException('Borrower signature is required.');
    }

    final code = await _generateUniqueCode();
    final signaturePath = '$code/borrow_signature.png';
    var signatureUploaded = false;

    try {
      await SupabaseService.client.storage
          .from('signatures')
          .uploadBinary(
            signaturePath,
            signaturePng,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              cacheControl: '3600',
              upsert: false,
            ),
          );
      signatureUploaded = true;

      final result = await SupabaseService.client.rpc(
        'create_warehouse_transaction',
        params: {
          'p_transaction_code': code,
          'p_borrower_name': draft.borrowerName.trim(),
          'p_contact_number': draft.contactNumber.trim(),
          'p_note': draft.note?.trim().isEmpty ?? true
              ? null
              : draft.note!.trim(),
          'p_signature_path': signaturePath,
          'p_items': [
            for (final entry in draft.items)
              {
                'item_id': entry.item.id.toString(),
                'quantity': entry.quantity,
                'item_type': entry.item.itemType,
                'expected_return_at': entry.expectedReturnAt
                    ?.toUtc()
                    .toIso8601String(),
              },
          ],
        },
      );

      final data = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      final transactionId = data['transaction_id'];
      if (transactionId == null) {
        throw const CreateTransactionException(
          'The transaction was saved but no transaction ID was returned.',
        );
      }
      return CreatedTransaction(id: transactionId, transactionCode: code);
    } on CreateTransactionException {
      if (signatureUploaded) await _removeSignature(signaturePath);
      rethrow;
    } on StorageException catch (error, stackTrace) {
      debugPrint('CREATE TRANSACTION STORAGE ERROR: ${error.message}');
      debugPrint('CREATE TRANSACTION STORAGE STATUS: ${error.statusCode}');
      debugPrint('$stackTrace');
      throw const CreateTransactionException(
        'Unable to upload the signature. Please try again.',
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('CREATE TRANSACTION ERROR: ${error.message}');
      debugPrint('CREATE TRANSACTION CODE: ${error.code}');
      debugPrint('CREATE TRANSACTION DETAILS: ${error.details}');
      debugPrint('$stackTrace');
      if (signatureUploaded) await _removeSignature(signaturePath);
      final message = error.message.toLowerCase();
      if (message.contains('not enough stock')) {
        throw CreateTransactionException(error.message);
      }
      if (error.code == 'PGRST202' || message.contains('function')) {
        throw const CreateTransactionException(
          'The transaction save function is missing in Supabase. Run the required SQL setup.',
        );
      }
      throw CreateTransactionException(
        error.message.isEmpty
            ? 'Unable to save the transaction. Please try again.'
            : error.message,
      );
    } catch (error, stackTrace) {
      debugPrint('CREATE TRANSACTION ERROR: $error');
      debugPrint('$stackTrace');
      if (signatureUploaded) await _removeSignature(signaturePath);
      throw const CreateTransactionException(
        'Unable to save the transaction. Please try again.',
      );
    }
  }

  static Future<String> _generateUniqueCode() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = GenerateCodeFunction.generate();
      final existing = await SupabaseService.client
          .from('transactions')
          .select('id')
          .eq('transaction_code', code)
          .maybeSingle();
      if (existing == null) return code;
    }
    throw const CreateTransactionException(
      'Unable to generate a unique transaction code. Please try again.',
    );
  }

  static Future<void> _removeSignature(String path) async {
    try {
      await SupabaseService.client.storage.from('signatures').remove([path]);
    } catch (error, stackTrace) {
      debugPrint('SIGNATURE CLEANUP ERROR: $error');
      debugPrint('$stackTrace');
    }
  }
}
