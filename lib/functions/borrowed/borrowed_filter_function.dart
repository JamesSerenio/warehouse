import 'borrowed_list_function.dart';

enum BorrowedFilter { all, active, partialReturn, overdue, returned }

abstract final class BorrowedFilterFunction {
  static List<BorrowedTransaction> apply(
    List<BorrowedTransaction> transactions,
    BorrowedFilter filter,
  ) {
    if (filter == BorrowedFilter.all) return transactions;
    return transactions.where((transaction) => switch (filter) {
          BorrowedFilter.all => true,
          BorrowedFilter.active => transaction.status == BorrowedStatus.active,
          BorrowedFilter.partialReturn =>
            transaction.status == BorrowedStatus.partialReturn,
          BorrowedFilter.overdue =>
            transaction.status == BorrowedStatus.overdue,
          BorrowedFilter.returned =>
            transaction.status == BorrowedStatus.returned,
        }).toList(growable: false);
  }
}
