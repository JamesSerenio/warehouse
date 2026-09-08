import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/inventory/inventory_list_function.dart';
import '../../functions/stock/add_stock_function.dart';
import 'modal_helper.dart';

Future<bool> showAddStockModal(BuildContext context, WarehouseItem item) async {
  return await showWarehouseModal<bool>(
        context: context,
        maxWidth: 540,
        barrierDismissible: false,
        builder: (_) => _AddStockModal(item: item),
      ) ??
      false;
}

class _AddStockModal extends StatefulWidget {
  const _AddStockModal({required this.item});
  final WarehouseItem item;

  @override
  State<_AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends State<_AddStockModal> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _dateReceived = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateReceived,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateReceived = date);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AddStockFunction.addStock(
        item: widget.item,
        quantity: int.parse(_quantityController.text),
        dateReceived: _dateReceived,
        note: _noteController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AddStockException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _Frame(
    title: 'Add Stock',
    canClose: !_saving,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReadOnlyValue(label: 'Product', value: widget.item.productName),
            const SizedBox(height: 16),
            _ReadOnlyValue(
              label: 'Current Stock',
              value: '${widget.item.totalStock} ${widget.item.unit}',
            ),
            const SizedBox(height: 16),
            _Label('Quantity to Add *'),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _input('0'),
              validator: (value) {
                final quantity = int.tryParse(value ?? '');
                return quantity == null || quantity <= 0
                    ? 'Enter a quantity greater than zero.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            _Label('Date Received *'),
            InkWell(
              onTap: _saving ? null : _pickDate,
              borderRadius: BorderRadius.circular(9),
              child: InputDecorator(
                decoration: _input(''),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Text(_formatDate(_dateReceived)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Note'),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: _input('Optional note'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5BE1),
                    ),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('CONFIRM ADD STOCK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.child,
    required this.canClose,
  });
  final String title;
  final Widget child;
  final bool canClose;
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
                onPressed: canClose
                    ? () => Navigator.of(context).pop(false)
                    : null,
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(child: child),
      ],
    ),
  );
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label(label),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF172033),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

InputDecoration _input(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: const Color(0xFFF9FBFD),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFD8E2EC)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFD8E2EC)),
  ),
);

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
