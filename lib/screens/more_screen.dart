import 'package:flutter/material.dart';

import '../functions/auth/login_function.dart';
import '../functions/navigation/navigation_function.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/modals/about_app_modal.dart';
import '../widgets/modals/settings_modal.dart';
import '../widgets/modals/stock_history_modal.dart';
import '../widgets/warehouse_drawer.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded),
    (label: 'Borrowed', icon: Icons.calendar_month_outlined),
    (label: 'Inventory', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.description_outlined),
    (label: 'More', icon: Icons.more_horiz_rounded),
  ];

  void _open(String page) => NavigationFunction.goToPage(context, page);

  Future<void> _logout() async {
    final didLogout = await showLogoutConfirmationDialog(context);
    if (!mounted || !didLogout) return;
    NavigationFunction.goToLogin(context);
  }

  void _onBottomNavigationTap(int index) {
    switch (index) {
      case 0:
        NavigationFunction.goToDashboard(context);
      case 1:
        _open('Borrowed');
      case 2:
        _open('Inventory');
      case 3:
        _open('Reports');
      case 4:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = LoginFunction.getCurrentUserEmail() ?? 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: WarehouseDrawer(
        currentPage: 'More',
        onNavigate: _open,
        onLogout: _logout,
      ),
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: const Color(0xFF08213B),
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Text(
          'More',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UserCard(email: email),
                const SizedBox(height: 22),
                _MoreMenuTile(
                  icon: Icons.history_rounded,
                  label: 'Stock History',
                  onTap: () => showStockHistoryModal(context),
                ),
                const SizedBox(height: 10),
                _MoreMenuTile(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () => showSettingsModal(context),
                ),
                const SizedBox(height: 10),
                _MoreMenuTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About App',
                  onTap: () => showAboutAppModal(context),
                ),
                const SizedBox(height: 10),
                _MoreMenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDanger: true,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: _onBottomNavigationTap,
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

class _UserCard extends StatelessWidget {
  const _UserCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2A4A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A08213B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFF174A74),
            child: Icon(Icons.person_outline_rounded, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logged in as',
                  style: TextStyle(color: Color(0xFFAFC1D6), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final accent = isDanger ? const Color(0xFFEF4444) : const Color(0xFF0D5BE1);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFF1F5FA),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E8F0)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDanger
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDanger
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF172033),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
