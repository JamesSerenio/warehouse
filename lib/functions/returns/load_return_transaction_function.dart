import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../transactions/transaction_details_function.dart';

class ReturnTransactionNotFoundException implements Exception {
  const ReturnTransactionNotFoundException();
}

class LoadReturnTransactionException implements Exception {
  const LoadReturnTransactionException(this.message);
  final String message;
}

abstract final class LoadReturnTransactionFunction {
  static const _query =
      'id, transaction_code, borrower_name, contact_number, note, status, created_at, signature_path, '
      'transaction_items(id, item_id, quantity, returned_quantity, expected_return_at, status, '
      'items(id, product_name, item_type, unit, image_path))';

  static Future<TransactionDetails> load({
    Object? transactionId,
    String? transactionCode,
  }) async {
    if (transactionId == null &&
        (transactionCode == null || transactionCode.trim().isEmpty)) {
      throw const LoadReturnTransactionException('A transaction is required.');
    }
    try {
      var query = SupabaseService.client.from('transactions').select(_query);
      final Map<String, dynamic>? row;
      if (transactionId != null) {
        row = await query.eq('id', transactionId).maybeSingle();
      } else {
        row = await query
            .ilike('transaction_code', transactionCode!.trim())
            .maybeSingle();
      }
      if (row == null) throw const ReturnTransactionNotFoundException();
      return TransactionDetails.fromJson(row);
    } on ReturnTransactionNotFoundException {
      rethrow;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('LOAD RETURN SUPABASE ERROR: ${error.message}');
      debugPrint('LOAD RETURN SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const LoadReturnTransactionException(
        'Unable to load return details.',
      );
    } catch (error, stackTrace) {
      if (error is LoadReturnTransactionException) rethrow;
      debugPrint('LOAD RETURN ERROR: $error');
      debugPrint('$stackTrace');
      throw const LoadReturnTransactionException(
        'Unable to connect to the return service.',
      );
    }
  }
}
