import 'package:flutter/material.dart';

import '../../functions/transactions/transaction_details_function.dart';
import 'modal_helper.dart';
import 'return_items_modal.dart';

Future<void> showTransactionDetailsModal(
  BuildContext context, {
  required TransactionDetails transaction,
}) async {
  final openReturn = await showWarehouseModal<bool>(
    context: context,
    maxWidth: 880,
    builder: (_) => _TransactionDetailsModal(transaction: transaction),
  );
  if (openReturn != true || !context.mounted) return;
  await showReturnItemsModal(
    context,
    transactionId: transaction.id,
    transactionCode: transaction.transactionCode,
  );
}

class _TransactionDetailsModal extends StatelessWidget {
  const _TransactionDetailsModal({required this.transaction});
  final TransactionDetails transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Header(onClose: () => Navigator.pop(context)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 26,
                    runSpacing: 12,
                    children: [
                      _Detail(
                        label: 'Transaction Code',
                        value: transaction.transactionCode,
                      ),
                      _StatusBadge(status: transaction.status),
                      _Detail(
                        label: 'Borrower',
                        value: transaction.borrowerName,
                      ),
                      _Detail(
                        label: 'Contact',
                        value: transaction.contactNumber,
                      ),
                      _Detail(
                        label: 'Borrowed Date',
                        value: _dateTime(transaction.createdAt),
                      ),
                    ],
                  ),
                  if (transaction.note != null &&
                      transaction.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Detail(label: 'Note', value: transaction.note!),
                  ],
                  if (transaction.returnableItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Tools / Equipment'),
                    const SizedBox(height: 10),
                    ...transaction.returnableItems.map(_ReturnableItem.new),
                  ],
                  if (transaction.materialItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      'Materials / Consumables (No return required)',
                    ),
                    const SizedBox(height: 10),
                    ...transaction.materialItems.map(_MaterialItem.new),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle("Borrower's Signature"),
                  const SizedBox(height: 10),
                  _SignatureView(path: transaction.signaturePath),
                  const SizedBox(height: 22),
                  if (transaction.hasRemainingReturnableItems)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Future<void>.delayed(
                            const Duration(milliseconds: 280),
                          );
                          if (!context.mounted) return;
                          await showReturnItemsModal(
                            context,
                            transactionId: transaction.id,
                            transactionCode: transaction.transactionCode,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5BE1),
                          minimumSize: const Size(190, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: const Icon(Icons.assignment_return_rounded),
                        label: const Text('RETURN ITEMS'),
                      ),
                    )
                  else if (transaction.returnableItems.isNotEmpty)
                    const Text(
                      'All tools/equipment have been returned.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF168447),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnableItem extends StatelessWidget {
  const _ReturnableItem(this.item);
  final TransactionLineDetails item;

  @override
  Widget build(BuildContext context) {
    final overdue = item.isOverdue;
    final status = overdue
        ? 'OVERDUE'
        : item.remainingQuantity == 0
        ? 'COMPLETED'
        : item.returnedQuantity > 0
        ? 'PARTIAL'
        : item.status.toUpperCase();
    return _ItemCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _ItemIdentity(item: item)),
          Expanded(
            child: _Value(label: 'Borrowed', value: '${item.quantity}'),
          ),
          Expanded(
            child: _Value(label: 'Returned', value: '${item.returnedQuantity}'),
          ),
          Expanded(
            child: _Value(
              label: 'Remaining',
              value: '${item.remainingQuantity}',
            ),
          ),
          Expanded(
            flex: 2,
            child: _Value(
              label: 'Expected Return',
              value: _dateTime(item.expectedReturnAt),
            ),
          ),
          _SmallStatus(label: status, danger: overdue),
        ],
      ),
    );
  }
}

class _MaterialItem extends StatelessWidget {
  const _MaterialItem(this.item);
  final TransactionLineDetails item;

  @override
  Widget build(BuildContext context) => _ItemCard(
    child: Row(
      children: [
        Expanded(child: _ItemIdentity(item: item)),
        Text(
          'Issued: ${item.quantity} ${item.unit}',
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          'No return required',
          style: TextStyle(
            color: Color(0xFF168447),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SignatureView extends StatelessWidget {
  const _SignatureView({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) {
      return const _SignatureBox(
        child: Text(
          'No signature available.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    return FutureBuilder<String?>(
      future: TransactionDetailsFunction.createSignatureUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SignatureBox(
            child: CircularProgressIndicator(strokeWidth: 2.4),
          );
        }
        if (snapshot.data == null) {
          return const _SignatureBox(
            child: Text(
              'Unable to load signature.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        return _SignatureBox(
          child: Image.network(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Text('Unable to load signature.'),
          ),
        );
      },
    );
  }
}

class _SignatureBox extends StatelessWidget {
  const _SignatureBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 145,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFDCE5EF)),
    ),
    child: child,
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: child,
  );
}

class _ItemIdentity extends StatelessWidget {
  const _ItemIdentity({required this.item});
  final TransactionLineDetails item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.productName,
        style: const TextStyle(
          color: Color(0xFF172033),
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        item.itemTypeLabel,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      ),
    ],
  );
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF172033),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 185,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'completed'
        ? const Color(0xFF168447)
        : normalized == 'overdue'
        ? const Color(0xFFDC2626)
        : normalized.contains('partial')
        ? const Color(0xFFEA7600)
        : const Color(0xFF0D5BE1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallStatus extends StatelessWidget {
  const _SmallStatus({required this.label, required this.danger});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: (danger ? const Color(0xFFDC2626) : const Color(0xFF0D5BE1))
          .withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: danger ? const Color(0xFFDC2626) : const Color(0xFF0D5BE1),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    padding: const EdgeInsets.only(left: 22, right: 8),
    color: const Color(0xFF08213B),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Transaction Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          color: Colors.white,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF172033),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Not available';
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.month}/${local.day}/${local.year}  $hour:$minute $period';
}
