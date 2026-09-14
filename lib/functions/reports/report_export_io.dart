import 'dart:io';

Future<String> saveReportCsv(String filename, String csv) async {
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$filename',
  );
  await file.writeAsString(csv, flush: true);
  return 'CSV saved to ${file.path}';
}
