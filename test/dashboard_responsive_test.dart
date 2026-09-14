import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warehouse_system/config/supabase_config.dart';
import 'package:warehouse_system/screens/dashboard_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  for (final size in const [Size(400, 858), Size(768, 900), Size(1024, 900)]) {
    testWidgets('dashboard has no layout overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pump();

      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('New Transaction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
