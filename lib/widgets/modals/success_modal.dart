import 'package:flutter/material.dart';

import 'modal_helper.dart';

Future<void> showSuccessModal(BuildContext context, {required String message}) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 390,
    barrierDismissible: false,
    builder: (dialogContext) => _StatusModal(
      icon: Icons.check_rounded,
      iconColor: const Color(0xFF239B56),
      iconBackground: const Color(0xFFDCFCE7),
      title: 'Success',
      message: message,
      buttonColor: const Color(0xFF0D5BE1),
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class _StatusModal extends StatelessWidget {
  const _StatusModal({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.buttonColor,
    required this.onClose,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final Color buttonColor;
  final VoidCallback onClose;

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
          child: CircleAvatar(
            radius: 36,
            backgroundColor: iconBackground,
            child: Icon(icon, color: iconColor, size: 40),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}
