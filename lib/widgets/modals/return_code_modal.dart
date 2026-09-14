import 'package:flutter/material.dart';

import '../../functions/returns/load_return_transaction_function.dart';
import '../../functions/transactions/transaction_details_function.dart';
import '../transaction_code_input.dart';
import 'modal_helper.dart';
import 'return_items_modal.dart';

Future<bool> showReturnCodeModal(BuildContext context) async {
  final transaction = await showWarehouseModal<TransactionDetails>(
    context: context,
    maxWidth: 470,
    builder: (_) => const _ReturnCodeModal(),
  );
  if (transaction == null || !context.mounted) return false;
  return showReturnItemsModal(
    context,
    transactionId: transaction.id,
    transactionCode: transaction.transactionCode,
  );
}

class _ReturnCodeModal extends StatefulWidget {
  const _ReturnCodeModal();
  @override
  State<_ReturnCodeModal> createState() => _ReturnCodeModalState();
}

class _ReturnCodeModalState extends State<_ReturnCodeModal> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _continueToReturn() async {
    if (_loading) return;
    final code = _controller.text.trim().toUpperCase();
    final validation = validateTransactionCode(code);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transaction = await LoadReturnTransactionFunction.load(
        transactionCode: code,
      );
      if (!mounted) return;
      if (transaction.returnableItems.isEmpty) {
        setState(
          () =>
              _error = 'This transaction has no returnable tools or equipment.',
        );
      } else if (!transaction.hasRemainingReturnableItems) {
        setState(
          () => _error =
              'All tools/equipment in this transaction have already been returned.',
        );
      } else {
        Navigator.pop(context, transaction);
      }
    } on ReturnTransactionNotFoundException {
      if (mounted) setState(() => _error = 'Transaction code not found.');
    } on LoadReturnTransactionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error, stackTrace) {
      debugPrint('RETURN CODE MODAL ERROR: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() => _error = 'Unable to search. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      mainAxisSize: MainAxisSize.min,
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
                onPressed: _loading ? null : () => Navigator.pop(context),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the transaction code for the items being returned.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 22),
              TransactionCodeInput(
                controller: _controller,
                focusNode: _focus,
                enabled: !_loading,
                hasError: _error != null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _continueToReturn(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 9),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _continueToReturn,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5BE1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CONTINUE TO RETURN',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
