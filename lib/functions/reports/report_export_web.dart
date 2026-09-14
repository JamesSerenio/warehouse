// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveReportXlsx(String filename, List<int> bytes) async {
  if (bytes.isEmpty) {
    throw StateError('Excel download received empty bytes.');
  }
  final data = Uint8List.fromList(bytes);
  final blob = html.Blob(<Object>[
    data,
  ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  try {
    anchor.click();
    await Future<void>.delayed(Duration.zero);
  } finally {
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
