import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import 'verify_return_function.dart';

class ReturnProcessException implements Exception {
  const ReturnProcessException(this.message);
  final String message;
}

class ReturnProcessResult {
  const ReturnProcessResult({
    required this.transactionStatus,
    required this.returnedQuantity,
  });
  final String transactionStatus;
  final int returnedQuantity;
  bool get isComplete => transactionStatus == 'completed';

  factory ReturnProcessResult.fromJson(Map<String, dynamic> json) =>
      ReturnProcessResult(
        transactionStatus:
            json['transaction_status']?.toString() ?? 'partial_return',
        returnedQuantity: (json['returned_quantity'] as num?)?.toInt() ?? 0,
      );
}

abstract final class ReturnItemFunction {
  static Future<ReturnProcessResult> processReturn({
    required Object transactionId,
    required List<ReturnSelection> returns,
    String? note,
  }) async {
    try {
      final response = await SupabaseService.client.rpc(
        'process_item_return',
        params: {
          'p_transaction_id': transactionId,
          'p_returns': returns
              .map((value) => value.toJson())
              .toList(growable: false),
          'p_note': note?.trim().isEmpty == true ? null : note?.trim(),
        },
      );
      return ReturnProcessResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('PROCESS RETURN SUPABASE ERROR: ${error.message}');
      debugPrint('PROCESS RETURN SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw ReturnProcessException(_friendly(error.message));
    } catch (error, stackTrace) {
      if (error is ReturnProcessException) rethrow;
      debugPrint('PROCESS RETURN ERROR: $error');
      debugPrint('$stackTrace');
      throw const ReturnProcessException(
        'Unable to process the return. Please try again.',
      );
    }
  }
}

String _friendly(String message) {
  const known = [
    'Transaction not found.',
    'No return items were selected.',
    'Only ',
    'Materials cannot be returned.',
    'Borrowed stock is inconsistent.',
  ];
  if (known.any(message.startsWith)) return message;
  return 'Unable to process the return. Please try again.';
}
