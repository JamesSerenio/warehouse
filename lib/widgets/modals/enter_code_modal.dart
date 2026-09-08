import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/transactions/enter_code_function.dart';
import '../../functions/transactions/transaction_details_function.dart';
import 'modal_helper.dart';
import 'transaction_details_modal.dart';

Future<void> showEnterCodeModal(BuildContext context) async {
  final transaction = await showWarehouseModal<TransactionDetails>(
    context: context,
    maxWidth: 470,
    builder: (_) => const _EnterCodeModal(),
  );
  if (transaction == null || !context.mounted) return;
  await showTransactionDetailsModal(context, transaction: transaction);
}

class _EnterCodeModal extends StatefulWidget {
  const _EnterCodeModal();

  @override
  State<_EnterCodeModal> createState() => _EnterCodeModalState();
}

class _EnterCodeModalState extends State<_EnterCodeModal> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_isSearching) return;
    final code = _controller.text.trim().toUpperCase();
    final validation = EnterCodeFunction.validateCode(code);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final transaction = await EnterCodeFunction.findTransaction(code);
      if (!mounted) return;
      Navigator.of(context).pop(transaction);
    } on TransactionCodeNotFoundException {
      if (mounted) setState(() => _error = 'Transaction code not found.');
    } on TransactionLookupException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error, stackTrace) {
      debugPrint('ENTER CODE MODAL ERROR: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() => _error = 'Unable to search. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

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
                    'Enter Transaction Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _isSearching ? null : () => Navigator.pop(context),
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
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !_isSearching,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [_UpperCaseFormatter()],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 18,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'A7K2',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      letterSpacing: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(
                        color: _error == null
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF0D5BE1),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSearching ? null : _search,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5BE1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _isSearching
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
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
