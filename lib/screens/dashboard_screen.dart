import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/quick_action_card.dart';
import 'login_screen.dart';
import 'placeholder_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _navItems = [
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Borrowed', icon: Icons.assignment_return_outlined),
    (label: 'Inventory', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.bar_chart_rounded),
    (label: 'More', icon: Icons.more_horiz_rounded),
  ];
  final _supabaseService = SupabaseService();
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _supabaseService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  void _open(String title) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PlaceholderScreen(title: title)),
  );

  void _onNavTap(int index) {
    if (index == 0) return;
    if (index == 4) {
      _showMoreMenu();
    } else {
      _open(_navItems[index].label);
    }
  }

  Future<void> _showMoreMenu() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'More',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Stock History'),
              onTap: () {
                Navigator.pop(sheetContext);
                _open('Stock History');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                _open('Settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(sheetContext);
                _logout();
              },
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _DashboardDrawer(onOpen: _open, onLogout: _logout),
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: const Color(0xFF08213B),
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WAREHOUSE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            Text(
              'Borrow & Inventory System',
              style: TextStyle(fontSize: 11, color: Color(0xFFB7C8DC)),
            ),
          ],
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
          return SingleChildScrollView(
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
                      children: const [
                        DashboardStatCard(
                          label: 'Total Items',
                          value: '0',
                          icon: Icons.inventory_2_outlined,
                          accentColor: Color(0xFF0D5BE1),
                        ),
                        DashboardStatCard(
                          label: 'Tools / Equipment Borrowed',
                          value: '0',
                          icon: Icons.construction_rounded,
                          accentColor: Color(0xFFF28C28),
                        ),
                        DashboardStatCard(
                          label: 'Materials Issued',
                          value: '0',
                          icon: Icons.category_outlined,
                          accentColor: Color(0xFF239B56),
                        ),
                        DashboardStatCard(
                          label: 'Overdue',
                          value: '0',
                          icon: Icons.warning_amber_rounded,
                          accentColor: Color(0xFFE53935),
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
                          onTap: () => _open('New Transaction'),
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
                          label: 'Inventory',
                          icon: Icons.inventory_rounded,
                          onTap: () => _open('Inventory'),
                        ),
                        QuickActionCard(
                          label: 'Add Stock',
                          icon: Icons.add_box_outlined,
                          onTap: () => _open('Add Stock'),
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
                      const Row(
                        children: [
                          Expanded(
                            child: _EmptySection(
                              title: 'Due Today',
                              message: 'No items due today.',
                              icon: Icons.event_available_outlined,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _EmptySection(
                              title: 'Low Stock Items',
                              message: 'No low stock items.',
                              icon: Icons.inventory_outlined,
                            ),
                          ),
                        ],
                      )
                    else
                      const Column(
                        children: [
                          _EmptySection(
                            title: 'Due Today',
                            message: 'No items due today.',
                            icon: Icons.event_available_outlined,
                          ),
                          SizedBox(height: 16),
                          _EmptySection(
                            title: 'Low Stock Items',
                            message: 'No low stock items.',
                            icon: Icons.inventory_outlined,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: _onNavTap,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCE9FF),
        destinations: [
          for (final item in _navItems)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({required this.onOpen, required this.onLogout});
  final ValueChanged<String> onOpen;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Drawer(
    child: Column(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFF08213B)),
          child: Row(
            children: [
              Icon(Icons.warehouse_rounded, color: Colors.white, size: 44),
              SizedBox(width: 14),
              Text(
                'WAREHOUSE\nSYSTEM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const ListTile(
          selected: true,
          leading: Icon(Icons.dashboard_rounded),
          title: Text('Dashboard'),
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Inventory'),
          onTap: () {
            Navigator.pop(context);
            onOpen('Inventory');
          },
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart_rounded),
          title: const Text('Reports'),
          onTap: () {
            Navigator.pop(context);
            onOpen('Reports');
          },
        ),
        const Spacer(),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text('Logout'),
          onTap: () {
            Navigator.pop(context);
            onLogout();
          },
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
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
