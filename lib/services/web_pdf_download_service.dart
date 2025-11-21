// lib/services/web_pdf_download_service.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// Web-specific imports (only available on web)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// Mobile-specific imports
import 'package:share_plus/share_plus.dart' as share_plus;

class WebPdfDownloadService {
  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      await _downloadForWeb(bytes, filename);
    } else {
      await _downloadForMobile(bytes, filename);
    }
  }

  static Future<void> _downloadForWeb(Uint8List bytes, String filename) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _downloadForMobile(Uint8List bytes, String filename) async {
    await share_plus.Share.shareXFiles([
      share_plus.XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')
    ]);
  }
}


