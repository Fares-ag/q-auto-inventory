import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QrDownloadService {
  static Future<void> downloadQrCode(String data, String assetId) async {
    try {
      final qrCode = QrPainter(
        data: data,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      const size = 512.0;
      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      qrCode.paint(canvas, const Size(size, size));
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_$assetId.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code for $assetId',
      );
    } catch (e) {
      throw Exception('Failed to generate QR code image: $e');
    }
  }
}
