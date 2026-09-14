import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String? validateTransactionCode(String value) {
  final code = value.trim().toUpperCase();
  if (code.length < 4) return 'Enter the complete 4-character code.';
  if (!RegExp(r'^[A-Z0-9]{4}$').hasMatch(code)) {
    return 'Invalid transaction code format.';
  }
  return null;
}

class TransactionCodeInput extends StatelessWidget {
  const TransactionCodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled, hasError;
  final ValueChanged<String> onChanged, onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    maxLength: 4,
    textAlign: TextAlign.center,
    textCapitalization: TextCapitalization.characters,
    inputFormatters: [_UpperCaseFormatter()],
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    style: const TextStyle(
      color: Color(0xFF172033),
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: 18,
    ),
    decoration: InputDecoration(
      counterText: '',
      hintText: 'A7K2',
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF0D5BE1), width: 1.6),
      ),
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
