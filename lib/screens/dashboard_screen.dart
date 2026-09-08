import 'package:flutter/material.dart';

import '../functions/dashboard/dashboard_summary_function.dart';
import '../functions/navigation/navigation_function.dart';
import '../models/dashboard_summary.dart';
import '../widgets/modals/add_item_modal.dart';
import '../widgets/modals/new_transaction_modal.dart';
import 'items_screen.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/warehouse_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  bool _isLoading = true;

  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded),
    (label: 'Borrowed', icon: Icons.calendar_month_outlined),
    (label: 'Items', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.description_outlined),
    (label: 'More', icon: Icons.more_horiz_rounded),
  ];
  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final summary = await DashboardSummaryFunction.load();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final didLogout = await showLogoutConfirmationDialog(context);
    if (!mounted || !didLogout) return;
    NavigationFunction.goToLogin(context);
  }

  void _open(String title) {
    _openPage(title);
  }

  Future<void> _openNewTransaction() async {
    debugPrint('NEW TRANSACTION TAP STARTED');
    try {
      await showNewTransactionModal(context);
      debugPrint('NEW TRANSACTION MODAL CLOSED');
    } catch (error, stackTrace) {
      debugPrint('NEW TRANSACTION ERROR: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open New Transaction. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openPage(String title) async {
    if (title == 'New Transaction') {
      await _openNewTransaction();
      return;
    }
    if (title == 'Items') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ItemsScreen()));
    } else if (title == 'Add Item') {
      await showAddItemModal(context);
    } else {
      NavigationFunction.goToPage(context, title);
      return;
    }
    if (mounted) {
      await _refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: WarehouseDrawer(
        currentPage: 'Dashboard',
        onNavigate: _open,
        onLogout: _logout,
      ),
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: const Color(0xFF08213B),
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications.')),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: const Color(0xFF172033),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: width >= 900 ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: width >= 900 ? 1.75 : 1.55,
                        children: [
                          DashboardStatCard(
                            label: 'Total Items',
                            value: _isLoading
                                ? '...'
                                : '${_summary?.totalItems ?? 0}',
                            icon: Icons.inventory_2_outlined,
                            accentColor: const Color(0xFF0D5BE1),
                          ),
                          DashboardStatCard(
                            label: 'Tools / Equipment Borrowed',
                            value: _isLoading
                                ? '...'
                                : '${_summary?.borrowedToolsEquipment ?? 0}',
                            icon: Icons.construction_rounded,
                            accentColor: const Color(0xFFF28C28),
                          ),
                          DashboardStatCard(
                            label: 'Materials Issued',
                            value: _isLoading
                                ? '...'
                                : '${_summary?.materialsIssued ?? 0}',
                            icon: Icons.category_outlined,
                            accentColor: const Color(0xFF239B56),
                          ),
                          DashboardStatCard(
                            label: 'Overdue',
                            value: _isLoading
                                ? '...'
                                : '${_summary?.overdue ?? 0}',
                            icon: Icons.warning_amber_rounded,
                            accentColor: const Color(0xFFE53935),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle('Quick Actions'),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: width >= 800 ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: width >= 800 ? 2.25 : 1.55,
                        children: [
                          QuickActionCard(
                            label: 'New Transaction',
                            icon: Icons.add_circle_outline_rounded,
                            onTap: _openNewTransaction,
                          ),
                          QuickActionCard(
                            label: 'Return Items',
                            icon: Icons.assignment_return_rounded,
                            onTap: () => _open('Return Items'),
                          ),
                          QuickActionCard(
                            label: 'Enter Code',
                            icon: Icons.password_rounded,
                            onTap: () => _open('Enter Code'),
                          ),
                          QuickActionCard(
                            label: 'Items',
                            icon: Icons.inventory_rounded,
                            onTap: () => _open('Items'),
                          ),
                          QuickActionCard(
                            label: 'Reports',
                            icon: Icons.analytics_outlined,
                            onTap: () => _open('Reports'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (width >= 900)
                        Row(
                          children: [
                            Expanded(
                              child: _EmptySection(
                                title: 'Due Today',
                                message: 'No items due today.',
                                icon: Icons.event_available_outlined,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _LowStockSection(
                                items: _summary?.lowStockItems ?? const [],
                                isLoading: _isLoading,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _EmptySection(
                              title: 'Due Today',
                              message: 'No items due today.',
                              icon: Icons.event_available_outlined,
                            ),
                            const SizedBox(height: 16),
                            _LowStockSection(
                              items: _summary?.lowStockItems ?? const [],
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              return;
            case 1:
              _open('Borrowed');
            case 2:
              _open('Items');
            case 3:
              _open('Reports');
            case 4:
              _open('More');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0D5BE1),
        unselectedItemColor: const Color(0xFF66758A),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        elevation: 12,
        items: [
          for (final item in _navItems)
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Icon(item.icon, size: 23),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Icon(item.icon, size: 24),
              ),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: const Color(0xFF172033),
      fontWeight: FontWeight.w800,
    ),
  );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE3EAF2)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                Icon(icon, size: 42, color: const Color(0xFF9AAABD)),
                const SizedBox(height: 10),
                Text(message, style: const TextStyle(color: Color(0xFF66758A))),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    ),
  );
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.items, required this.isLoading});

  final List<DashboardLowStockItem> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE3E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Low Stock Items'),
            const SizedBox(height: 14),
            if (isLoading)
              const SizedBox(
                height: 82,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (items.isEmpty)
              const SizedBox(
                height: 82,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 42,
                        color: Color(0xFF9AAABD),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No low stock items.',
                        style: TextStyle(color: Color(0xFF66758A)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...items.map(_LowStockRow.new),
          ],
        ),
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow(this.item);

  final DashboardLowStockItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 42,
              height: 42,
              child: item.imageUrl == null
                  ? const ColoredBox(
                      color: Color(0xFFF0F4FA),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF60748C),
                      ),
                    )
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: Color(0xFFF0F4FA),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF60748C),
                            ),
                          ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${item.availableStock} ${item.unit} left',
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
