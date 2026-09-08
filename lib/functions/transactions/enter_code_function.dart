import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import 'transaction_details_function.dart';

class TransactionCodeNotFoundException implements Exception {
  const TransactionCodeNotFoundException();
}

class TransactionLookupException implements Exception {
  const TransactionLookupException(this.message);
  final String message;
}

abstract final class EnterCodeFunction {
  static String? validateCode(String value) {
    final code = value.trim().toUpperCase();
    if (code.length < 4) return 'Enter the complete 4-character code.';
    if (!RegExp(r'^[A-Z0-9]{4}$').hasMatch(code)) {
      return 'Invalid transaction code format.';
    }
    return null;
  }

  static Future<TransactionDetails> findTransaction(String value) async {
    final code = value.trim().toUpperCase();
    try {
      final row = await SupabaseService.client
          .from('transactions')
          .select(
            'id, transaction_code, borrower_name, contact_number, note, status, created_at, signature_path, '
            'transaction_items(id, item_id, quantity, returned_quantity, expected_return_at, status, '
            'items(id, product_name, item_type, unit, image_path))',
          )
          .ilike('transaction_code', code)
          .maybeSingle();
      if (row == null) throw const TransactionCodeNotFoundException();
      return TransactionDetails.fromJson(row);
    } on TransactionCodeNotFoundException {
      rethrow;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('ENTER CODE SUPABASE ERROR: ${error.message}');
      debugPrint('ENTER CODE SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const TransactionLookupException(
        'Unable to search transactions. Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('ENTER CODE ERROR: $error');
      debugPrint('$stackTrace');
      throw const TransactionLookupException(
        'Unable to connect to the transaction service.',
      );
    }
  }
}
