import 'borrowed_list_function.dart';

abstract final class BorrowedSearchFunction {
  static List<BorrowedTransaction> apply(
    List<BorrowedTransaction> transactions,
    String query,
  ) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return transactions;
    return transactions.where((transaction) {
      return transaction.transactionCode.toLowerCase().contains(value) ||
          transaction.borrowerName.toLowerCase().contains(value) ||
          transaction.contactNumber.toLowerCase().contains(value) ||
          transaction.items.any(
            (item) => item.productName.toLowerCase().contains(value),
          );
    }).toList(growable: false);
  }
}
