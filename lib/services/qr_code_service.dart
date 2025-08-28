// lib/services/qr_code_service.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class QrCodeService {
  /// Generates a QR code widget for the given data.
  static Widget generateQrCodeWidget(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      backgroundColor: Colors.white,
    );
  }

  /// Generates a PNG image of the QR code for the given data and saves it to device storage.
  /// Returns the file path of the saved image.
  static Future<String?> generateAndSaveQrCode(String data,
      {String? fileName}) async {
    try {
      // Request storage permission (handle Android 13+)
      print('[QrCodeService] Requesting storage/media permission...');
      PermissionStatus status;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        print('[QrCodeService] Storage/media permission denied.');
        return null;
      }

      // Generate QR code as a widget
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status != QrValidationStatus.valid) return null;

      final qrCode = qrValidationResult.qrCode;
      final painter = QrPainter.withQr(
        qr: qrCode!,
        color: Colors.black,
        emptyColor: Colors.white,
        gapless: false,
      );
      final imageData = await painter.toImageData(400);

      // Get app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final qrFileName =
          fileName ?? 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$qrFileName';

      // Save PNG file
      final file = File(filePath);
      await file.writeAsBytes(imageData!.buffer.asUint8List());

      print('[QrCodeService] QR code saved at: $filePath');
      return filePath;
    } catch (e) {
      print('[QrCodeService] Error generating QR code: $e');
      return null;
    }
  }
}
