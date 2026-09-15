import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warehouse_system/config/supabase_config.dart';
import 'package:warehouse_system/screens/dashboard_screen.dart';
import 'package:warehouse_system/screens/more_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  testWidgets('drawer and More open the same Stock History modal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stock History'));
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.text('Search item or reference...'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const MaterialApp(home: MoreScreen()));
    await tester.pump();
    await tester.tap(find.text('Stock History'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Search item or reference...'), findsOneWidget);
  });
}
