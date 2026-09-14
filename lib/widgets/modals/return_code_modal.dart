import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/returns/load_return_transaction_function.dart';
import '../../functions/transactions/enter_code_function.dart';
import '../../functions/transactions/transaction_details_function.dart';
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
  bool _loading = false;
  String? _error;

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

  Future<void> _search() async {
    if (_loading) return;
    final code = _controller.text.trim().toUpperCase();
    final validation = EnterCodeFunction.validateCode(code);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await LoadReturnTransactionFunction.load(
        transactionCode: code,
      );
      if (!mounted) return;
      if (!result.hasRemainingReturnableItems) {
        setState(
          () => _error = 'All tools/equipment have already been returned.',
        );
        return;
      }
      Navigator.pop(context, result);
    } on ReturnTransactionNotFoundException {
      if (mounted) setState(() => _error = 'Transaction code not found.');
    } on LoadReturnTransactionException catch (error) {
      if (mounted) setState(() => _error = error.message);
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
                'Enter the 4-character transaction code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: !_loading,
                maxLength: 4,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  _UpperCaseFormatter(),
                ],
                onSubmitted: (_) => _search(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 18,
                  color: Color(0xFF172033),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'A7K2',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    letterSpacing: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                      color: _error == null
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
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
                  onPressed: _loading ? null : _search,
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
                          'SEARCH',
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

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
    composing: TextRange.empty,
  );
}
