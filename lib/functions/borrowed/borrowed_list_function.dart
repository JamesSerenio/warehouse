import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../transactions/transaction_details_function.dart';

class BorrowedListException implements Exception {
  const BorrowedListException(this.message);
  final String message;
}

enum BorrowedStatus { active, partialReturn, overdue, returned }

class BorrowedTransaction {
  const BorrowedTransaction({required this.details, required this.items});
  final TransactionDetails details;
  final List<TransactionLineDetails> items;

  Object get id => details.id;
  String get transactionCode => details.transactionCode;
  String get borrowerName => details.borrowerName;
  String get contactNumber => details.contactNumber;

  BorrowedStatus get status {
    if (items.every((item) => item.remainingQuantity == 0)) {
      return BorrowedStatus.returned;
    }
    if (items.any((item) => item.isOverdue)) return BorrowedStatus.overdue;
    if (items.any(
      (item) => item.returnedQuantity > 0 && item.remainingQuantity > 0,
    )) {
      return BorrowedStatus.partialReturn;
    }
    return BorrowedStatus.active;
  }

  DateTime? get soonestDueDate {
    final dates =
        items
            .where((item) => item.remainingQuantity > 0)
            .map((item) => item.expectedReturnAt)
            .whereType<DateTime>()
            .toList(growable: false)
          ..sort();
    return dates.isEmpty ? null : dates.first;
  }
}

abstract final class BorrowedListFunction {
  static const query =
      'id, transaction_code, borrower_name, contact_number, note, status, created_at, signature_path, '
      'transaction_items(id, item_id, quantity, returned_quantity, expected_return_at, status, '
      'items(id, product_name, item_type, unit, image_path))';

  static Future<List<BorrowedTransaction>> load() async {
    try {
      final rows = await SupabaseService.client
          .from('transactions')
          .select(query)
          .order('created_at', ascending: false);
      final transactions = rows
          .map(TransactionDetails.fromJson)
          .map(
            (details) => BorrowedTransaction(
              details: details,
              items: details.returnableItems,
            ),
          )
          .where((transaction) => transaction.items.isNotEmpty)
          .toList();
      transactions.sort(_compare);
      return List.unmodifiable(transactions);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('BORROWED LIST SUPABASE ERROR: ${error.message}');
      debugPrint('BORROWED LIST SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const BorrowedListException('Unable to load borrowed items.');
    } catch (error, stackTrace) {
      debugPrint('BORROWED LIST ERROR: $error');
      debugPrint('$stackTrace');
      throw const BorrowedListException(
        'Unable to connect. Check your internet connection.',
      );
    }
  }

  static int _compare(BorrowedTransaction a, BorrowedTransaction b) {
    final rank = _rank(a.status).compareTo(_rank(b.status));
    if (rank != 0) return rank;
    final aDue = a.soonestDueDate;
    final bDue = b.soonestDueDate;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  static int _rank(BorrowedStatus status) => switch (status) {
    BorrowedStatus.overdue => 0,
    BorrowedStatus.partialReturn || BorrowedStatus.active => 1,
    BorrowedStatus.returned => 2,
  };
}
