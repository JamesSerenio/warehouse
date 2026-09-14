import 'package:flutter/material.dart';

import '../functions/borrowed/borrowed_filter_function.dart';
import '../functions/borrowed/borrowed_list_function.dart';
import '../functions/borrowed/borrowed_search_function.dart';
import '../functions/navigation/navigation_function.dart';
import '../functions/transactions/transaction_details_function.dart';
import '../services/supabase_service.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/modals/return_items_modal.dart';
import '../widgets/modals/transaction_details_modal.dart';
import '../widgets/warehouse_drawer.dart';

class BorrowedScreen extends StatefulWidget {
  const BorrowedScreen({super.key});
  @override
  State<BorrowedScreen> createState() => _BorrowedScreenState();
}

class _BorrowedScreenState extends State<BorrowedScreen> {
  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded),
    (label: 'Borrowed', icon: Icons.calendar_month_outlined),
    (label: 'Items', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.description_outlined),
    (label: 'More', icon: Icons.more_horiz_rounded),
  ];
  final _search = TextEditingController();
  late Future<List<BorrowedTransaction>> _records;
  BorrowedFilter _filter = BorrowedFilter.all;

  @override
  void initState() {
    super.initState();
    _records = BorrowedListFunction.load();
    _search.addListener(_changed);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() => setState(() {});
  void _open(String page) => NavigationFunction.goToPage(context, page);

  Future<void> _refresh() async {
    final future = BorrowedListFunction.load();
    setState(() => _records = future);
    await future;
  }

  Future<void> _logout() async {
    final loggedOut = await showLogoutConfirmationDialog(context);
    if (loggedOut && mounted) NavigationFunction.goToLogin(context);
  }

  Future<void> _details(BorrowedTransaction record) async {
    await showTransactionDetailsModal(context, transaction: record.details);
    if (mounted) await _refresh();
  }

  Future<void> _return(BorrowedTransaction record) async {
    await showReturnItemsModal(
      context,
      transactionId: record.id,
      transactionCode: record.transactionCode,
    );
    if (mounted) await _refresh();
  }

  void _bottomTap(int index) {
    switch (index) {
      case 0:
        NavigationFunction.goToDashboard(context);
      case 1:
        return;
      case 2:
        _open('Items');
      case 3:
        _open('Reports');
      case 4:
        _open('More');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    drawer: WarehouseDrawer(
      currentPage: 'Borrowed',
      onNavigate: _open,
      onLogout: _logout,
    ),
    appBar: AppBar(
      toolbarHeight: 68,
      backgroundColor: const Color(0xFF08213B),
      foregroundColor: Colors.white,
      titleSpacing: 4,
      title: const Text(
        'Borrowed',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            sliver: SliverToBoxAdapter(child: _controls(context)),
          ),
          FutureBuilder<List<BorrowedTransaction>>(
            future: _records,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                final message = snapshot.error is BorrowedListException
                    ? (snapshot.error! as BorrowedListException).message
                    : 'Unable to load borrowed items.';
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.cloud_off_rounded,
                    message: message,
                    onRetry: _refresh,
                  ),
                );
              }
              var records = BorrowedSearchFunction.apply(
                snapshot.data ?? const [],
                _search.text,
              );
              records = BorrowedFilterFunction.apply(records, _filter);
              if (records.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.assignment_return_outlined,
                    message: 'No borrowed tools or equipment.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverList.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 13),
                  itemBuilder: (_, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: _BorrowedCard(
                        transaction: records[index],
                        onTap: () => _details(records[index]),
                        onReturn: () => _return(records[index]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 1,
      onTap: _bottomTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF0D5BE1),
      unselectedItemColor: const Color(0xFF66758A),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      items: [
        for (final item in _navItems)
          BottomNavigationBarItem(
            icon: Icon(item.icon, size: 23),
            activeIcon: Icon(item.icon, size: 24),
            label: item.label,
          ),
      ],
    ),
  );

  Widget _controls(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Borrowed Items',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF172033),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search borrower, transaction code, or item...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _search.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFD8E2EC)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BorrowedFilter.values
                  .map((filter) {
                    final selected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterLabel(filter)),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: const Color(0xFF0D5BE1),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                        side: const BorderSide(color: Color(0xFFD8E2EC)),
                        showCheckmark: false,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BorrowedCard extends StatelessWidget {
  const _BorrowedCard({
    required this.transaction,
    required this.onTap,
    required this.onReturn,
  });
  final BorrowedTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final canReturn = transaction.items.any((i) => i.remainingQuantity > 0);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFF8FAFC),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    transaction.transactionCode,
                    style: const TextStyle(
                      color: Color(0xFF0D5BE1),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _StatusBadge(status: transaction.status),
                  Text(
                    transaction.borrowerName,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    transaction.contactNumber,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const Divider(height: 26, color: Color(0xFFE2E8F0)),
              ...transaction.items.map(_BorrowedItemRow.new),
              if (canReturn) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onReturn,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5BE1),
                      minimumSize: const Size(160, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_return_rounded, size: 19),
                    label: const Text('RETURN ITEMS'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BorrowedItemRow extends StatelessWidget {
  const _BorrowedItemRow(this.item);
  final TransactionLineDetails item;

  @override
  Widget build(BuildContext context) {
    final path = item.imagePath?.trim();
    final imageUrl = path == null || path.isEmpty
        ? null
        : SupabaseService.client.storage.from('item-images').getPublicUrl(path);
    final identity = Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 64,
            height: 64,
            child: imageUrl == null
                ? const _ImageFallback()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ImageFallback(),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.itemTypeLabel,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
    final metrics = Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _Metric('Borrowed', '${item.quantity} ${item.unit}'),
        _Metric('Returned', '${item.returnedQuantity} ${item.unit}'),
        _Metric('Remaining', '${item.remainingQuantity} ${item.unit}'),
        _Metric('Due', _formatDateTime(item.expectedReturnAt)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (_, constraints) => constraints.maxWidth < 680
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [identity, const SizedBox(height: 11), metrics],
              )
            : Row(
                children: [
                  SizedBox(width: 300, child: identity),
                  const SizedBox(width: 18),
                  Expanded(child: metrics),
                ],
              ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final BorrowedStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BorrowedStatus.active => const Color(0xFF0D5BE1),
      BorrowedStatus.partialReturn => const Color(0xFFEA7600),
      BorrowedStatus.overdue => const Color(0xFFDC2626),
      BorrowedStatus.returned => const Color(0xFF168447),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8F0FF),
    child: Center(
      child: Icon(Icons.handyman_outlined, color: Color(0xFF0D5BE1), size: 30),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.onRetry});
  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Color(0xFF64748B))),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ],
    ),
  );
}

String _filterLabel(BorrowedFilter filter) => switch (filter) {
  BorrowedFilter.all => 'All',
  BorrowedFilter.active => 'Active',
  BorrowedFilter.partialReturn => 'Partial Return',
  BorrowedFilter.overdue => 'Overdue',
  BorrowedFilter.returned => 'Returned',
};

String _statusLabel(BorrowedStatus status) => switch (status) {
  BorrowedStatus.active => 'Active',
  BorrowedStatus.partialReturn => 'Partial Return',
  BorrowedStatus.overdue => 'Overdue',
  BorrowedStatus.returned => 'Returned',
};

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'Not set';
  final value = dateTime.toLocal();
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
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${months[value.month - 1]} ${value.day}, ${value.year}  $hour:$minute $period';
}
