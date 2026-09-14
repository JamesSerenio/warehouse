import 'package:flutter/material.dart';

import 'modal_helper.dart';

enum TransactionSuccessAction { viewTransaction, done }

Future<TransactionSuccessAction?> showTransactionSuccessModal(
  BuildContext context, {
  required String transactionCode,
}) {
  return showWarehouseModal<TransactionSuccessAction>(
    context: context,
    maxWidth: 450,
    barrierDismissible: false,
    builder: (_) => _TransactionSuccessModal(transactionCode: transactionCode),
  );
}

class _TransactionSuccessModal extends StatelessWidget {
  const _TransactionSuccessModal({required this.transactionCode});
  final String transactionCode;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 32,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFF239B56),
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Transaction Recorded Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Transaction Code',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFF86D19F)),
          ),
          child: Text(
            transactionCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF168447),
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please keep this code for returning items.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(
                  context,
                  TransactionSuccessAction.viewTransaction,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('VIEW TRANSACTION'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, TransactionSuccessAction.done),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5BE1),
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
