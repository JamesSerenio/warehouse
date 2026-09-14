import 'package:flutter/material.dart';

import '../functions/navigation/navigation_function.dart';
import '../functions/reports/monthly_report_function.dart';
import '../functions/reports/report_export_function.dart';
import '../functions/reports/report_filter_function.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/modals/return_code_modal.dart';
import '../widgets/modals/report_detail_modal.dart';
import '../widgets/warehouse_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded),
    (label: 'Borrowed', icon: Icons.calendar_month_outlined),
    (label: 'Items', icon: Icons.inventory_2_outlined),
    (label: 'Reports', icon: Icons.description_outlined),
    (label: 'More', icon: Icons.more_horiz_rounded),
  ];
  final _search = TextEditingController();
  late DateTime _month;
  late Future<MonthlyReport> _report;
  ReportFilter _filter = ReportFilter.allItems;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _report = MonthlyReportFunction.load(_month);
    _search.addListener(_changed);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() => setState(() {});
  void _open(String page) {
    if (page == 'Return Items') {
      _openReturnByCode();
      return;
    }
    NavigationFunction.goToPage(context, page);
  }

  Future<void> _openReturnByCode() async {
    final returned = await showReturnCodeModal(context);
    if (returned && mounted) await _reload();
  }
  Future<void> _reload() async {
    final future = MonthlyReportFunction.load(_month);
    setState(() => _report = future);
    await future;
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _report = MonthlyReportFunction.load(_month);
    });
  }

  Future<void> _logout() async {
    final loggedOut = await showLogoutConfirmationDialog(context);
    if (loggedOut && mounted) NavigationFunction.goToLogin(context);
  }

  void _bottomTap(int index) {
    switch (index) {
      case 0:
        NavigationFunction.goToDashboard(context);
      case 1:
        _open('Borrowed');
      case 2:
        _open('Items');
      case 3:
        return;
      case 4:
        _open('More');
    }
  }

  Future<void> _export(MonthlyReport report) async {
    try {
      final result = await ReportExportFunction.exportCsv(report);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to export CSV: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    drawer: WarehouseDrawer(
      currentPage: 'Reports',
      onNavigate: _open,
      onLogout: _logout,
    ),
    appBar: AppBar(
      toolbarHeight: 68,
      backgroundColor: const Color(0xFF08213B),
      foregroundColor: Colors.white,
      titleSpacing: 4,
      title: const Text(
        'Reports',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<MonthlyReport>(
        future: _report,
        builder: (context, snapshot) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            month: _month,
                            previous: () => _changeMonth(-1),
                            next: () => _changeMonth(1),
                            export: snapshot.hasData
                                ? () => _export(snapshot.data!)
                                : null,
                          ),
                          const SizedBox(height: 18),
                          if (snapshot.connectionState != ConnectionState.done)
                            const SizedBox(
                              height: 330,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (snapshot.hasError)
                            _ErrorState(
                              message: snapshot.error is MonthlyReportException
                                  ? (snapshot.error! as MonthlyReportException)
                                        .message
                                  : 'Unable to load report data.',
                              retry: _reload,
                            )
                          else
                            ..._content(context, snapshot.data!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 3,
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

  List<Widget> _content(BuildContext context, MonthlyReport report) {
    final filtered = ReportFilterFunction.apply(
      items: report.items,
      query: _search.text,
      filter: _filter,
    );
    return [
      LayoutBuilder(
        builder: (_, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 6
              : constraints.maxWidth >= 650
              ? 3
              : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 6 ? 1.12 : 1.35,
            children: [
              DashboardStatCard(
                label: 'Total Items',
                value: '${report.summary.totalItems}',
                icon: Icons.inventory_2_outlined,
                accentColor: const Color(0xFF0D5BE1),
              ),
              DashboardStatCard(
                label: 'Tools / Equipment Borrowed',
                value: '${report.summary.toolsBorrowed}',
                icon: Icons.construction_rounded,
                accentColor: const Color(0xFFF28C28),
              ),
              DashboardStatCard(
                label: 'Materials Issued',
                value: '${report.summary.materialsIssued}',
                icon: Icons.category_outlined,
                accentColor: const Color(0xFF239B56),
              ),
              DashboardStatCard(
                label: 'Total Returned',
                value: '${report.summary.totalReturned}',
                icon: Icons.assignment_return_rounded,
                accentColor: const Color(0xFF7C3AED),
              ),
              DashboardStatCard(
                label: 'Overdue Items',
                value: '${report.summary.overdueItems}',
                icon: Icons.warning_amber_rounded,
                accentColor: const Color(0xFFE53935),
              ),
              DashboardStatCard(
                label: 'Active Transactions',
                value: '${report.summary.activeTransactions}',
                icon: Icons.receipt_long_outlined,
                accentColor: const Color(0xFF0284C7),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _search,
        decoration: InputDecoration(
          hintText: 'Search item...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _search.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFD8E2EC)),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReportFilter.values
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: filter == _filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    showCheckmark: false,
                    selectedColor: const Color(0xFF0D5BE1),
                    labelStyle: TextStyle(
                      color: filter == _filter
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: Color(0xFFD8E2EC)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 14),
      if (filtered.isEmpty)
        const SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No report data for this month.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        )
      else
        ...filtered.map(
          (item) => _ReportRow(
            item: item,
            onTap: () => showReportDetailModal(context, item),
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.previous,
    required this.next,
    this.export,
  });
  final DateTime month;
  final VoidCallback previous, next;
  final VoidCallback? export;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final selector = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD8E2EC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: previous,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            SizedBox(
              width: 135,
              child: Text(
                _monthLabel(month),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: next,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      );
      final button = FilledButton.icon(
        onPressed: export,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0D5BE1),
          minimumSize: const Size(120, 48),
        ),
        icon: const Icon(Icons.download_rounded),
        label: const Text('EXPORT'),
      );
      return constraints.maxWidth < 560
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reports',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                selector,
                const SizedBox(height: 10),
                button,
              ],
            )
          : Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                selector,
                const SizedBox(width: 10),
                button,
              ],
            );
    },
  );
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.item, required this.onTap});
  final MonthlyItemReport item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: Color(0xFFE1E8F0)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (_, constraints) {
            final identity = Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: item.imageUrl == null
                        ? const _Fallback()
                        : Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _Fallback(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),
                      Text(
                        '${item.typeLabel} • ${item.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final values = Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Mini(
                  item.isMaterial ? 'Issued' : 'Borrowed',
                  '${item.borrowedOrIssued}',
                ),
                _Mini('Returned', item.isMaterial ? 'N/A' : '${item.returned}'),
                _Mini(
                  'Remaining',
                  item.isMaterial ? 'N/A' : '${item.remaining}',
                ),
                _Mini('Available', '${item.currentAvailable}'),
                _Badge(item.status),
              ],
            );
            return constraints.maxWidth < 720
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [identity, const SizedBox(height: 12), values],
                  )
                : Row(
                    children: [
                      SizedBox(width: 310, child: identity),
                      const SizedBox(width: 16),
                      Expanded(child: values),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  );
          },
        ),
      ),
    ),
  );
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.status);
  final ReportItemStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReportItemStatus.overdue => const Color(0xFFDC2626),
      ReportItemStatus.returned => const Color(0xFF168447),
      ReportItemStatus.partial => const Color(0xFFEA7600),
      ReportItemStatus.active => const Color(0xFF0D5BE1),
      ReportItemStatus.noReturnRequired => const Color(0xFF168447),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8F0FF),
    child: Center(
      child: Icon(Icons.inventory_2_outlined, color: Color(0xFF0D5BE1)),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 260,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(message),
          TextButton(onPressed: retry, child: const Text('TRY AGAIN')),
        ],
      ),
    ),
  );
}

String _monthLabel(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

String _filterLabel(ReportFilter value) => switch (value) {
  ReportFilter.allItems => 'All Items',
  ReportFilter.toolsEquipment => 'Tools / Equipment',
  ReportFilter.materials => 'Materials',
  ReportFilter.borrowed => 'Borrowed',
  ReportFilter.returned => 'Returned',
  ReportFilter.overdue => 'Overdue',
};
String _statusLabel(ReportItemStatus value) => switch (value) {
  ReportItemStatus.active => 'ACTIVE',
  ReportItemStatus.partial => 'PARTIAL RETURN',
  ReportItemStatus.returned => 'RETURNED',
  ReportItemStatus.overdue => 'OVERDUE',
  ReportItemStatus.noReturnRequired => 'IN STOCK',
};
