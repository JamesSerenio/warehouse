import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../functions/inventory/add_item_function.dart';
import '../../functions/inventory/remove_background_function.dart';
import '../../functions/inventory/upload_item_image_function.dart';
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
  final _unitController = TextEditingController();
  String? _category;
  Uint8List? _imageBytes;
  String? _imageExtension;
  Uint8List? _removedBackgroundBytes;
  bool _previewRemovedBackground = false;
  bool _useRemovedBackground = false;
  bool _isRemovingBackground = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _initialStockController.dispose();
    _lowStockController.dispose();
    _noteController.dispose();
    _unitController.dispose();
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

  Future<void> _selectImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final dotIndex = image.name.lastIndexOf('.');
      final extension = dotIndex < 0
          ? ''
          : image.name.substring(dotIndex + 1).toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        if (!mounted) return;
        await showWarningModal(
          context,
          message: 'Please select a JPG, PNG, or WEBP image.',
        );
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        await showWarningModal(
          context,
          message: 'Image must be 5 MB or smaller.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageExtension = extension;
        _removedBackgroundBytes = null;
        _previewRemovedBackground = false;
        _useRemovedBackground = false;
      });
    } on PlatformException catch (error, stackTrace) {
      debugPrint('IMAGE PICKER PLATFORM ERROR');
      debugPrint('Code: ${error.code}');
      debugPrint('Message: ${error.message}');
      debugPrint('Details: ${error.details}');
      debugPrint('$stackTrace');
      if (!mounted) return;
      await showWarningModal(
        context,
        message: 'Unable to select the image. Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('IMAGE PICKER ERROR: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      await showWarningModal(
        context,
        message: 'Unable to select the image. Please try again.',
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageExtension = null;
      _removedBackgroundBytes = null;
      _previewRemovedBackground = false;
      _useRemovedBackground = false;
    });
  }

  Future<void> _removeBackground() async {
    if (_imageBytes == null ||
        _imageExtension == null ||
        _isRemovingBackground) {
      return;
    }
    setState(() => _isRemovingBackground = true);
    try {
      final processedBytes = await RemoveBackgroundFunction.removeBackground(
        originalBytes: _imageBytes!,
        originalExtension: _imageExtension!,
      );
      if (!mounted) return;
      setState(() {
        _removedBackgroundBytes = processedBytes;
        _previewRemovedBackground = true;
        // Saving continues to use the original until the user confirms PNG.
        _useRemovedBackground = false;
      });
    } on RemoveBackgroundException {
      if (!mounted) return;
      await showWarningModal(
        context,
        message:
            'Background removal failed. You can still use the original image.',
      );
    } finally {
      if (mounted) setState(() => _isRemovingBackground = false);
    }
  }

  void _selectOriginalImage() {
    setState(() {
      _previewRemovedBackground = false;
      _useRemovedBackground = false;
    });
  }

  void _selectRemovedBackgroundImage() {
    if (_removedBackgroundBytes == null) return;
    setState(() {
      _previewRemovedBackground = true;
      _useRemovedBackground = true;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final itemId = await AddItemFunction.addItem(
        productName: _productNameController.text,
        itemType: _categories[_category]!,
        unit: _unitController.text,
        initialStock: int.parse(_initialStockController.text),
        lowStockLevel: int.parse(_lowStockController.text),
        note: _noteController.text,
      );
      if (!mounted) return;
      String? imageUploadWarning;
      if (_imageBytes != null && _imageExtension != null) {
        try {
          final finalBytes = _useRemovedBackground
              ? _removedBackgroundBytes!
              : _imageBytes!;
          final finalExtension = _useRemovedBackground
              ? 'png'
              : _imageExtension!;
          await UploadItemImageFunction.uploadItemImage(
            itemId: itemId,
            bytes: finalBytes,
            extension: finalExtension,
          );
        } on UploadItemImageException catch (error) {
          imageUploadWarning = error.message;
        }
      }
      if (!mounted) return;
      _clearForm();
      if (imageUploadWarning == null) {
        await showSuccessModal(context, message: 'Item added successfully.');
      } else {
        await showWarningModal(
          context,
          title: 'Item Added',
          message: imageUploadWarning,
        );
      }
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
    _unitController.clear();
    setState(() {
      _category = null;
      _imageBytes = null;
      _imageExtension = null;
      _removedBackgroundBytes = null;
      _previewRemovedBackground = false;
      _useRemovedBackground = false;
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
                        _ProductImageSection(
                          imageBytes: _previewRemovedBackground
                              ? _removedBackgroundBytes
                              : _imageBytes,
                          hasProcessedImage: _removedBackgroundBytes != null,
                          usingRemovedBackground: _useRemovedBackground,
                          isRemovingBackground: _isRemovingBackground,
                          onSelect: _selectImage,
                          onRemove: _removeImage,
                          onRemoveBackground: _removeBackground,
                          onUseOriginal: _selectOriginalImage,
                          onUseRemovedBackground: _selectRemovedBackgroundImage,
                        ),
                        const SizedBox(height: 20),
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
                          _UnitComboField(
                            controller: _unitController,
                            units: _units,
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

class _ProductImageSection extends StatelessWidget {
  const _ProductImageSection({
    required this.imageBytes,
    required this.hasProcessedImage,
    required this.usingRemovedBackground,
    required this.isRemovingBackground,
    required this.onSelect,
    required this.onRemove,
    required this.onRemoveBackground,
    required this.onUseOriginal,
    required this.onUseRemovedBackground,
  });

  final Uint8List? imageBytes;
  final bool hasProcessedImage;
  final bool usingRemovedBackground;
  final bool isRemovingBackground;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final VoidCallback onRemoveBackground;
  final VoidCallback onUseOriginal;
  final VoidCallback onUseRemovedBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E2EC)),
      ),
      child: imageBytes == null ? _emptyState() : _preview(),
    );
  }

  Widget _emptyState() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: Color(0xFF0D5BE1),
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Product Photo',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Optional',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onSelect,
          icon: const Icon(Icons.image_outlined, size: 18),
          label: const Text('SELECT IMAGE'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0D5BE1),
            side: const BorderSide(color: Color(0xFF9CBEF5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _preview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _CheckerboardPainter()),
                Image.memory(
                  imageBytes!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: hasProcessedImage
              ? [
                  OutlinedButton.icon(
                    onPressed: isRemovingBackground ? null : onUseOriginal,
                    icon: Icon(
                      !usingRemovedBackground
                          ? Icons.check_circle_rounded
                          : Icons.image_outlined,
                      size: 18,
                    ),
                    label: const Text('USE ORIGINAL'),
                  ),
                  FilledButton.icon(
                    onPressed: isRemovingBackground
                        ? null
                        : onUseRemovedBackground,
                    icon: Icon(
                      usingRemovedBackground
                          ? Icons.check_circle_rounded
                          : Icons.auto_fix_high_rounded,
                      size: 18,
                    ),
                    label: const Text('USE REMOVED BACKGROUND'),
                  ),
                  TextButton.icon(
                    onPressed: isRemovingBackground ? null : onRemoveBackground,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('TRY AGAIN'),
                  ),
                ]
              : [
                  FilledButton.icon(
                    onPressed: isRemovingBackground ? null : onRemoveBackground,
                    icon: isRemovingBackground
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(
                      isRemovingBackground
                          ? 'REMOVING...'
                          : 'REMOVE BACKGROUND',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: isRemovingBackground ? null : onUseOriginal,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('USE ORIGINAL'),
                  ),
                ],
        ),
        const Divider(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: isRemovingBackground ? null : onSelect,
              icon: const Icon(Icons.change_circle_outlined, size: 19),
              label: const Text('Change Photo'),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: isRemovingBackground ? null : onRemove,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 14.0;
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFE8EDF3);
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final alternating =
            ((x / squareSize).floor() + (y / squareSize).floor()).isEven;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          alternating ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _UnitComboField extends StatefulWidget {
  const _UnitComboField({required this.controller, required this.units});

  final TextEditingController controller;
  final List<String> units;

  @override
  State<_UnitComboField> createState() => _UnitComboFieldState();
}

class _UnitComboFieldState extends State<_UnitComboField> {
  final _menuController = MenuController();

  List<String> get _suggestions {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) return widget.units;
    return widget.units
        .where((unit) => unit.toLowerCase().contains(query))
        .toList();
  }

  void _showSuggestions() {
    if (!_menuController.isOpen) _menuController.open();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    return _FieldShell(
      label: 'Unit *',
      child: MenuAnchor(
        controller: _menuController,
        menuChildren: [
          for (final unit in suggestions)
            MenuItemButton(
              onPressed: () {
                widget.controller.text = unit;
                widget.controller.selection = TextSelection.collapsed(
                  offset: unit.length,
                );
              },
              child: SizedBox(width: 180, child: Text(unit)),
            ),
          if (suggestions.isEmpty)
            const MenuItemButton(
              onPressed: null,
              child: SizedBox(
                width: 180,
                child: Text('Custom unit will be used'),
              ),
            ),
        ],
        builder: (context, menuController, child) => TextFormField(
          controller: widget.controller,
          textInputAction: TextInputAction.next,
          onTap: _showSuggestions,
          onChanged: (_) {
            setState(() {});
            if (suggestions.isNotEmpty) _showSuggestions();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Unit is required.';
            }
            return null;
          },
          decoration: _decoration('Select or type a unit').copyWith(
            suffixIcon: IconButton(
              tooltip: 'Show unit options',
              onPressed: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              icon: Icon(
                menuController.isOpen
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
