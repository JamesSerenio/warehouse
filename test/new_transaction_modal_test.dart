import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  testWidgets('dashboard New Transaction opens and closes repeatedly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();

    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(find.text('New Transaction'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Borrower Information'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Close').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Borrower Information'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('drawer closes before New Transaction modal opens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('New Transaction'), findsWidgets);

    await tester.tap(find.text('New Transaction').last);
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Borrower Information'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard Enter Code opens and validates code format', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();

    await tester.tap(find.text('Enter Code'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Enter the 4-character transaction code.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).last, 'a7k');
    await tester.tap(find.text('SEARCH'));
    await tester.pump();
    expect(find.text('Enter the complete 4-character code.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'a@k2');
    await tester.tap(find.text('SEARCH'));
    await tester.pump();
    expect(find.text('ETS Invalid transaction code format.'), findsNothing);
    expect(find.text('Invalid transaction code format.'), findsOneWidget);
  });

  testWidgets('drawer Enter Transaction Code opens the same modal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enter Transaction Code'));
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Enter the 4-character transaction code.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
