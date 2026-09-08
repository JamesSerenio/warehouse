import 'package:flutter/material.dart';

import '../functions/inventory/inventory_list_function.dart';
import '../functions/inventory/search_item_function.dart';
import '../functions/navigation/navigation_function.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/modals/add_item_modal.dart';
import '../widgets/modals/view_item_modal.dart';
import '../widgets/warehouse_drawer.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded),
    (label: 'Borrowed', icon: Icons.calendar_month_outlined),
    (label: 'Items', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.description_outlined),
    (label: 'More', icon: Icons.more_horiz_rounded),
  ];
  final _search = TextEditingController();
  late Future<List<WarehouseItem>> _items;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _items = InventoryListFunction.loadItems();
    _search.addListener(_filterChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_filterChanged)
      ..dispose();
    super.dispose();
  }

  void _filterChanged() => setState(() {});
  void _reload() => setState(() => _items = InventoryListFunction.loadItems());
  void _open(String page) => NavigationFunction.goToPage(context, page);

  Future<void> _addItem() async {
    await showAddItemModal(context);
    if (mounted) _reload();
  }

  Future<void> _view(WarehouseItem item) async {
    if (await showViewItemModal(context, item) && mounted) _reload();
  }

  Future<void> _logout() async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed && mounted) NavigationFunction.goToLogin(context);
  }

  void _bottomTap(int index) {
    switch (index) {
      case 0:
        NavigationFunction.goToDashboard(context);
      case 1:
        _open('Borrowed');
      case 2:
        return;
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
      currentPage: 'Items',
      onNavigate: _open,
      onLogout: _logout,
    ),
    appBar: AppBar(
      toolbarHeight: 68,
      backgroundColor: const Color(0xFF08213B),
      foregroundColor: Colors.white,
      titleSpacing: 4,
      title: const Text(
        'Items',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 620;
                  final title = Text(
                    'Items',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF172033),
                      fontWeight: FontWeight.w800,
                    ),
                  );
                  final button = FilledButton.icon(
                    onPressed: _addItem,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5BE1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ADD ITEM'),
                  );
                  return narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [title, const SizedBox(height: 12), button],
                        )
                      : Row(
                          children: [
                            Expanded(child: title),
                            button,
                          ],
                        );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(
                            color: Color(0xFFD8E2EC),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(
                            color: Color(0xFFD8E2EC),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 600 ? 135 : 210,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _filter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 'tool', child: Text('Tool')),
                        DropdownMenuItem(
                          value: 'equipment',
                          child: Text('Equipment'),
                        ),
                        DropdownMenuItem(
                          value: 'material',
                          child: Text('Material / Consumable'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<WarehouseItem>>(
                  future: _items,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _StateView(
                        icon: Icons.cloud_off_rounded,
                        message: snapshot.error is InventoryListException
                            ? (snapshot.error! as InventoryListException)
                                  .message
                            : 'Unable to load items.',
                        action: _reload,
                      );
                    }
                    final items = SearchItemFunction.filter(
                      items: snapshot.data ?? const [],
                      query: _search.text,
                      itemType: _filter,
                    );
                    if (items.isEmpty) {
                      return const _StateView(
                        icon: Icons.inventory_2_outlined,
                        message: 'No items found.',
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1000
                            ? 3
                            : constraints.maxWidth >= 650
                            ? 2
                            : 1;
                        return GridView.builder(
                          itemCount: items.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: columns == 1 ? 2.7 : 2.25,
                              ),
                          itemBuilder: (_, index) => _ItemCard(
                            item: items[index],
                            onTap: () => _view(items[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 2,
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
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final WarehouseItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFFF1F5FA),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE1E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 82,
                height: 82,
                child: item.imageUrl == null
                    ? const _Fallback()
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _Fallback(),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.typeLabel} • ${item.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Total: ${item.totalStock}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'Available: ${item.availableStock}',
                        style: const TextStyle(
                          color: Color(0xFF168447),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.itemType != 'material')
                        Text(
                          'Borrowed: ${item.borrowedStock}',
                          style: const TextStyle(
                            color: Color(0xFFDC5B13),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (item.isLowStock
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF168447))
                              .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.isLowStock ? 'Low Stock' : 'In Stock',
                      style: TextStyle(
                        color: item.isLowStock
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF168447),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    ),
  );
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8F0FF),
    child: Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF0D5BE1),
        size: 36,
      ),
    ),
  );
}

class _StateView extends StatelessWidget {
  const _StateView({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(message),
        if (action != null) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: action, child: const Text('TRY AGAIN')),
        ],
      ],
    ),
  );
}
