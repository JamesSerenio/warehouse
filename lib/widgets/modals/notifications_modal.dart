import 'package:flutter/material.dart';

import '../../functions/transactions/enter_code_function.dart';
import '../../models/dashboard_summary.dart';
import '../animations/animated_list_item.dart';
import 'modal_helper.dart';
import 'transaction_details_modal.dart';
import 'view_item_modal.dart';

Future<void> showNotificationsModal(
  BuildContext context, {
  required List<DashboardLowStockItem> lowStockItems,
  required List<DashboardDueTodayItem> dueTodayItems,
  required bool showLowStock,
  required bool showDueToday,
}) async {
  final selection = await showWarehouseModal<Object>(
    context: context,
    maxWidth: 720,
    builder: (_) => _NotificationsModal(
      lowStockItems: lowStockItems,
      dueTodayItems: dueTodayItems,
      showLowStock: showLowStock,
      showDueToday: showDueToday,
    ),
  );
  if (selection == null || !context.mounted) return;
  if (selection is DashboardLowStockItem) {
    await showViewItemModal(context, selection.item);
    return;
  }
  if (selection is DashboardDueTodayItem) {
    try {
      final transaction = await EnterCodeFunction.findTransaction(
        selection.transactionCode,
      );
      if (context.mounted) {
        await showTransactionDetailsModal(context, transaction: transaction);
      }
    } catch (error, stackTrace) {
      debugPrint('DUE TODAY DETAILS ERROR: $error');
      debugPrint('$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load transaction details.')),
        );
      }
    }
  }
}

class _NotificationsModal extends StatelessWidget {
  const _NotificationsModal({
    required this.lowStockItems,
    required this.dueTodayItems,
    required this.showLowStock,
    required this.showDueToday,
  });

  final List<DashboardLowStockItem> lowStockItems;
  final List<DashboardDueTodayItem> dueTodayItems;
  final bool showLowStock;
  final bool showDueToday;

  bool get _hasNoEnabledAlerts =>
      (!showLowStock || lowStockItems.isEmpty) &&
      (!showDueToday || dueTodayItems.isEmpty);

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
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: _content(context),
          ),
        ),
      ],
    ),
  );

  List<Widget> _content(BuildContext context) {
    if (!showLowStock && !showDueToday) {
      return const [_EmptyMessage('Notifications are disabled in Settings.')];
    }
    if (_hasNoEnabledAlerts) {
      return const [_EmptyMessage('No notifications right now.')];
    }

    var animationIndex = 0;
    return [
      if (showLowStock) ...[
        const _SectionHeading(
          icon: Icons.inventory_2_outlined,
          label: 'LOW STOCK',
          color: Color(0xFFE53935),
        ),
        const SizedBox(height: 8),
        if (lowStockItems.isEmpty)
          const _EmptyMessage('No low stock alerts.')
        else
          ...lowStockItems.map(
            (item) => AnimatedListItem(
              index: animationIndex++,
              child: _AlertTile(
                imageUrl: item.imageUrl,
                fallbackIcon: Icons.inventory_2_outlined,
                title: item.productName,
                details: item.isOutOfStock
                    ? '0 ${item.unit} remaining'
                    : '${item.availableStock} ${item.unit} remaining\n'
                          'Low stock level: ${item.lowStockLevel} ${item.unit}',
                status: item.isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                danger: true,
                onTap: () => Navigator.pop(context, item),
              ),
            ),
          ),
      ],
      if (showLowStock && showDueToday) const SizedBox(height: 22),
      if (showDueToday) ...[
        const _SectionHeading(
          icon: Icons.event_available_outlined,
          label: 'DUE TODAY',
          color: Color(0xFF0D5BE1),
        ),
        const SizedBox(height: 8),
        if (dueTodayItems.isEmpty)
          const _EmptyMessage('No items due today.')
        else
          ...dueTodayItems.map(
            (item) => AnimatedListItem(
              index: animationIndex++,
              child: _AlertTile(
                imageUrl: item.imageUrl,
                fallbackIcon: Icons.construction_rounded,
                title: '${item.transactionCode} • ${item.productName}',
                details:
                    '${item.borrowerName}\n${item.remainingQuantity} ${item.unit} remaining • Due ${_time(item.expectedReturnAt)}',
                status: 'DUE TODAY',
                onTap: () => Navigator.pop(context, item),
              ),
            ),
          ),
      ],
    ];
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: color),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.fallbackIcon,
    required this.title,
    required this.details,
    required this.status,
    required this.onTap,
    this.imageUrl,
    this.danger = false,
  });
  final String? imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String details;
  final String status;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    color: const Color(0xFFF8FAFC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ProductImage(imageUrl: imageUrl, fallbackIcon: fallbackIcon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    details,
                    style: TextStyle(
                      color: danger
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: danger ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(label: status, danger: danger),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.danger});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFE8F0FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? const Color(0xFFDC2626) : const Color(0xFF0D5BE1),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl, required this.fallbackIcon});
  final String? imageUrl;
  final IconData fallbackIcon;

  Widget get _fallback => ColoredBox(
    color: const Color(0xFFE8F0FF),
    child: Icon(fallbackIcon, color: const Color(0xFF0D5BE1)),
  );

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 48,
      height: 48,
      child: imageUrl == null
          ? _fallback
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, synchronous) =>
                  AnimatedOpacity(
                    opacity: synchronous || frame != null ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: child,
                  ),
              errorBuilder: (_, _, _) => _fallback,
            ),
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF64748B)),
    ),
  );
}

String _time(DateTime value) {
  final local = value.toUtc().add(const Duration(hours: 8));
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}
