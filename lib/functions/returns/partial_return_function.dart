abstract final class PartialReturnFunction {
  static bool isComplete(String transactionStatus) =>
      transactionStatus.toLowerCase() == 'completed';

  static String successMessage(String transactionStatus) =>
      isComplete(transactionStatus)
      ? 'All tools/equipment have been returned successfully.'
      : 'Partial return recorded successfully.\n\nRemaining items can be returned later using the same transaction code.';
}
