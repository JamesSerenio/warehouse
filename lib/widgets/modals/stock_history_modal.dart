import 'package:flutter/material.dart';

import '../../functions/stock/stock_history_function.dart';
import 'modal_helper.dart';

Future<void> showStockHistoryModal(BuildContext context) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 960,
    builder: (_) => const _StockHistoryModal(),
  );
}

class _StockHistoryModal extends StatefulWidget {
  const _StockHistoryModal();

  @override
  State<_StockHistoryModal> createState() => _StockHistoryModalState();
}

class _StockHistoryModalState extends State<_StockHistoryModal> {
  static const _allActions = 'All actions';
  final _searchController = TextEditingController();
  late Future<List<StockMovementRecord>> _history;
  String _selectedAction = _allActions;

  @override
  void initState() {
    super.initState();
    _history = StockHistoryFunction.loadStockHistory();
    _searchController.addListener(_refreshFilter);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  void _refreshFilter() => setState(() {});

  void _reload() {
    setState(() => _history = StockHistoryFunction.loadStockHistory());
  }

  List<StockMovementRecord> _filtered(List<StockMovementRecord> records) {
    final query = _searchController.text.trim().toLowerCase();
    return records
        .where((record) {
          final action = _actionLabel(record.movementType);
          final matchesAction =
              _selectedAction == _allActions || action == _selectedAction;
          final matchesQuery =
              query.isEmpty ||
              record.itemName.toLowerCase().contains(query) ||
              (record.referenceCode?.toLowerCase().contains(query) ?? false);
          return matchesAction && matchesQuery;
        })
        .toList(growable: false);
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
          Container(
            height: 62,
            padding: const EdgeInsets.only(left: 22, right: 8),
            color: const Color(0xFF08213B),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Stock History',
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
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search item or reference...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: _searchController.clear,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD8E2EC),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD8E2EC),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        tooltip: 'Filter stock history',
                        initialValue: _selectedAction,
                        onSelected: (value) =>
                            setState(() => _selectedAction = value),
                        itemBuilder: (_) => [
                          for (final action in const [
                            _allActions,
                            'Initial Stock',
                            'Added Stock',
                            'Borrowed',
                            'Returned',
                            'Material Issued',
                            'Adjustment',
                          ])
                            PopupMenuItem(value: action, child: Text(action)),
                        ],
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFB9CEF1)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                color: Color(0xFF0D5BE1),
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  color: Color(0xFF0D5BE1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<StockMovementRecord>>(
                      future: _history,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          final message =
                              snapshot.error is StockHistoryException
                              ? (snapshot.error! as StockHistoryException)
                                    .message
                              : 'Unable to load stock history.';
                          return _MessageState(
                            icon: Icons.cloud_off_rounded,
                            message: message,
                            actionLabel: 'TRY AGAIN',
                            onAction: _reload,
                          );
                        }
                        final records = _filtered(snapshot.data ?? const []);
                        if (records.isEmpty) {
                          return const _MessageState(
                            icon: Icons.history_rounded,
                            message: 'No stock history yet.',
                          );
                        }
                        return _HistoryTable(records: records);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.records});
  final List<StockMovementRecord> records;

  @override
  Widget build(BuildContext context) => Scrollbar(
    thumbVisibility: true,
    child: SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          columns: const [
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Qty'), numeric: true),
            DataColumn(label: Text('Balance'), numeric: true),
          ],
          rows: [
            for (final record in records)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(width: 130, child: Text(_date(record.createdAt))),
                  ),
                  DataCell(SizedBox(width: 190, child: Text(record.itemName))),
                  DataCell(_ActionBadge(type: record.movementType)),
                  DataCell(Text(_quantity(record))),
                  DataCell(Text('${record.balanceAfter}')),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final label = _actionLabel(type);
    final color = switch (label) {
      'Added Stock' || 'Returned' => const Color(0xFF168447),
      'Borrowed' || 'Material Issued' => const Color(0xFFDC5B13),
      'Initial Stock' => const Color(0xFF0D5BE1),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 46, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 14),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

String _actionLabel(String type) => switch (type.toLowerCase()) {
  'initial_stock' => 'Initial Stock',
  'added_stock' || 'add_stock' => 'Added Stock',
  'borrowed' || 'borrow' => 'Borrowed',
  'returned' || 'return' => 'Returned',
  'material_issued' || 'issued' => 'Material Issued',
  _ => 'Adjustment',
};

String _quantity(StockMovementRecord record) {
  final action = _actionLabel(record.movementType);
  final prefix = switch (action) {
    'Initial Stock' || 'Added Stock' || 'Returned' => '+',
    'Borrowed' || 'Material Issued' => '-',
    _ => '',
  };
  return '$prefix${record.quantity.abs()}';
}

String _date(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day  $hour:$minute';
}
