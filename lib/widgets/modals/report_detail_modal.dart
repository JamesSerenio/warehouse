import 'package:flutter/material.dart';

import '../../functions/reports/monthly_report_function.dart';
import '../../functions/reports/report_detail_function.dart';
import 'modal_helper.dart';

Future<void> showReportDetailModal(
  BuildContext context,
  MonthlyItemReport item,
) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 820,
    builder: (_) => _ReportDetailModal(item: item),
  );
}

class _ReportDetailModal extends StatelessWidget {
  const _ReportDetailModal({required this.item});
  final MonthlyItemReport item;

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
                  'Report Detail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: item.imageUrl == null
                            ? const _Fallback()
                            : Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const _Fallback(),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${item.typeLabel} • ${item.unit}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      item.isMaterial ? 'Issued' : 'Borrowed',
                      item.borrowedOrIssued,
                    ),
                    _Metric('Returned', item.isMaterial ? null : item.returned),
                    _Metric(
                      'Remaining',
                      item.isMaterial ? null : item.remaining,
                    ),
                    _Metric('Current Available', item.currentAvailable),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Related Transaction History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 10),
                if (item.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No transaction history for this month.'),
                    ),
                  )
                else
                  ...ReportDetailFunction.sortedHistory(item).map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Wrap(
                        spacing: 22,
                        runSpacing: 7,
                        children: [
                          _Value('Code', entry.transactionCode),
                          _Value('Borrower', entry.borrowerName),
                          _Value('Quantity', '${entry.quantity} ${item.unit}'),
                          _Value('Date', _date(entry.createdAt)),
                          _Value('Status', _status(entry.status)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final int? value;
  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FB),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? 'N/A',
          style: const TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 125,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
        size: 38,
      ),
    ),
  );
}

String _date(DateTime? value) => value == null
    ? 'Not available'
    : '${value.toLocal().month}/${value.toLocal().day}/${value.toLocal().year}';
String _status(ReportItemStatus status) => switch (status) {
  ReportItemStatus.active => 'Active',
  ReportItemStatus.partial => 'Partial Return',
  ReportItemStatus.returned => 'Returned',
  ReportItemStatus.overdue => 'Overdue',
  ReportItemStatus.noReturnRequired => 'No return required',
};
