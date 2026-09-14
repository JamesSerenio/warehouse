import '../transactions/transaction_details_function.dart';

abstract final class SearchPendingReturnsFunction {
  static List<TransactionDetails> apply(
    List<TransactionDetails> transactions,
    String query,
  ) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return transactions;
    return transactions
        .where((transaction) {
          return transaction.borrowerName.toLowerCase().contains(term) ||
              transaction.contactNumber.toLowerCase().contains(term) ||
              transaction.transactionCode.toLowerCase().contains(term) ||
              transaction.returnableItems.any(
                (item) => item.productName.toLowerCase().contains(term),
              );
        })
        .toList(growable: false);
  }
}
