import 'package:flutter/material.dart';

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

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex.clamp(0, 4);

  void _selectTab(int index) {
    if (index == _currentIndex || index < 0 || index > 4) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _currentIndex,
    children: [
      DashboardScreen(onTabSelected: _selectTab, isActive: _currentIndex == 0),
      BorrowedScreen(onTabSelected: _selectTab),
      ItemsScreen(onTabSelected: _selectTab),
      ReportsScreen(onTabSelected: _selectTab),
      MoreScreen(onTabSelected: _selectTab),
    ],
  );
}
