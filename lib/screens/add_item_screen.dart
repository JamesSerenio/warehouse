import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../functions/inventory/add_item_function.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
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

  String? _requiredText(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  String? _validateNonNegativeInteger(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    final number = int.tryParse(value);
    if (number == null) return '$field must be a whole number.';
    if (number < 0) return '$field cannot be negative.';
    return null;
  }

  Future<void> _saveItem() async {
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
      _formKey.currentState!.reset();
      _productNameController.clear();
      _initialStockController.clear();
      _lowStockController.text = '5';
      _noteController.clear();
      setState(() {
        _category = null;
        _unit = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully.'),
          backgroundColor: Color(0xFF239B56),
        ),
      );
    } on AddItemException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Add New Item'),
        backgroundColor: const Color(0xFF08213B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE3EAF2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 600;
                      final categoryField = _DropdownField(
                        label: 'Category / Type *',
                        value: _category,
                        items: _categories.keys.toList(),
                        onChanged: (value) => setState(() => _category = value),
                      );
                      final unitField = _DropdownField(
                        label: 'Unit *',
                        value: _unit,
                        items: _units,
                        onChanged: (value) => setState(() => _unit = value),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Information',
                            style: TextStyle(
                              color: Color(0xFF172033),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LabeledTextField(
                            label: 'Product Name *',
                            controller: _productNameController,
                            hint: 'Hammer',
                            validator: (value) =>
                                _requiredText(value, 'Product name'),
                          ),
                          const SizedBox(height: 18),
                          if (twoColumns)
                            Row(
                              children: [
                                Expanded(child: categoryField),
                                const SizedBox(width: 18),
                                Expanded(child: unitField),
                              ],
                            )
                          else
                            Column(
                              children: [
                                categoryField,
                                const SizedBox(height: 18),
                                unitField,
                              ],
                            ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _LabeledTextField(
                                  label: 'Initial Stock / Quantity *',
                                  controller: _initialStockController,
                                  hint: '10',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) =>
                                      _validateNonNegativeInteger(
                                        value,
                                        'Initial stock',
                                      ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _LabeledTextField(
                                  label: 'Low Stock Alert Level *',
                                  controller: _lowStockController,
                                  hint: '5',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) =>
                                      _validateNonNegativeInteger(
                                        value,
                                        'Low stock level',
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _LabeledTextField(
                            label: 'Note',
                            controller: _noteController,
                            hint: 'Claw hammer with rubber handle',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: _isSaving ? null : _saveItem,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0D5BE1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
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
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
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
      DropdownButtonFormField<String>(
        initialValue: value,
        decoration: _inputDecoration('Select an option'),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select an option.' : null,
      ),
    ],
  );
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
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
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: _inputDecoration(hint),
      ),
    ],
  );
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
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
