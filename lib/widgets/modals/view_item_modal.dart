import 'package:flutter/material.dart';

import '../../functions/inventory/inventory_list_function.dart';
import 'add_stock_modal.dart';
import 'delete_item_confirmation_modal.dart';
import 'edit_item_modal.dart';
import 'modal_helper.dart';

Future<bool> showViewItemModal(BuildContext context, WarehouseItem item) async {
  return await showWarehouseModal<bool>(
        context: context,
        maxWidth: 720,
        builder: (_) => _ViewItemModal(item: item),
      ) ??
      false;
}

class _ViewItemModal extends StatefulWidget {
  const _ViewItemModal({required this.item});
  final WarehouseItem item;
  @override
  State<_ViewItemModal> createState() => _ViewItemModalState();
}

class _ViewItemModalState extends State<_ViewItemModal> {
  late WarehouseItem _item = widget.item;
  bool _changed = false;
  bool _refreshing = false;
  String? _error;

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final item = await InventoryListFunction.loadItem(_item.id);
      if (mounted)
        setState(() {
          _item = item;
          _refreshing = false;
        });
    } on InventoryListException catch (error) {
      if (mounted)
        setState(() {
          _refreshing = false;
          _error = error.message;
        });
    }
  }

  Future<void> _edit() async {
    if (await showEditItemModal(context, _item)) {
      _changed = true;
      await _refresh();
    }
  }

  Future<void> _addStock() async {
    if (await showAddStockModal(context, _item)) {
      _changed = true;
      await _refresh();
    }
  }

  Future<void> _delete() async {
    if (_item.borrowedStock > 0) {
      setState(
        () => _error =
            'Cannot delete this item because ${_item.borrowedStock} unit(s) are currently borrowed.',
      );
      return;
    }
    if (await showDeleteItemConfirmationModal(context, _item) && mounted)
      Navigator.of(context).pop(true);
  }

  void _close() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) => Container(
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
                  'Item Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _close,
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_refreshing) const LinearProgressIndicator(minHeight: 2),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 540;
                    final image = ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: compact ? double.infinity : 210,
                        height: 160,
                        child: _item.imageUrl == null
                            ? const _ImageFallback()
                            : Image.network(
                                _item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const _ImageFallback(),
                              ),
                      ),
                    );
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item.productName,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_item.typeLabel}  •  ${_item.unit}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StockChip(
                              label: 'Total',
                              value: _item.totalStock,
                              color: const Color(0xFF0D5BE1),
                            ),
                            _StockChip(
                              label: 'Available',
                              value: _item.availableStock,
                              color: const Color(0xFF168447),
                            ),
                            _StockChip(
                              label: 'Borrowed',
                              value: _item.borrowedStock,
                              color: const Color(0xFFDC5B13),
                            ),
                          ],
                        ),
                      ],
                    );
                    return compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              image,
                              const SizedBox(height: 18),
                              details,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              image,
                              const SizedBox(width: 22),
                              Expanded(child: details),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 22),
                const Divider(),
                _DetailRow(
                  label: 'Low Stock Alert Level',
                  value: '${_item.lowStockLevel} ${_item.unit}',
                ),
                _DetailRow(
                  label: 'Note',
                  value: _item.note?.trim().isNotEmpty == true
                      ? _item.note!
                      : '—',
                ),
                _DetailRow(
                  label: 'Created Date',
                  value: _date(_item.createdAt),
                ),
                _DetailRow(
                  label: 'Updated Date',
                  value: _date(_item.updatedAt),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _refreshing ? null : _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('EDIT ITEM'),
                    ),
                    FilledButton.icon(
                      onPressed: _refreshing ? null : _addStock,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5BE1),
                      ),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('ADD STOCK'),
                    ),
                    FilledButton.icon(
                      onPressed: _refreshing ? null : _delete,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('DELETE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8F0FF),
    child: Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 60,
        color: Color(0xFF0D5BE1),
      ),
    ),
  );
}

class _StockChip extends StatelessWidget {
  const _StockChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

String _date(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
