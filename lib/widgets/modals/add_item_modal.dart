import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/inventory/add_item_function.dart';
import 'modal_helper.dart';
import 'success_modal.dart';
import 'warning_modal.dart';

Future<void> showAddItemModal(BuildContext context) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 760,
    barrierDismissible: false,
    builder: (_) => const AddItemModal(),
  );
}

class AddItemModal extends StatefulWidget {
  const AddItemModal({super.key});

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal> {
  static const _categories = {
    'Tool': 'tool',
    'Equipment': 'equipment',
    'Material / Consumable': 'material',
  };
  static const _units = [
    'pcs',
    'set',
    'box',
    'roll',
    'bag',
    'meter',
    'kg',
    'liter',
  ];

  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _initialStockController = TextEditingController();
  final _lowStockController = TextEditingController(text: '5');
  final _noteController = TextEditingController();
  String? _category;
  String? _unit;
  bool _isSaving = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _initialStockController.dispose();
    _lowStockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  String? _wholeNumber(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    final number = int.tryParse(value);
    if (number == null) return '$field must be a whole number.';
    if (number < 0) return '$field cannot be negative.';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await AddItemFunction.addItem(
        productName: _productNameController.text,
        itemType: _categories[_category]!,
        unit: _unit!,
        initialStock: int.parse(_initialStockController.text),
        lowStockLevel: int.parse(_lowStockController.text),
        note: _noteController.text,
      );
      if (!mounted) return;
      _clearForm();
      await showSuccessModal(context, message: 'Item added successfully.');
    } on AddItemException catch (error) {
      if (!mounted) return;
      await showWarningModal(context, message: error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _productNameController.clear();
    _initialStockController.clear();
    _lowStockController.text = '5';
    _noteController.clear();
    setState(() {
      _category = null;
      _unit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 38,
            offset: Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            color: const Color(0xFF08213B),
            child: Row(
              children: [
                const Icon(
                  Icons.add_box_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add New Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  color: Colors.white,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 560;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ModalTextField(
                          label: 'Product Name *',
                          controller: _productNameController,
                          hint: 'Hammer',
                          validator: (value) =>
                              _required(value, 'Product name'),
                        ),
                        const SizedBox(height: 17),
                        _responsivePair(
                          twoColumns,
                          _ModalDropdown(
                            label: 'Category / Type *',
                            value: _category,
                            items: _categories.keys.toList(),
                            onChanged: (value) =>
                                setState(() => _category = value),
                          ),
                          _ModalDropdown(
                            label: 'Unit *',
                            value: _unit,
                            items: _units,
                            onChanged: (value) => setState(() => _unit = value),
                          ),
                        ),
                        const SizedBox(height: 17),
                        _responsivePair(
                          twoColumns,
                          _ModalTextField(
                            label: 'Initial Stock / Quantity *',
                            controller: _initialStockController,
                            hint: '10',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) =>
                                _wholeNumber(value, 'Initial stock'),
                          ),
                          _ModalTextField(
                            label: 'Low Stock Alert Level *',
                            controller: _lowStockController,
                            hint: '5',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) =>
                                _wholeNumber(value, 'Low stock level'),
                          ),
                        ),
                        const SizedBox(height: 17),
                        _ModalTextField(
                          label: 'Note',
                          controller: _noteController,
                          hint: 'Claw hammer with rubber handle',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF334155),
                                    side: const BorderSide(
                                      color: Color(0xFFD8DEE8),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                  child: const Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _save,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D5BE1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'SAVE ITEM',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsivePair(bool twoColumns, Widget first, Widget second) {
    if (!twoColumns) {
      return Column(children: [first, const SizedBox(height: 17), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 18),
        Expanded(child: second),
      ],
    );
  }
}

class _ModalDropdown extends StatelessWidget {
  const _ModalDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _FieldShell(
    label: label,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _decoration('Select an option'),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select an option.' : null,
    ),
  );
}

class _ModalTextField extends StatelessWidget {
  const _ModalTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) => _FieldShell(
    label: label,
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: _decoration(hint),
    ),
  );
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF172033),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

InputDecoration _decoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9AAABD)),
  filled: true,
  fillColor: const Color(0xFFF9FBFD),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFD8E2EC)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFD8E2EC)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFF0D5BE1), width: 2),
  ),
);
