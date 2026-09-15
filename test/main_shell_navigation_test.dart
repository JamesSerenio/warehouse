import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warehouse_system/config/supabase_config.dart';
import 'package:warehouse_system/screens/main_shell.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  testWidgets('bottom tabs use IndexedStack and preserve Items search state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final observer = _RouteCounter();
    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [observer], home: const MainShell()),
    );
    await tester.pump();
    final initialPushes = observer.pushes;

    await tester.tap(_bottomLabel('Items'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search items...'),
      'hammer',
    );
    await tester.tap(_bottomLabel('Reports'));
    await tester.pump();
    await tester.tap(_bottomLabel('Items'));
    await tester.pump();

    expect(find.text('hammer'), findsOneWidget);
    expect(observer.pushes, initialPushes);
    expect(find.byType(IndexedStack), findsWidgets);
  });

  testWidgets('drawer main link changes shell tab without pushing a route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final observer = _RouteCounter();
    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [observer], home: const MainShell()),
    );
    await tester.pump();
    final initialPushes = observer.pushes;

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Reports')),
    );
    await tester.pumpAndSettle();

    expect(observer.pushes, initialPushes);
    expect(find.text('Reports'), findsWidgets);
  });
}

Finder _bottomLabel(String label) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.text(label),
);

class _RouteCounter extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}
