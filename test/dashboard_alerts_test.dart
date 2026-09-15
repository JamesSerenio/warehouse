import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warehouse_system/functions/dashboard/dashboard_due_today_function.dart';
import 'package:warehouse_system/functions/dashboard/dashboard_low_stock_function.dart';
import 'package:warehouse_system/functions/dashboard/dashboard_notification_function.dart';
import 'package:warehouse_system/functions/inventory/inventory_list_function.dart';
import 'package:warehouse_system/functions/notifications/notification_badge_function.dart';
import 'package:warehouse_system/functions/settings/notification_settings_function.dart';
import 'package:warehouse_system/models/dashboard_summary.dart';

void main() {
  WarehouseItem item(String name, int available, int threshold) =>
      WarehouseItem(
        id: name,
        productName: name,
        itemType: 'tool',
        unit: 'pcs',
        totalStock: 10,
        availableStock: available,
        borrowedStock: 0,
        lowStockLevel: threshold,
        isActive: true,
      );

  test('Due Today compares the Philippine UTC+8 calendar date', () {
    final now = DateTime.utc(2026, 9, 14, 16, 30); // Sep 15, 12:30 AM PH.
    expect(
      isDueTodayPhilippines(DateTime.utc(2026, 9, 14, 23), now: now),
      isTrue,
    );
    expect(
      isDueTodayPhilippines(DateTime.utc(2026, 9, 15, 16), now: now),
      isFalse,
    );
    expect(
      isDueTodayPhilippines(DateTime.utc(2026, 9, 13, 23), now: now),
      isFalse,
    );
  });

  test('Low Stock uses <= and sorts out-of-stock then quantity then name', () {
    expect(isLowStock(item('Not Low', 6, 5)), isFalse);
    expect(isLowStock(item('Equal', 5, 5)), isTrue);
    expect(isLowStock(item('Low', 3, 5)), isTrue);
    expect(isLowStock(item('Empty', 0, 5)), isTrue);

    final values = [
      DashboardLowStockItem(item: item('Zeta', 3, 5)),
      DashboardLowStockItem(item: item('Beta', 0, 5)),
      DashboardLowStockItem(item: item('Alpha', 0, 5)),
      DashboardLowStockItem(item: item('Gamma', 1, 5)),
    ]..sort(compareLowStock);
    expect(values.map((value) => value.productName), [
      'Alpha',
      'Beta',
      'Gamma',
      'Zeta',
    ]);
  });

  test('notification preferences persist with defaults enabled', () async {
    SharedPreferences.setMockInitialValues({});
    var preferences = await DashboardNotificationFunction.load();
    expect(preferences.lowStockAlerts, isTrue);
    expect(preferences.dueTodayReminders, isTrue);

    await DashboardNotificationFunction.setLowStockAlerts(false);
    await DashboardNotificationFunction.setDueTodayReminders(false);
    preferences = await DashboardNotificationFunction.load();
    expect(preferences.lowStockAlerts, isFalse);
    expect(preferences.dueTodayReminders, isFalse);
  });

  test('notification badge counts only enabled real records', () {
    final lowStockItems = [
      DashboardLowStockItem(item: item('Low', 1, 5)),
      DashboardLowStockItem(item: item('Empty', 0, 5)),
    ];
    final dueTodayItems = [
      DashboardDueTodayItem(
        transactionCode: 'E79S',
        borrowerName: 'Borrower',
        contactNumber: '09123456789',
        itemId: 'item-1',
        productName: 'Hammer',
        remainingQuantity: 1,
        unit: 'pcs',
        expectedReturnAt: DateTime.utc(2026, 9, 15),
      ),
    ];

    expect(
      NotificationBadgeFunction.calculate(
        settings: const NotificationSettings(
          lowStockAlerts: true,
          dueTodayReminders: true,
        ),
        lowStockItems: lowStockItems,
        dueTodayItems: dueTodayItems,
      ),
      3,
    );
    expect(
      NotificationBadgeFunction.calculate(
        settings: const NotificationSettings(
          lowStockAlerts: false,
          dueTodayReminders: true,
        ),
        lowStockItems: lowStockItems,
        dueTodayItems: dueTodayItems,
      ),
      1,
    );
  });

  test('notification settings use stable preference keys', () async {
    SharedPreferences.setMockInitialValues({});
    await NotificationSettingsFunction.setLowStockAlerts(false);
    await NotificationSettingsFunction.setDueTodayReminders(false);
    final storage = await SharedPreferences.getInstance();
    expect(storage.getBool('low_stock_alerts_enabled'), isFalse);
    expect(storage.getBool('due_today_reminders_enabled'), isFalse);
  });
}
