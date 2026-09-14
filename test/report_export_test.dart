import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_system/functions/reports/monthly_report_function.dart';
import 'package:warehouse_system/functions/reports/report_export_function.dart';

void main() {
  test('exports a valid two-sheet XLSX workbook', () async {
    final report = MonthlyReport(
      month: DateTime(2026, 9),
      summary: const ReportSummary(
        totalItems: 15,
        toolsBorrowed: 4,
        materialsIssued: 5,
        totalReturned: 1,
        overdueItems: 0,
        activeTransactions: 1,
      ),
      items: const [
        MonthlyItemReport(
          itemId: 'tool-1',
          productName: 'Claw Hammer',
          itemType: 'tool',
          unit: 'pcs',
          currentAvailable: 7,
          borrowedOrIssued: 4,
          returned: 1,
          remaining: 3,
          status: ReportItemStatus.partial,
          history: [],
        ),
        MonthlyItemReport(
          itemId: 'material-1',
          productName: 'Solar Street Light 200W',
          itemType: 'material',
          unit: 'pcs',
          currentAvailable: 45,
          borrowedOrIssued: 5,
          returned: 0,
          remaining: 0,
          status: ReportItemStatus.noReturnRequired,
          history: [],
        ),
      ],
    );

    await ReportExportFunction.exportExcel(report, filterName: 'All Items');
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'warehouse_report_2026_09.xlsx',
    );
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    final bytes = await file.readAsBytes();
    expect(bytes.take(2), orderedEquals([0x50, 0x4B]));
    final workbook = Excel.decodeBytes(bytes);
    expect(
      workbook.tables.keys,
      containsAll(['Monthly Summary', 'Item Report']),
    );
    expect(
      workbook['Monthly Summary'].cell(CellIndex.indexByString('B9')).value,
      const IntCellValue(15),
    );
    expect(
      workbook['Item Report'].cell(CellIndex.indexByString('E3')).value,
      isA<TextCellValue>(),
    );
  });
}
