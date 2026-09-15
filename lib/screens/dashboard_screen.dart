import 'package:flutter/material.dart';

import '../functions/dashboard/dashboard_notification_function.dart';
import '../functions/dashboard/dashboard_summary_function.dart';
import '../functions/transactions/enter_code_function.dart';
import '../functions/navigation/navigation_function.dart';
import '../models/dashboard_summary.dart';
import '../widgets/modals/add_item_modal.dart';
import '../widgets/modals/enter_code_modal.dart';
import '../widgets/modals/new_transaction_modal.dart';
import '../widgets/modals/notifications_modal.dart';
import '../widgets/modals/transaction_details_modal.dart';
import '../widgets/modals/view_item_modal.dart';
import 'borrowed_screen.dart';
import 'items_screen.dart';
import 'more_screen.dart';
import 'reports_screen.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/modals/return_items_list_modal.dart';
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
  DashboardNotificationPreferences _notificationPreferences =
      DashboardNotificationFunction.preferences.value;

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
    DashboardNotificationFunction.preferences.addListener(
      _notificationPreferencesChanged,
    );
    DashboardNotificationFunction.load();
    _refreshDashboard();
  }

  @override
  void dispose() {
    DashboardNotificationFunction.preferences.removeListener(
      _notificationPreferencesChanged,
    );
    super.dispose();
  }

  void _notificationPreferencesChanged() {
    if (!mounted) return;
    setState(() {
      _notificationPreferences =
          DashboardNotificationFunction.preferences.value;
    });
  }

  Future<void> _openNotifications({
    bool? showLowStock,
    bool? showDueToday,
  }) async {
    final summary = _summary;
    if (summary == null) return;
    await showNotificationsModal(
      context,
      lowStockItems: summary.lowStockItems,
      dueTodayItems: summary.dueTodayItems,
      showLowStock: showLowStock ?? _notificationPreferences.lowStockAlerts,
      showDueToday: showDueToday ?? _notificationPreferences.dueTodayReminders,
    );
    if (mounted) await _refreshDashboard();
  }

  Future<void> _openDueTodayItem(DashboardDueTodayItem item) async {
    try {
      final transaction = await EnterCodeFunction.findTransaction(
        item.transactionCode,
      );
      if (!mounted) return;
      await showTransactionDetailsModal(context, transaction: transaction);
      if (mounted) await _refreshDashboard();
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD DUE TODAY DETAILS ERROR: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load transaction details.')),
        );
      }
    }
  }

  Future<void> _openLowStockItem(DashboardLowStockItem item) async {
    await showViewItemModal(context, item.item);
    if (mounted) await _refreshDashboard();
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

  Future<void> _openEnterCode() async {
    debugPrint('ENTER CODE TAP STARTED');
    try {
      await showEnterCodeModal(context);
      if (mounted) await _refreshDashboard();
      debugPrint('ENTER CODE FLOW CLOSED');
    } catch (error, stackTrace) {
      debugPrint('ENTER CODE ERROR: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Enter Transaction Code.')),
      );
    }
  }

  Future<void> _openNewTransaction() async {
    debugPrint('NEW TRANSACTION TAP STARTED');
    try {
      final saved = await showNewTransactionModal(context);
      debugPrint('NEW TRANSACTION MODAL CLOSED');
      if (saved && mounted) await _refreshDashboard();
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
    if (title == 'Enter Code' || title == 'Enter Transaction Code') {
      await _openEnterCode();
      return;
    }
    if (title == 'Return Items') {
      final returned = await showReturnItemsListModal(context);
      if (returned && mounted) await _refreshDashboard();
      return;
    }
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
      final destination = switch (title) {
        'Borrowed' => const BorrowedScreen(),
        'Reports' => const ReportsScreen(),
        'More' => const MoreScreen(),
        _ => null,
      };
      if (destination == null) {
        NavigationFunction.goToPage(context, title);
        return;
      }
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => destination));
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
        title: const Row(
          children: [
            Expanded(
              child: Text(
                'Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          _NotificationBell(
            count: _notificationPreferences.lowStockAlerts
                ? _summary?.lowStockItems.length ?? 0
                : 0,
            onTap: _isLoading ? null : _openNotifications,
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
              padding: EdgeInsets.all(width < 600 ? 16 : 20),
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
                        childAspectRatio: width >= 900
                            ? 1.75
                            : width <= 500
                            ? 1.35
                            : 1.55,
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
                        childAspectRatio: width >= 800
                            ? 2.25
                            : width <= 500
                            ? 1.45
                            : 1.55,
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
                            onTap: _openEnterCode,
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
                              child: _DueTodaySection(
                                items: _summary?.dueTodayItems ?? const [],
                                isLoading: _isLoading,
                                onTap: _openDueTodayItem,
                                onViewAll: () => _openNotifications(
                                  showLowStock: false,
                                  showDueToday: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _LowStockSection(
                                items: _summary?.lowStockItems ?? const [],
                                isLoading: _isLoading,
                                onTap: _openLowStockItem,
                                onViewAll: () => _openNotifications(
                                  showLowStock: true,
                                  showDueToday: false,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _DueTodaySection(
                              items: _summary?.dueTodayItems ?? const [],
                              isLoading: _isLoading,
                              onTap: _openDueTodayItem,
                              onViewAll: () => _openNotifications(
                                showLowStock: false,
                                showDueToday: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LowStockSection(
                              items: _summary?.lowStockItems ?? const [],
                              isLoading: _isLoading,
                              onTap: _openLowStockItem,
                              onViewAll: () => _openNotifications(
                                showLowStock: true,
                                showDueToday: false,
                              ),
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

class _DueTodaySection extends StatelessWidget {
  const _DueTodaySection({
    required this.items,
    required this.isLoading,
    required this.onTap,
    required this.onViewAll,
  });

  final List<DashboardDueTodayItem> items;
  final bool isLoading;
  final ValueChanged<DashboardDueTodayItem> onTap;
  final VoidCallback onViewAll;

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
          _SectionHeader(
            title: 'Due Today',
            showViewAll: items.length > 5,
            onViewAll: onViewAll,
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const _SectionLoader()
          else if (items.isEmpty)
            const SizedBox(
              height: 82,
              child: Center(
                child: Text(
                  'No items due today.',
                  style: TextStyle(color: Color(0xFF66758A)),
                ),
              ),
            )
          else
            ...items
                .take(5)
                .map(
                  (item) => InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onTap(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          _DashboardProductImage(
                            imageUrl: item.imageUrl,
                            fallback: Icons.construction_rounded,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF172033),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${item.transactionCode} • ${item.borrowerName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.remainingQuantity} ${item.unit}',
                                style: const TextStyle(
                                  color: Color(0xFF0D5BE1),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Due ${_philippineTime(item.expectedReturnAt)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
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
    ),
  );
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({
    required this.items,
    required this.isLoading,
    required this.onTap,
    required this.onViewAll,
  });

  final List<DashboardLowStockItem> items;
  final bool isLoading;
  final ValueChanged<DashboardLowStockItem> onTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Card(
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
          _SectionHeader(
            title: 'Low Stock Items',
            showViewAll: items.length > 5,
            onViewAll: onViewAll,
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const _SectionLoader()
          else if (items.isEmpty)
            const SizedBox(
              height: 82,
              child: Center(
                child: Text(
                  'No low stock items.',
                  style: TextStyle(color: Color(0xFF66758A)),
                ),
              ),
            )
          else
            ...items
                .take(5)
                .map(
                  (item) => _LowStockRow(item: item, onTap: () => onTap(item)),
                ),
        ],
      ),
    ),
  );
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.item, required this.onTap});

  final DashboardLowStockItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _DashboardProductImage(
            imageUrl: item.imageUrl,
            fallback: Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Alert level: ${item.lowStockLevel} ${item.unit}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.availableStock} ${item.unit} left',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                item.isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                style: TextStyle(
                  color: item.isOutOfStock
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFFD97706),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.showViewAll,
    required this.onViewAll,
  });
  final String title;
  final bool showViewAll;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _SectionTitle(title)),
      if (showViewAll)
        TextButton(onPressed: onViewAll, child: const Text('View All')),
    ],
  );
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 82,
    child: Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
}

class _DashboardProductImage extends StatelessWidget {
  const _DashboardProductImage({
    required this.imageUrl,
    required this.fallback,
  });
  final String? imageUrl;
  final IconData fallback;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 44,
      height: 44,
      child: imageUrl == null
          ? _fallback
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback,
            ),
    ),
  );

  Widget get _fallback => ColoredBox(
    color: const Color(0xFFF0F4FA),
    child: Icon(fallback, color: const Color(0xFF60748C)),
  );
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        tooltip: 'Notifications',
        onPressed: onTap,
        icon: const Icon(Icons.notifications_none_rounded),
      ),
      if (count > 0)
        Positioned(
          right: 3,
          top: 3,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF08213B), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
    ],
  );
}

String _philippineTime(DateTime value) {
  final local = value.toUtc().add(const Duration(hours: 8));
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}
