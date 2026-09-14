import '../transactions/transaction_details_function.dart';
import 'load_pending_returns_function.dart';

enum PendingReturnFilter { all, active, partial, overdue, dueToday }

abstract final class FilterPendingReturnsFunction {
  static List<TransactionDetails> apply(
    List<TransactionDetails> transactions,
    PendingReturnFilter filter,
  ) => transactions
      .where((transaction) {
        final pending = transaction.returnableItems
            .where((item) => item.remainingQuantity > 0)
            .toList(growable: false);
        final overdue = pending.any((item) => item.isOverdue);
        final dueToday = pending.any(
          (item) => isPendingReturnDueToday(item.expectedReturnAt),
        );
        return switch (filter) {
          PendingReturnFilter.all => true,
          PendingReturnFilter.active => !overdue && !dueToday,
          PendingReturnFilter.partial => pending.any(
            (item) => item.returnedQuantity > 0,
          ),
          PendingReturnFilter.overdue => overdue,
          PendingReturnFilter.dueToday => dueToday,
        };
      })
      .toList(growable: false);
}
