import 'package:flutter/material.dart';

import '../../functions/inventory/delete_item_function.dart';
import '../../functions/inventory/inventory_list_function.dart';
import 'modal_helper.dart';

Future<bool> showDeleteItemConfirmationModal(
  BuildContext context,
  WarehouseItem item,
) async {
  return await showWarehouseModal<bool>(
        context: context,
        maxWidth: 430,
        barrierDismissible: false,
        builder: (_) => _DeleteItemModal(item: item),
      ) ??
      false;
}

class _DeleteItemModal extends StatefulWidget {
  const _DeleteItemModal({required this.item});
  final WarehouseItem item;
  @override
  State<_DeleteItemModal> createState() => _DeleteItemModalState();
}

class _DeleteItemModalState extends State<_DeleteItemModal> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await DeleteItemFunction.archiveItem(widget.item);
      if (mounted) {
        Navigator.ofgst(context).pop(true);
      }
    } on DeleteItemException catch (error) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 32,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 38,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Delete this item?',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '"${widget.item.productName}" will be removed from the inventory.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 6),
        const Text(
          'This action cannot be undone.',
          style: TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _deleting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _deleting ? null : _delete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                child: _deleting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('DELETE'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
