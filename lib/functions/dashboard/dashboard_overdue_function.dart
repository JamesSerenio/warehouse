import 'package:flutter/foundation.dart';

abstract final class DashboardOverdueFunction {
  static Future<int> load() async {
    debugPrint(
      'DASHBOARD OVERDUE: transaction tables are not implemented yet.',
    );
    return 0;
  }
}
