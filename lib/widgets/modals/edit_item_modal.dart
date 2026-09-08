import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../functions/inventory/edit_item_function.dart';
import '../../functions/inventory/inventory_list_function.dart';
import '../../functions/inventory/upload_item_image_function.dart';
import 'modal_helper.dart';
import 'success_modal.dart';

Future<bool> showEditItemModal(BuildContext context, WarehouseItem item) async {
  return await showWarehouseModal<bool>(
        context: context,
        maxWidth: 680,
        barrierDismissible: false,
        builder: (_) => _EditItemModal(item: item),
      ) ??
      false;
}

class _EditItemModal extends StatefulWidget {
  const _EditItemModal({required this.item});
  final WarehouseItem item;
  @override
  State<_EditItemModal> createState() => _EditItemModalState();
}

class _EditItemModalState extends State<_EditItemModal> {
  static const _types = {
    'Tool': 'tool',
    'Equipment': 'equipment',
    'Material / Consumable': 'material',
  };
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _totalStock;
  late final TextEditingController _lowStock;
  late final TextEditingController _note;
  late final TextEditingController _correctionReason;
  late String _type;
  Uint8List? _newImageBytes;
  String? _newImageExtension;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.productName);
    _unit = TextEditingController(text: widget.item.unit);
    _totalStock = TextEditingController(text: '${widget.item.totalStock}');
    _lowStock = TextEditingController(text: '${widget.item.lowStockLevel}');
    _note = TextEditingController(text: widget.item.note ?? '');
    _correctionReason = TextEditingController();
    _type = widget.item.itemType;
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _totalStock.dispose();
    _lowStock.dispose();
    _note.dispose();
    _correctionReason.dispose();
    super.dispose();
  }

  bool get _stockChanged =>
      int.tryParse(_totalStock.text) != widget.item.totalStock;

  Future<void> _selectPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final extension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : '';
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        if (mounted) {
          setState(() => _error = 'Please select a JPG, PNG, or WEBP image.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) setState(() => _error = 'Image must be 5 MB or smaller.');
        return;
      }
      if (mounted) {
        setState(() {
          _newImageBytes = bytes;
          _newImageExtension = extension;
          _error = null;
        });
      }
    } on PlatformException catch (error, stackTrace) {
      debugPrint('EDIT ITEM IMAGE PICKER ERROR: ${error.message}');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(
          () => _error = 'Unable to select the image. Please try again.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('EDIT ITEM IMAGE ERROR: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(
          () => _error = 'Unable to select the image. Please try again.',
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final stockCorrected = _stockChanged;
      await EditItemFunction.updateItem(
        itemId: widget.item.id,
        productName: _name.text,
        itemType: _type,
        unit: _unit.text,
        totalStock: int.parse(_totalStock.text),
        lowStockLevel: int.parse(_lowStock.text),
        note: _note.text,
        correctionReason: stockCorrected ? _correctionReason.text : null,
      );
      if (_newImageBytes != null && _newImageExtension != null) {
        await UploadItemImageFunction.uploadItemImage(
          itemId: widget.item.id,
          bytes: _newImageBytes!,
          extension: _newImageExtension!,
        );
      }
      if (!mounted) return;
      await showSuccessModal(
        context,
        message: stockCorrected
            ? 'Item and stock quantity updated successfully.'
            : 'Item updated successfully.',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on EditItemException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    } on UploadItemImageException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    }
  }

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
                  'Edit Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).pop(false),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 150,
                            height: 110,
                            child: _newImageBytes != null
                                ? Image.memory(
                                    _newImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : widget.item.imageUrl != null
                                ? Image.network(
                                    widget.item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const _ImageFallback(),
                                  )
                                : const _ImageFallback(),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _saving ? null : _selectPhoto,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('CHANGE PHOTO'),
                        ),
                      ],
                    ),
                  ),
                  _Field(
                    label: 'Product Name *',
                    child: TextFormField(
                      controller: _name,
                      decoration: _decoration(),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _Field(
                    label: 'Category / Type *',
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: _decoration(),
                      items: [
                        for (final entry in _types.entries)
                          DropdownMenuItem(
                            value: entry.value,
                            child: Text(entry.key),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  _Field(
                    label: 'Unit *',
                    child: TextFormField(
                      controller: _unit,
                      decoration: _decoration(),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Unit is required.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _Field(
                    label: 'Total Stock / Quantity *',
                    child: TextFormField(
                      controller: _totalStock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration(),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final stock = int.tryParse(value ?? '');
                        if (stock == null) return 'Enter a whole number.';
                        if (stock < 0) return 'Total stock cannot be negative.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StockSnapshot(
                    available: widget.item.availableStock,
                    borrowed: widget.item.borrowedStock,
                    unit: widget.item.unit,
                  ),
                  const SizedBox(height: 15),
                  _Field(
                    label: 'Low Stock Alert Level *',
                    child: TextFormField(
                      controller: _lowStock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration(),
                      validator: (value) => int.tryParse(value ?? '') == null
                          ? 'Enter a whole number.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _Field(
                    label: 'Note',
                    child: TextFormField(
                      controller: _note,
                      maxLines: 3,
                      decoration: _decoration(),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _stockChanged
                        ? Padding(
                            key: const ValueKey('correction-reason'),
                            padding: const EdgeInsets.only(top: 15),
                            child: _Field(
                              label: 'Reason for Stock Correction *',
                              child: TextFormField(
                                controller: _correctionReason,
                                maxLines: 2,
                                decoration: _decoration().copyWith(
                                  hintText:
                                      'Incorrect quantity entered during initial setup.',
                                ),
                                validator: (value) {
                                  if (_stockChanged &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter a reason for the stock correction.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('no-correction-reason'),
                          ),
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
                              : const Text('SAVE CHANGES'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StockSnapshot extends StatelessWidget {
  const _StockSnapshot({
    required this.available,
    required this.borrowed,
    required this.unit,
  });

  final int available;
  final int borrowed;
  final String unit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFFD8E2EC)),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 7,
      children: [
        Text('Current Available: $available $unit'),
        Text('Current Borrowed: $borrowed $unit'),
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
        size: 50,
        color: Color(0xFF0D5BE1),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 7),
      child,
    ],
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Product name is required.' : null;
InputDecoration _decoration() => InputDecoration(
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
