import 'package:flutter/material.dart';

import '../widgets/animations/animation_constants.dart';
import 'borrowed_screen.dart';
import 'dashboard_screen.dart';
import 'items_screen.dart';
import 'more_screen.dart';
import 'reports_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex = widget.initialIndex.clamp(0, 4);
  late final AnimationController _tabController = AnimationController(
    vsync: this,
    duration: AppAnimationDurations.normal,
    value: 1,
  );
  late final Animation<double> _tabOpacity = Tween<double>(begin: .88, end: 1)
      .animate(
        CurvedAnimation(
          parent: _tabController,
          curve: AppAnimationCurves.standard,
        ),
      );

  void _selectTab(int index) {
    if (index == _currentIndex || index < 0 || index > 4) return;
    setState(() => _currentIndex = index);
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _tabController.value = 1;
    } else {
      _tabController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _tabOpacity,
    child: IndexedStack(
      index: _currentIndex,
      children: [
        DashboardScreen(
          onTabSelected: _selectTab,
          isActive: _currentIndex == 0,
        ),
        BorrowedScreen(onTabSelected: _selectTab),
        ItemsScreen(onTabSelected: _selectTab),
        ReportsScreen(onTabSelected: _selectTab),
        MoreScreen(onTabSelected: _selectTab),
      ],
    ),
  );
}
