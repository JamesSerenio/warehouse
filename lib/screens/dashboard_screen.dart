import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/warehouse_drawer.dart';
import 'login_screen.dart';
import 'placeholder_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded),
    (label: 'Borrowed', icon: Icons.calendar_month_outlined),
    (label: 'Inventory', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.description_outlined),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
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
