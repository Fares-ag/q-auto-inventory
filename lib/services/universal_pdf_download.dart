// lib/services/universal_pdf_download.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'package:share_plus/share_plus.dart' as share_plus;

class UniversalPdfDownload {
  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      await _downloadForWeb(bytes, filename);
    } else {
      await _downloadForMobile(bytes, filename);
    }
  }

  static Future<void> _downloadForWeb(Uint8List bytes, String filename) async {
    // Web implementation
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _downloadForMobile(Uint8List bytes, String filename) async {
    // Mobile implementation using share_plus
    await share_plus.Share.shareXFiles([
      share_plus.XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')
    ]);
  }
}

 


