import '../transactions/transaction_details_function.dart';

class ReturnSelection {
  const ReturnSelection({
    required this.transactionItemId,
    required this.quantity,
  });
  final Object transactionItemId;
  final int quantity;
  Map<String, dynamic> toJson() => {
    'transaction_item_id': transactionItemId,
    'quantity': quantity,
  };
}

abstract final class VerifyReturnFunction {
  static String? validate({
    required List<TransactionLineDetails> items,
    required Map<String, int> quantities,
  }) {
    var hasReturn = false;
    for (final item in items) {
      final quantity = quantities[item.id.toString()] ?? 0;
      if (quantity < 0) return 'Return quantity cannot be negative.';
      if (quantity > item.remainingQuantity) {
        return 'Only ${item.remainingQuantity} item(s) remain to be returned.';
      }
      hasReturn = hasReturn || quantity > 0;
    }
    return hasReturn ? null : 'Select at least one item to return.';
  }

  static List<ReturnSelection> selections({
    required List<TransactionLineDetails> items,
    required Map<String, int> quantities,
  }) => items
      .map(
        (item) => ReturnSelection(
          transactionItemId: item.id,
          quantity: quantities[item.id.toString()] ?? 0,
        ),
      )
      .where((selection) => selection.quantity > 0)
      .toList(growable: false);
}
