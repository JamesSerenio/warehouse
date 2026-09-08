import 'package:flutter/material.dart';

import 'modal_helper.dart';

Future<void> showReturnItemsModal(
  BuildContext context, {
  required Object transactionId,
  required String transactionCode,
}) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 480,
    builder: (_) => _ReturnItemsModal(
      transactionId: transactionId,
      transactionCode: transactionCode,
    ),
  );
}

class _ReturnItemsModal extends StatelessWidget {
  const _ReturnItemsModal({
    required this.transactionId,
    required this.transactionCode,
  });
  final Object transactionId;
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
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFE8F0FF),
          child: Icon(
            Icons.assignment_return_rounded,
            color: Color(0xFF0D5BE1),
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Return Items',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Transaction $transactionCode',
          style: const TextStyle(
            color: Color(0xFF0D5BE1),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The return-processing form will use this transaction directly. Return stock updates are not enabled until the transaction database setup is completed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D5BE1),
            ),
            child: const Text('CLOSE'),
          ),
        ),
      ],
    ),
  );
}
