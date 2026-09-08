import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../functions/auth/login_function.dart';
import '../functions/navigation/drawer_function.dart';

class WarehouseDrawer extends StatelessWidget {
  const WarehouseDrawer({
    super.key,
    required this.currentPage,
    required this.onNavigate,
    required this.onLogout,
  });

  final String currentPage;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  static const _navy = Color(0xFF08213B);
  static const _hover = Color(0xFF123B5D);
  static const _primary = Color(0xFF0D5BE1);

  void _navigate(BuildContext context, String page) {
    if (page == 'New Transaction' || page == 'Enter Transaction Code') {
      DrawerFunction.close(context);
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        onNavigate(page);
      });
      return;
    }
    DrawerFunction.handleSelection(
      context: context,
      currentPage: currentPage,
      selectedPage: page,
      onNavigate: onNavigate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = LoginFunction.getCurrentUserEmail() ?? 'No email available';
    final drawerWidth = math.min(MediaQuery.sizeOf(context).width * .85, 320.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: _navy,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            _BrandHeader(onClose: () => DrawerFunction.close(context)),
            const Divider(height: 1, color: Color(0xFF1D4162)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                children: [
                  _item(context, 'Dashboard', Icons.dashboard_rounded),
                  _item(
                    context,
                    'New Transaction',
                    Icons.add_circle_outline_rounded,
                  ),
                  _item(
                    context,
                    'Return Items',
                    Icons.assignment_return_rounded,
                  ),
                  _item(
                    context,
                    'Enter Transaction Code',
                    Icons.qr_code_2_rounded,
                  ),
                  const _MenuDivider(),
                  _item(context, 'Items', Icons.inventory_2_outlined),
                  _item(context, 'Add Item', Icons.add_box_outlined),
                  _item(context, 'Stock History', Icons.history_rounded),
                  const _MenuDivider(),
                  _item(context, 'Reports', Icons.bar_chart_rounded),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1D4162)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: _DrawerItem(
                label: 'Logout',
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFFF6B6B),
                textColor: const Color(0xFFFF8A8A),
                onTap: () {
                  DrawerFunction.close(context);
                  onLogout();
                },
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2A47),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF204766)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFF174A74),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 21,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logged in as',
                          style: TextStyle(
                            color: Color(0xFF91A9C0),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String label, IconData icon) {
    return _DrawerItem(
      label: label,
      icon: icon,
      selected: DrawerFunction.isSelected(
        currentPage: currentPage,
        itemPage: label,
      ),
      onTap: () => _navigate(context, label),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF103B61),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF31658E)),
              ),
              child: const Icon(
                Icons.warehouse_outlined,
                color: Colors.white,
                size: 33,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAREHOUSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Borrow & Inventory System',
                    maxLines: 1,
                    style: TextStyle(color: Color(0xFFAFC1D6), fontSize: 10.5),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close menu',
              onPressed: onClose,
              color: const Color(0xFFD8E4F0),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.iconColor,
    this.textColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFFD8E4F0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? WarehouseDrawer._primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: WarehouseDrawer._hover,
          splashColor: const Color(0x334B91FF),
          child: SizedBox(
            height: 43,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  Icon(icon, size: 21, color: iconColor ?? foreground),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor ?? foreground,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: Color(0xFF1D4162)),
    );
  }
}
