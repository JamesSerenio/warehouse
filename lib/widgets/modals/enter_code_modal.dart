import 'package:flutter/material.dart';

import '../../functions/transactions/enter_code_function.dart';
import '../../functions/transactions/transaction_details_function.dart';
import '../transaction_code_input.dart';
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

  Future<void> _viewTransaction() async {
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
      final transaction = await EnterCodeFunction.findTransaction(code);
      if (mounted) Navigator.pop(context, transaction);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _CodeModalShell(
    title: 'Enter Transaction Code',
    instruction: 'Enter the transaction code to view transaction details.',
    buttonLabel: 'VIEW TRANSACTION',
    controller: _controller,
    focusNode: _focus,
    error: _error,
    loading: _loading,
    submit: _viewTransaction,
    clearError: (_) {
      if (_error != null) setState(() => _error = null);
    },
  );
}

class _CodeModalShell extends StatelessWidget {
  const _CodeModalShell({
    required this.title,
    required this.instruction,
    required this.buttonLabel,
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.loading,
    required this.submit,
    required this.clearError,
  });
  final String title, instruction, buttonLabel;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final bool loading;
  final VoidCallback submit;
  final ValueChanged<String> clearError;

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: loading ? null : () => Navigator.pop(context),
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
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 22),
              TransactionCodeInput(
                controller: controller,
                focusNode: focusNode,
                enabled: !loading,
                hasError: error != null,
                onChanged: clearError,
                onSubmitted: (_) => submit(),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
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
                  onPressed: loading ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5BE1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          buttonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
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
