import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../transactions/transaction_details_function.dart';

class LoadPendingReturnsException implements Exception {
  const LoadPendingReturnsException(this.message);
  final String message;
}

abstract final class LoadPendingReturnsFunction {
  static const query =
      'id, transaction_code, borrower_name, contact_number, note, status, created_at, signature_path, '
      'transaction_items(id, item_id, quantity, returned_quantity, expected_return_at, status, '
      'items(id, product_name, item_type, unit, image_path))';

  static Future<List<TransactionDetails>> load() async {
    try {
      final rows = await SupabaseService.client
          .from('transactions')
          .select(query);
      final pending = rows
          .map(TransactionDetails.fromJson)
          .where((transaction) => transaction.hasRemainingReturnableItems)
          .toList(growable: false);
      return [...pending]..sort(_compare);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('PENDING RETURNS SUPABASE ERROR: ${error.message}');
      debugPrint('PENDING RETURNS SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const LoadPendingReturnsException(
        'Unable to load pending returns. Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('PENDING RETURNS ERROR: $error');
      debugPrint('$stackTrace');
      throw const LoadPendingReturnsException(
        'Unable to connect to the return service.',
      );
    }
  }

  static int _compare(TransactionDetails a, TransactionDetails b) {
    final priority = _priority(a).compareTo(_priority(b));
    if (priority != 0) return priority;
    final aDue = _soonestDue(a);
    final bDue = _soonestDue(b);
    if (aDue == null && bDue == null) {
      return a.transactionCode.compareTo(b.transactionCode);
    }
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  static int _priority(TransactionDetails transaction) {
    final items = transaction.returnableItems.where(
      (item) => item.remainingQuantity > 0,
    );
    if (items.any((item) => item.isOverdue)) return 0;
    if (items.any((item) => _isToday(item.expectedReturnAt))) return 1;
    return 2;
  }

  static DateTime? _soonestDue(TransactionDetails transaction) {
    final dates = transaction.returnableItems
        .where((item) => item.remainingQuantity > 0)
        .map((item) => item.expectedReturnAt)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }
}

bool isPendingReturnDueToday(DateTime? value, {DateTime? now}) {
  if (value == null) return false;
  final today = now ?? DateTime.now();
  final local = value.toLocal();
  return local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
}

bool _isToday(DateTime? value) => isPendingReturnDueToday(value);
