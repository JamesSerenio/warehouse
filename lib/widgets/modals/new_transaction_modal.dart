import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/inventory/inventory_list_function.dart';
import '../../functions/transactions/new_transaction_function.dart';
import 'modal_helper.dart';
import 'signature_modal.dart';

Future<void> showNewTransactionModal(BuildContext context) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 920,
    builder: (_) => const _NewTransactionModal(),
  );
}

class _NewTransactionModal extends StatefulWidget {
  const _NewTransactionModal();

  @override
  State<_NewTransactionModal> createState() => _NewTransactionModalState();
}

class _NewTransactionModalState extends State<_NewTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final List<TransactionDraftItem> _selectedItems = [];

  List<WarehouseItem> _availableItems = const [];
  bool _isLoadingItems = true;
  String? _loadError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoadingItems = true;
      _loadError = null;
    });
    try {
      final items = await NewTransactionFunction.loadAvailableItems();
      if (!mounted) return;
      setState(() {
        _availableItems = items;
        _isLoadingItems = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingItems = false;
        _loadError = 'Unable to load available items.';
      });
    }
  }

  void _addItem(WarehouseItem item) {
    if (_selectedItems.any((entry) => entry.item.id == item.id)) {
      setState(() => _formError = 'Item already added.');
      return;
    }
    setState(() {
      _selectedItems.add(TransactionDraftItem(item: item));
      _searchController.clear();
      _formError = null;
    });
  }

  void _updateItem(int index, TransactionDraftItem item) {
    setState(() {
      _selectedItems[index] = item;
      _formError = null;
    });
  }

  void _changeQuantity(int index, int change) {
    final entry = _selectedItems[index];
    final next = entry.quantity + change;
    if (next < 1) return;
    if (next > entry.item.availableStock) {
      setState(
        () => _formError =
            'Only ${entry.item.availableStock} ${entry.item.unit} are available.',
      );
      return;
    }
    _updateItem(index, entry.copyWith(quantity: next));
  }

  Future<void> _pickDate(int index) async {
    final entry = _selectedItems[index];
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.returnDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) _updateItem(index, entry.copyWith(returnDate: picked));
  }

  Future<void> _pickTime(int index) async {
    final entry = _selectedItems[index];
    final existing = entry.returnTimeMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: existing == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: existing ~/ 60, minute: existing % 60),
    );
    if (picked != null) {
      _updateItem(
        index,
        entry.copyWith(returnTimeMinutes: picked.hour * 60 + picked.minute),
      );
    }
  }

  Future<void> _proceed() async {
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    final draft = NewTransactionDraft(
      borrowerName: _nameController.text.trim(),
      contactNumber: _contactController.text.trim(),
      items: List.unmodifiable(_selectedItems),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    final validationError = NewTransactionFunction.validateDraft(draft);
    if (!fieldsValid || validationError != null) {
      setState(
        () => _formError =
            validationError ?? 'Please complete all required fields.',
      );
      return;
    }
    setState(() => _formError = null);
    await showSignatureModal(context, draft: draft);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ModalHeader(onClose: () => Navigator.pop(context)),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('Borrower Information'),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          _Field(
                            controller: _nameController,
                            label: 'Borrower Name *',
                            icon: Icons.person_outline_rounded,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Borrower name is required.'
                                : null,
                          ),
                          _Field(
                            controller: _contactController,
                            label: 'Contact Number *',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+]'),
                              ),
                            ],
                            validator: (value) =>
                                NewTransactionFunction.validateContact(
                                  value ?? '',
                                ),
                          ),
                        ];
                        if (constraints.maxWidth < 620) {
                          return Column(
                            children: [
                              fields[0],
                              const SizedBox(height: 12),
                              fields[1],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 14),
                            Expanded(child: fields[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle('Add Items'),
                    const SizedBox(height: 10),
                    _ItemSearch(
                      items: _availableItems,
                      isLoading: _isLoadingItems,
                      error: _loadError,
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onSelected: _addItem,
                      onRetry: _loadItems,
                    ),
                    const SizedBox(height: 14),
                    if (_selectedItems.isEmpty)
                      const _EmptyItems()
                    else
                      ...List.generate(
                        _selectedItems.length,
                        (index) => _SelectedItemCard(
                          entry: _selectedItems[index],
                          onDecrease: () => _changeQuantity(index, -1),
                          onIncrease: () => _changeQuantity(index, 1),
                          onDate: () => _pickDate(index),
                          onTime: () => _pickTime(index),
                          onRemove: () => setState(() {
                            _selectedItems.removeAt(index);
                            _formError = null;
                          }),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isLoadingItems
                            ? null
                            : () => _searchFocus.requestFocus(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('ADD ANOTHER ITEM'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _noteController,
                      label: 'Note (Optional)',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _formError!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: FilledButton.icon(
                            onPressed: _proceed,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D5BE1),
                              minimumSize: const Size(230, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            icon: const Icon(Icons.draw_outlined),
                            label: const Text('PROCEED TO SIGNATURE'),
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
}

class _ItemSearch extends StatelessWidget {
  const _ItemSearch({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.controller,
    required this.focusNode,
    required this.onSelected,
    required this.onRetry,
  });

  final List<WarehouseItem> items;
  final bool isLoading;
  final String? error;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<WarehouseItem> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LinearProgressIndicator(minHeight: 3);
    }
    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      );
    }
    return RawAutocomplete<WarehouseItem>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (item) => item.productName,
      optionsBuilder: (value) =>
          NewTransactionFunction.searchItems(items, value.text),
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, node, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: node,
          onSubmitted: (_) => onSubmitted(),
          decoration: _decoration(
            label: 'Search product...',
            icon: Icons.search_rounded,
          ),
        );
      },
      optionsViewBuilder: (context, select, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 300),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final item = options.elementAt(index);
                return InkWell(
                  onTap: () => select(item),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Row(
                      children: [
                        _Thumbnail(url: item.imageUrl),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.typeLabel} • Available: ${item.availableStock} ${item.unit}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedItemCard extends StatelessWidget {
  const _SelectedItemCard({
    required this.entry,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDate,
    required this.onTime,
    required this.onRemove,
  });

  final TransactionDraftItem entry;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDate;
  final VoidCallback onTime;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDCE5EF)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _Thumbnail(url: entry.item.imageUrl),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${entry.item.typeLabel} • Available: ${entry.item.availableStock} ${entry.item.unit}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _QuantityControl(
              value: entry.quantity,
              canIncrease: entry.quantity < entry.item.availableStock,
              onDecrease: onDecrease,
              onIncrease: onIncrease,
            ),
            IconButton(
              tooltip: 'Remove item',
              onPressed: onRemove,
              color: const Color(0xFFEF4444),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        if (entry.requiresReturn) ...[
          const Divider(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final date = OutlinedButton.icon(
                onPressed: onDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  entry.returnDate == null
                      ? 'Return Date *'
                      : _dateLabel(entry.returnDate!),
                ),
              );
              final time = OutlinedButton.icon(
                onPressed: onTime,
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(
                  entry.returnTimeMinutes == null
                      ? 'Return Time *'
                      : _timeLabel(context, entry.returnTimeMinutes!),
                ),
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [date, const SizedBox(height: 8), time],
                );
              }
              return Row(
                children: [
                  Expanded(child: date),
                  const SizedBox(width: 10),
                  Expanded(child: time),
                ],
              );
            },
          ),
        ] else ...[
          const Divider(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No return required',
              style: TextStyle(
                color: Color(0xFF168447),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.value,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });
  final int value;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFCBD5E1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > 1 ? onDecrease : null,
          icon: const Icon(Icons.remove_rounded),
          visualDensity: VisualDensity.compact,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: canIncrease ? onIncrease : null,
          icon: const Icon(Icons.add_rounded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 46,
      height: 46,
      child: url == null
          ? const ColoredBox(
              color: Color(0xFFE8F0FF),
              child: Icon(Icons.inventory_2_outlined, color: Color(0xFF0D5BE1)),
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF0D5BE1),
                ),
              ),
            ),
    ),
  );
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFDCE5EF)),
    ),
    child: const Column(
      children: [
        Icon(Icons.playlist_add_rounded, color: Color(0xFF94A3B8), size: 34),
        SizedBox(height: 6),
        Text(
          'Search and add at least one item.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    padding: const EdgeInsets.only(left: 22, right: 8),
    color: const Color(0xFF08213B),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'New Transaction',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          color: Colors.white,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF172033),
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    decoration: _decoration(label: label, icon: icon),
  );
}

InputDecoration _decoration({required String label, required IconData icon}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
  );
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF0D5BE1), width: 1.5),
    ),
  );
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _timeLabel(BuildContext context, int minutes) {
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);
}
