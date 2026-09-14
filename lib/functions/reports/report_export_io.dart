import 'dart:io';

Future<void> saveReportXlsx(String filename, List<int> bytes) async {
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$filename',
  );
  await file.writeAsBytes(bytes, flush: true);
}
