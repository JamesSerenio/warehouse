import 'package:flutter/material.dart';

import '../../functions/returns/filter_pending_returns_function.dart';
import '../../functions/returns/load_pending_returns_function.dart';
import '../../functions/returns/search_pending_returns_function.dart';
import '../../functions/transactions/transaction_details_function.dart';
import '../../services/supabase_service.dart';
import 'modal_helper.dart';
import 'return_items_modal.dart';

Future<bool> showReturnItemsListModal(BuildContext context) async {
  return await showWarehouseModal<bool>(
        context: context,
        maxWidth: 920,
        builder: (_) => const _ReturnItemsListModal(),
      ) ??
      false;
}

class _ReturnItemsListModal extends StatefulWidget {
  const _ReturnItemsListModal();

  @override
  State<_ReturnItemsListModal> createState() => _ReturnItemsListModalState();
}

class _ReturnItemsListModalState extends State<_ReturnItemsListModal> {
  final _search = TextEditingController();
  late Future<List<TransactionDetails>> _pending;
  PendingReturnFilter _filter = PendingReturnFilter.all;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _pending = LoadPendingReturnsFunction.load();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _refresh() async {
    final pending = LoadPendingReturnsFunction.load();
    setState(() => _pending = pending);
    await pending;
  }

  Future<void> _open(TransactionDetails transaction) async {
    final returned = await showReturnItemsModal(
      context,
      transactionId: transaction.id,
      transactionCode: transaction.transactionCode,
    );
    if (!mounted || !returned) return;
    _changed = true;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Container(
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
                  'Return Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context, _changed),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search borrower, item, or transaction...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: PendingReturnFilter.values
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_filterLabel(filter)),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                            selectedColor: const Color(0xFFDCE8FF),
                            labelStyle: TextStyle(
                              color: _filter == filter
                                  ? const Color(0xFF0D5BE1)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                            side: const BorderSide(color: Color(0xFFD8DEE8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<TransactionDetails>>(
            future: _pending,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _LoadFailure(retry: _refresh);
              }
              final searched = SearchPendingReturnsFunction.apply(
                snapshot.data ?? const [],
                _search.text,
              );
              final visible = FilterPendingReturnsFunction.apply(
                searched,
                _filter,
              );
              if (visible.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No items are currently pending return.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _TransactionCard(
                    transaction: visible[index],
                    onTap: () => _open(visible[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onTap});
  final TransactionDetails transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = transaction.returnableItems
        .where((item) => item.remainingQuantity > 0)
        .toList(growable: false);
    return Material(
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.transactionCode,
                          style: const TextStyle(
                            color: Color(0xFF0D5BE1),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          transaction.borrowerName,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          transaction.contactNumber,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(transaction: transaction),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _PendingItem(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingItem extends StatelessWidget {
  const _PendingItem({required this.item});
  final TransactionLineDetails item;

  @override
  Widget build(BuildContext context) {
    final path = item.imagePath?.trim();
    final imageUrl = path == null || path.isEmpty
        ? null
        : SupabaseService.client.storage.from('item-images').getPublicUrl(path);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 54,
              height: 54,
              child: imageUrl == null
                  ? const _FallbackImage()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FallbackImage(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Borrowed: ${item.quantity} ${item.unit}  •  Remaining: ${item.remainingQuantity} ${item.unit}',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Due: ${_formatDate(item.expectedReturnAt)}',
                  style: TextStyle(
                    color: item.isOverdue
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: item.isOverdue
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8F0FF),
    child: Icon(Icons.construction_rounded, color: Color(0xFF0D5BE1)),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.transaction});
  final TransactionDetails transaction;

  @override
  Widget build(BuildContext context) {
    final items = transaction.returnableItems.where(
      (item) => item.remainingQuantity > 0,
    );
    final overdue = items.any((item) => item.isOverdue);
    final dueToday = items.any(
      (item) => isPendingReturnDueToday(item.expectedReturnAt),
    );
    final partial = items.any((item) => item.returnedQuantity > 0);
    final (label, foreground, background) = overdue
        ? ('OVERDUE', const Color(0xFFDC2626), const Color(0xFFFEE2E2))
        : dueToday
        ? ('DUE TODAY', const Color(0xFFD97706), const Color(0xFFFFEDD5))
        : partial
        ? ('PARTIAL RETURN', const Color(0xFF7C3AED), const Color(0xFFEDE9FE))
        : ('ACTIVE', const Color(0xFF168447), const Color(0xFFDCFCE7));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.retry});
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to load pending returns.'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('TRY AGAIN'),
        ),
      ],
    ),
  );
}

String _filterLabel(PendingReturnFilter filter) => switch (filter) {
  PendingReturnFilter.all => 'All',
  PendingReturnFilter.active => 'Active',
  PendingReturnFilter.partial => 'Partial Return',
  PendingReturnFilter.overdue => 'Overdue',
  PendingReturnFilter.dueToday => 'Due Today',
};

String _formatDate(DateTime? value) {
  if (value == null) return 'Not set';
  final date = value.toLocal();
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
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute $period';
}
