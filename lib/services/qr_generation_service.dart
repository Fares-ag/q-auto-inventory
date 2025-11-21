import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/firestore_models.dart';
import 'image_upload_service.dart';

/// Service for generating and storing QR codes
class QrGenerationService {
  /// Generate QR code image bytes for an item
  static Future<Uint8List> generateQrCodeImage(InventoryItem item) async {
    try {
      final qrData = jsonEncode({
        'itemId': item.id,
        'assetId': item.assetId,
        'name': item.name,
      });

      final qrValidationResult = QrValidator.validate(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('Failed to validate QR code data');
      }

      const size = 512.0;
      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        color: const ui.Color(0xFF000000),
        emptyColor: const ui.Color(0xFFFFFFFF),
        gapless: true,
      );

      final picData = await painter.toImageData(
        size,
        format: ui.ImageByteFormat.png,
      );

      if (picData == null) {
        throw Exception('Failed to generate QR code image');
      }

      return picData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating QR code: $e');
      rethrow;
    }
  }

  /// Generate QR code and upload to Firebase Storage
  static Future<String> generateAndUploadQrCode(InventoryItem item) async {
    try {
      // Generate QR code image
      final qrBytes = await generateQrCodeImage(item);

      // Create temporary file
      final tempDir = await Directory.systemTemp.createTemp('qr_codes');
      final file = File('${tempDir.path}/qr_${item.id}.png');
      await file.writeAsBytes(qrBytes);

      // Upload to Firebase Storage
      final uploadService = ImageUploadService();
      final qrCodeUrl = await uploadService.uploadItemImage(
        'qr_codes/${item.id}',
        file,
      );

      // Clean up temp file
      try {
        await file.delete();
        await tempDir.delete(recursive: true);
      } catch (e) {
        debugPrint('Error cleaning up temp files: $e');
      }

      return qrCodeUrl;
    } catch (e) {
      debugPrint('Error generating and uploading QR code: $e');
      rethrow;
    }
  }

  /// Generate QR code data string for an item
  static String generateQrCodeData(InventoryItem item) {
    return jsonEncode({
      'itemId': item.id,
      'assetId': item.assetId,
      'name': item.name,
    });
  }
}

