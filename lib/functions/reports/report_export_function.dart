import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import 'monthly_report_function.dart';
import 'report_export_stub.dart'
    if (dart.library.html) 'report_export_web.dart'
    if (dart.library.io) 'report_export_io.dart';

class ReportExportResult {
  const ReportExportResult(this.message);
  final String message;
}

abstract final class ReportExportFunction {
  static Future<ReportExportResult> exportExcel(
    MonthlyReport report, {
    required String filterName,
  }) async {
    try {
      debugPrint('EXCEL EXPORT STARTED');
      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', 'Monthly Summary');
      _buildSummary(workbook['Monthly Summary'], report, filterName);
      _buildItems(workbook['Item Report'], report.items);
      final bytes = workbook.encode();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Excel workbook encoding returned no data.');
      }
      final month = report.month.month.toString().padLeft(2, '0');
      final filename = 'warehouse_report_${report.month.year}_$month.xlsx';
      await saveReportXlsx(filename, bytes);
      debugPrint('EXCEL EXPORT COMPLETED');
      return const ReportExportResult('Excel report exported successfully.');
    } catch (error, stackTrace) {
      debugPrint('EXCEL EXPORT ERROR: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  static void _buildSummary(
    Sheet sheet,
    MonthlyReport report,
    String filterName,
  ) {
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('B1'));
    _set(
      sheet,
      'A1',
      TextCellValue('WAREHOUSE BORROW & INVENTORY SYSTEM'),
      _titleStyle,
    );
    _set(sheet, 'A2', TextCellValue('Monthly Report'), _subtitleStyle);
    _set(sheet, 'A4', TextCellValue('Month:'), _labelStyle);
    _set(sheet, 'B4', TextCellValue(_monthLabel(report.month)));
    _set(sheet, 'A5', TextCellValue('Generated:'), _labelStyle);
    final generated = sheet.cell(CellIndex.indexByString('B5'));
    generated.value = DateTimeCellValue.fromDateTime(DateTime.now());
    generated.cellStyle = CellStyle(
      numberFormat: CustomDateTimeNumFormat(
        formatCode: 'mmm d, yyyy h:mm AM/PM',
      ),
    );
    _set(sheet, 'A6', TextCellValue('Selected Filter:'), _labelStyle);
    _set(sheet, 'B6', TextCellValue(filterName));
    _set(sheet, 'A8', TextCellValue('Metric'), _headerStyle);
    _set(sheet, 'B8', TextCellValue('Value'), _headerStyle);
    final values = <(String, int)>[
      ('Total Items', report.summary.totalItems),
      ('Tools / Equipment Borrowed', report.summary.toolsBorrowed),
      ('Materials Issued', report.summary.materialsIssued),
      ('Total Returned', report.summary.totalReturned),
      ('Overdue Items', report.summary.overdueItems),
      ('Active Transactions', report.summary.activeTransactions),
    ];
    for (var index = 0; index < values.length; index++) {
      final row = index + 9;
      _set(sheet, 'A$row', TextCellValue(values[index].$1));
      _set(sheet, 'B$row', IntCellValue(values[index].$2), _numberStyle);
    }
    sheet.setColumnWidth(0, 34);
    sheet.setColumnWidth(1, 24);
  }

  static void _buildItems(Sheet sheet, List<MonthlyItemReport> items) {
    const headings = [
      'Product Name',
      'Category / Type',
      'Unit',
      'Borrowed / Issued',
      'Returned',
      'Remaining',
      'Available',
      'Status',
    ];
    for (var column = 0; column < headings.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.value = TextCellValue(headings[column]);
      cell.cellStyle = _headerStyle;
    }
    if (items.isEmpty) {
      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('H2'));
      final emptyCell = sheet.cell(CellIndex.indexByString('A2'));
      emptyCell.value = TextCellValue('No report data for this month.');
      emptyCell.cellStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('FF64748B'),
        italic: true,
      );
    }
    for (var rowIndex = 0; rowIndex < items.length; rowIndex++) {
      final item = items[rowIndex];
      final values = <CellValue>[
        TextCellValue(item.productName),
        TextCellValue(item.typeLabel),
        TextCellValue(item.unit),
        IntCellValue(item.borrowedOrIssued),
        item.isMaterial ? TextCellValue('N/A') : IntCellValue(item.returned),
        item.isMaterial ? TextCellValue('N/A') : IntCellValue(item.remaining),
        IntCellValue(item.currentAvailable),
        TextCellValue(_status(item.status)),
      ];
      for (var column = 0; column < values.length; column++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: column,
            rowIndex: rowIndex + 1,
          ),
        );
        cell.value = values[column];
        if (column >= 3 && column <= 6 && values[column] is IntCellValue) {
          cell.cellStyle = _numberStyle;
        }
      }
    }
    const widths = [30.0, 24.0, 12.0, 20.0, 14.0, 14.0, 14.0, 22.0];
    for (var index = 0; index < widths.length; index++) {
      sheet.setColumnWidth(index, widths[index]);
    }
  }

  static void _set(
    Sheet sheet,
    String address,
    CellValue value, [
    CellStyle? style,
  ]) {
    final cell = sheet.cell(CellIndex.indexByString(address));
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }
}

final _titleStyle = CellStyle(
  bold: true,
  fontSize: 16,
  fontColorHex: ExcelColor.white,
  backgroundColorHex: ExcelColor.fromHexString('FF08213B'),
  verticalAlign: VerticalAlign.Center,
);
final _subtitleStyle = CellStyle(bold: true, fontSize: 13);
final _labelStyle = CellStyle(bold: true);
final _numberStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
final _headerStyle = CellStyle(
  bold: true,
  fontColorHex: ExcelColor.white,
  backgroundColorHex: ExcelColor.fromHexString('FF0D5BE1'),
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
);

String _monthLabel(DateTime month) {
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
  return '${months[month.month - 1]} ${month.year}';
}

String _status(ReportItemStatus status) => switch (status) {
  ReportItemStatus.active => 'ACTIVE',
  ReportItemStatus.partial => 'PARTIAL RETURN',
  ReportItemStatus.returned => 'RETURNED',
  ReportItemStatus.overdue => 'OVERDUE',
  ReportItemStatus.noReturnRequired => 'IN STOCK',
};
