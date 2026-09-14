import 'package:flutter/material.dart';

import '../../functions/returns/load_return_transaction_function.dart';
import '../../functions/returns/partial_return_function.dart';
import '../../functions/returns/return_item_function.dart';
import '../../functions/returns/verify_return_function.dart';
import '../../functions/transactions/transaction_details_function.dart';
import '../../services/supabase_service.dart';
import 'modal_helper.dart';
import 'success_modal.dart';

Future<bool> showReturnItemsModal(
  BuildContext context, {
  Object? transactionId,
  String? transactionCode,
}) async {
  final result = await showWarehouseModal<ReturnProcessResult>(
    context: context,
    maxWidth: 820,
    barrierDismissible: false,
    builder: (_) => _ReturnItemsModal(
      transactionId: transactionId,
      transactionCode: transactionCode,
    ),
  );
  if (result == null || !context.mounted) return false;
  await showSuccessModal(
    context,
    message: PartialReturnFunction.successMessage(result.transactionStatus),
  );
  return true;
}

class _ReturnItemsModal extends StatefulWidget {
  const _ReturnItemsModal({this.transactionId, this.transactionCode});
  final Object? transactionId;
  final String? transactionCode;
  @override
  State<_ReturnItemsModal> createState() => _ReturnItemsModalState();
}

class _ReturnItemsModalState extends State<_ReturnItemsModal> {
  final _note = TextEditingController();
  final _quantities = <String, int>{};
  late Future<TransactionDetails> _transaction;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _transaction = LoadReturnTransactionFunction.load(
      transactionId: widget.transactionId,
      transactionCode: widget.transactionCode,
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _initialize(TransactionDetails transaction) {
    for (final item in transaction.returnableItems.where(
      (i) => i.remainingQuantity > 0,
    )) {
      _quantities.putIfAbsent(item.id.toString(), () => 1);
    }
  }

  void _change(TransactionLineDetails item, int difference) {
    if (_submitting) return;
    final key = item.id.toString();
    final current = _quantities[key] ?? 0;
    final next = (current + difference).clamp(0, item.remainingQuantity);
    setState(() {
      _quantities[key] = next;
      _error = null;
    });
  }

  Future<void> _confirm(TransactionDetails transaction) async {
    if (_submitting) return;
    final items = transaction.returnableItems
        .where((i) => i.remainingQuantity > 0)
        .toList();
    final validation = VerifyReturnFunction.validate(
      items: items,
      quantities: _quantities,
    );
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ReturnItemFunction.processReturn(
        transactionId: transaction.id,
        returns: VerifyReturnFunction.selections(
          items: items,
          quantities: _quantities,
        ),
        note: _note.text,
      );
      if (mounted) Navigator.pop(context, result);
    } on ReturnProcessException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
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
        Container(
          height: 62,
          padding: const EdgeInsets.only(left: 22, right: 8),
          color: const Color(0xFF08213B),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Return Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _submitting ? null : () => Navigator.pop(context),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: FutureBuilder<TransactionDetails>(
            future: _transaction,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _LoadError(
                  error: snapshot.error!,
                  retry: () {
                    setState(
                      () => _transaction = LoadReturnTransactionFunction.load(
                        transactionId: widget.transactionId,
                        transactionCode: widget.transactionCode,
                      ),
                    );
                  },
                );
              }
              final transaction = snapshot.data!;
              _initialize(transaction);
              final items = transaction.returnableItems
                  .where((i) => i.remainingQuantity > 0)
                  .toList();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 28,
                      runSpacing: 10,
                      children: [
                        _Info('Transaction Code', transaction.transactionCode),
                        _Info('Borrower', transaction.borrowerName),
                        _Info('Contact', transaction.contactNumber),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'All tools/equipment have already been returned.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF168447),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => _ReturnCard(
                          item: item,
                          quantity: _quantities[item.id.toString()] ?? 0,
                          decrement: () => _change(item, -1),
                          increment: () => _change(item, 1),
                        ),
                      ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _note,
                      enabled: !_submitting,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Return Note (Optional)',
                        hintText: 'Returned in good condition.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _submitting || items.isEmpty
                              ? null
                              : () => _confirm(transaction),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5BE1),
                            minimumSize: const Size(190, 48),
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.assignment_turned_in_rounded),
                          label: const Text('CONFIRM RETURN'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({
    required this.item,
    required this.quantity,
    required this.decrement,
    required this.increment,
  });
  final TransactionLineDetails item;
  final int quantity;
  final VoidCallback decrement, increment;
  @override
  Widget build(BuildContext context) {
    final path = item.imagePath?.trim();
    final imageUrl = path == null || path.isEmpty
        ? null
        : SupabaseService.client.storage.from('item-images').getPublicUrl(path);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final identity = Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageUrl == null
                      ? const _Fallback()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _Fallback(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    Text(
                      '${item.itemTypeLabel} • ${item.unit}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final details = Wrap(
            spacing: 16,
            runSpacing: 7,
            children: [
              _Metric('Borrowed', '${item.quantity} ${item.unit}'),
              _Metric(
                'Already Returned',
                '${item.returnedQuantity} ${item.unit}',
              ),
              _Metric('Remaining', '${item.remainingQuantity} ${item.unit}'),
              _Metric('Expected Return', _date(item.expectedReturnAt)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Return Now: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: decrement,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: increment,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ],
          );
          return constraints.maxWidth < 650
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [identity, const SizedBox(height: 11), details],
                )
              : Row(
                  children: [
                    SizedBox(width: 260, child: identity),
                    const SizedBox(width: 16),
                    Expanded(child: details),
                  ],
                );
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF172033),
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8F0FF),
    child: Center(
      child: Icon(Icons.handyman_outlined, color: Color(0xFF0D5BE1), size: 30),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            error is LoadReturnTransactionException
                ? (error as LoadReturnTransactionException).message
                : 'Unable to load return details.',
          ),
          TextButton(onPressed: retry, child: const Text('TRY AGAIN')),
        ],
      ),
    ),
  );
}

String _date(DateTime? value) {
  if (value == null) return 'Not set';
  final date = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
}
