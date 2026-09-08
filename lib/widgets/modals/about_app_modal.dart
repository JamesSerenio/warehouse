import 'package:flutter/material.dart';

import 'modal_helper.dart';

Future<void> showAboutAppModal(BuildContext context) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 460,
    builder: (_) => const _AboutAppModal(),
  );
}

class _AboutAppModal extends StatelessWidget {
  const _AboutAppModal();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 32,
          offset: Offset(0, 16),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.only(left: 22, right: 8),
          color: const Color(0xFF08213B),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'About App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.warehouse_outlined,
                  color: Color(0xFF0D5BE1),
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'WAREHOUSE',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Borrow & Inventory System',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A warehouse inventory system for managing tools, equipment, '
                'materials, borrowing, returns, stock movements, and reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5BE1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
