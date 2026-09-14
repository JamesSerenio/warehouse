import 'monthly_report_function.dart';
import 'report_export_stub.dart'
    if (dart.library.html) 'report_export_web.dart'
    if (dart.library.io) 'report_export_io.dart';

class ReportExportResult {
  const ReportExportResult(this.message);
  final String message;
}

abstract final class ReportExportFunction {
  static Future<ReportExportResult> exportCsv(MonthlyReport report) async {
    final buffer = StringBuffer()
      ..writeln(
        'Product Name,Category,Unit,Issued or Borrowed,Returned,Remaining,Current Available,Status',
      );
    for (final item in report.items) {
      buffer.writeln(
        [
          _csv(item.productName),
          _csv(item.typeLabel),
          _csv(item.unit),
          item.borrowedOrIssued,
          item.isMaterial ? 'N/A' : item.returned,
          item.isMaterial ? 'N/A' : item.remaining,
          item.currentAvailable,
          _csv(_status(item.status)),
        ].join(','),
      );
    }
    final month = report.month.month.toString().padLeft(2, '0');
    final filename = 'warehouse_report_${report.month.year}_$month.csv';
    final message = await saveReportCsv(filename, buffer.toString());
    return ReportExportResult(message);
  }
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';
String _status(ReportItemStatus status) => switch (status) {
  ReportItemStatus.active => 'Active',
  ReportItemStatus.partial => 'Partial Return',
  ReportItemStatus.returned => 'Returned',
  ReportItemStatus.overdue => 'Overdue',
  ReportItemStatus.noReturnRequired => 'No return required',
};
