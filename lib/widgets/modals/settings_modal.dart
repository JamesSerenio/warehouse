import 'package:flutter/material.dart';

import '../../functions/auth/login_function.dart';
import 'modal_helper.dart';

Future<void> showSettingsModal(BuildContext context) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 620,
    builder: (_) => const _SettingsModal(),
  );
}

class _SettingsModal extends StatefulWidget {
  const _SettingsModal();

  @override
  State<_SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  bool _lowStockAlerts = true;
  bool _dueTodayReminders = true;

  @override
  Widget build(BuildContext context) {
    final email = LoginFunction.getCurrentUserEmail() ?? 'No email available';
    return _ModalFrame(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(22),
        shrinkWrap: true,
        children: [
          const _SectionTitle('Notifications'),
          _SettingTile(
            icon: Icons.inventory_outlined,
            title: 'Low Stock Alerts',
            trailing: Switch(
              value: _lowStockAlerts,
              onChanged: (value) => setState(() => _lowStockAlerts = value),
            ),
          ),
          _SettingTile(
            icon: Icons.event_available_outlined,
            title: 'Due Today Reminders',
            trailing: Switch(
              value: _dueTodayReminders,
              onChanged: (value) => setState(() => _dueTodayReminders = value),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Tablet & Signature Pad'),
          const _SettingTile(
            icon: Icons.draw_outlined,
            title: 'Signature Pad',
            subtitle: 'Device: HUION HS64\nStatus: Not Connected',
          ),
          const SizedBox(height: 18),
          const _SectionTitle('System Info'),
          const _InfoRow(
            label: 'App Name',
            value: 'Warehouse Borrow & Inventory System',
          ),
          const _InfoRow(label: 'Version', value: '1.0.0'),
          _InfoRow(label: 'Logged-in email', value: email),
        ],
      ),
    );
  }
}

class _ModalFrame extends StatelessWidget {
  const _ModalFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 32,
          offset: Offset(0, 16),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 62,
          padding: const EdgeInsets.only(left: 22, right: 8),
          color: const Color(0xFF08213B),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
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
        Flexible(child: child),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0A2A4A),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE1E8F0)),
    ),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF0D5BE1)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(height: 1.45)),
      trailing: trailing,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
