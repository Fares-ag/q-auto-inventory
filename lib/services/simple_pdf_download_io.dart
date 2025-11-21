// lib/services/simple_pdf_download_io.dart

import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class SimplePdfDownload {
  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    await Share.shareXFiles([
      XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')
    ]);
  }
}
