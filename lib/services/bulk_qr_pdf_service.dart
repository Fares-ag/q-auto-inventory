// lib/services/bulk_qr_pdf_service.dart

import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../models/firestore_models.dart';

class BulkQrPdfService {
  /// Generate a PDF with one QR code per page, centered with asset name and ID
  /// [onProgress] callback receives (current, total) for progress updates
  /// Optimized for speed with parallel QR code generation
  static Future<List<Uint8List>> generateBulkQrPdfs(
    List<InventoryItem> items, {
    void Function(int current, int total)? onProgress,
    double? pageWidthMm,
    double? pageHeightMm,
  }) async {
    final totalItems = items.length;
    const batchSize = 500; // Batch size to avoid memory issues

    // If we have fewer items than batch size, return single PDF
    if (totalItems <= batchSize) {
      final pdfBytes = await _generateSinglePdf(items, onProgress,
          pageWidthMm: pageWidthMm, pageHeightMm: pageHeightMm);
      return [pdfBytes];
    }

    // For large lists, generate multiple PDFs
    debugPrint(
        'Large PDF detected ($totalItems items). Generating multiple PDFs of $batchSize pages each...');

    final List<Uint8List> pdfFiles = [];
    int processedCount = 0;
    final totalBatches = (items.length / batchSize).ceil();

    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      final batchNumber = (i ~/ batchSize) + 1;

      debugPrint(
          'Generating PDF $batchNumber of $totalBatches (${batch.length} items)...');

      // Generate PDF for this batch
      final batchPdf = await _generateSinglePdf(
        batch,
        (current, total) {
          // Update progress based on overall progress
          final overallCurrent = i + current;
          onProgress?.call(overallCurrent, totalItems);
        },
        pageWidthMm: pageWidthMm,
        pageHeightMm: pageHeightMm,
      );

      pdfFiles.add(batchPdf);
      processedCount += batch.length;
      onProgress?.call(processedCount, totalItems);
    }

    debugPrint('Generated ${pdfFiles.length} PDF files.');
    return pdfFiles;
  }

  static Future<Uint8List> _generateSinglePdf(
    List<InventoryItem> items,
    void Function(int current, int total)? onProgress, {
    double? pageWidthMm,
    double? pageHeightMm,
  }) async {
    final doc = pw.Document();
    final totalItems = items.length;

    final qrPagesData = await _generateQrCodesConcurrently(
      items,
      onProgress,
      pageWidthMm: pageWidthMm,
      pageHeightMm: pageHeightMm,
    );

    int currentIndex = 0;

    final customFormat =
        pageWidthMm != null && pageHeightMm != null
            ? pdf.PdfPageFormat(
                pageWidthMm * pdf.PdfPageFormat.mm,
                pageHeightMm * pdf.PdfPageFormat.mm,
                marginAll: 2 * pdf.PdfPageFormat.mm,
              )
            : pdf.PdfPageFormat.a4;

    // Group items into sets of 3 for each page
    const itemsPerPage = 3;
    for (int pageIndex = 0;
        pageIndex < qrPagesData.length;
        pageIndex += itemsPerPage) {
      final pageItems = qrPagesData.skip(pageIndex).take(itemsPerPage).toList();

      doc.addPage(
        pw.Page(
          pageFormat: customFormat,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            final double mm = pdf.PdfPageFormat.mm;
            final bool useCustomLabel =
                pageWidthMm != null && pageHeightMm != null;

            // Calculate sizes to fit 3 QR codes vertically
            // For 33mm width x 106.68mm height (3x original), each QR section gets ~35mm height
            final double labelWidth = (pageWidthMm ?? 33);
            final double frameSize = useCustomLabel
                ? (((labelWidth - 4).clamp(14, 22)) * mm)
                : 280;
            final double qrSize = useCustomLabel ? (frameSize - 2 * mm) : 240;
            final double nameFont = useCustomLabel ? 5.5 : 12;
            final double idFont = useCustomLabel ? 4.5 : 8;
            final double gap1 = useCustomLabel ? 1.2 * mm : 4;
            final double gap2 = useCustomLabel ? 0.6 * mm : 2;
            final double sectionGap = useCustomLabel ? 3.0 * mm : 8;

            final List<pw.Widget> qrSections = [];

            for (int i = 0; i < pageItems.length; i++) {
              final pageData = pageItems[i];
              final itemId = pageData['itemId'] as String;
              final itemName = pageData['itemName'] as String;
              final qrImageBytes = pageData['qrImageBytes'] as Uint8List;
              final qrImage = pw.MemoryImage(qrImageBytes);

              qrSections.add(
                pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // QR Code
                    pw.Container(
                      width: frameSize,
                      height: frameSize,
                      padding: useCustomLabel
                          ? pw.EdgeInsets.all(1.5 * mm)
                          : const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: pdf.PdfColors.black, width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Center(
                        child: pw.Image(
                          qrImage,
                          width: qrSize,
                          height: qrSize,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: gap1),
                    pw.Text(
                      itemName,
                      style: pw.TextStyle(
                        fontSize: nameFont,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: gap2),
                    pw.Text(
                      itemId,
                      style: pw.TextStyle(
                        fontSize: idFont,
                        fontWeight: pw.FontWeight.bold,
                        color: pdf.PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (i != pageItems.length - 1) pw.SizedBox(height: sectionGap),
                  ],
                ),
              );
            }

            return pw.Container(
              width: double.infinity,
              height: double.infinity,
              padding: useCustomLabel
                  ? pw.EdgeInsets.symmetric(
                      horizontal: 1 * mm, vertical: 2 * mm)
                  : const pw.EdgeInsets.all(8),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: qrSections,
              ),
            );
          },
        ),
      );

      currentIndex += pageItems.length;
      onProgress?.call(currentIndex, totalItems);
    }

    final pdfBytes = await doc.save();
    return pdfBytes;
  }

  static Future<List<Map<String, dynamic>>> _generateQrCodesConcurrently(
    List<InventoryItem> items,
    void Function(int current, int total)? onProgress, {
    required double? pageWidthMm,
    required double? pageHeightMm,
  }) async {
    const concurrentBatchSize = 15;
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < items.length; i += concurrentBatchSize) {
      final batch = items.skip(i).take(concurrentBatchSize).toList();

      final List<Map<String, dynamic>> batchResults = await Future.wait(
        batch.map((item) async {
          final qrBytes = await _generateQrCodeImage(
            item,
            pageWidthMm: pageWidthMm,
            pageHeightMm: pageHeightMm,
          );
          return {
            'itemId': item.assetId,
            'itemName': item.name,
            'qrImageBytes': qrBytes,
          };
        }),
      );

      result.addAll(batchResults);
      onProgress?.call(result.length, items.length);
    }

    return result;
  }

  static Future<Uint8List> _generateQrCodeImage(
    InventoryItem item, {
    required double? pageWidthMm,
    required double? pageHeightMm,
  }) async {
    final qrValidationResult = QrValidator.validate(
      data: jsonEncode({
        'itemId': item.id,
        'assetId': item.assetId,
        'name': item.name,
      }),
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Failed to generate QR for ${item.id}');
    }

    final painter = QrPainter.withQr(
      qr: qrValidationResult.qrCode!,
      color: const ui.Color(0xFF000000),
      emptyColor: const ui.Color(0x00000000),
      gapless: true,
    );

    final double baseSize =
        pageWidthMm != null ? (pageWidthMm - 6).clamp(10, 22) : 256 / 3.78;
    final double logicalPixels = baseSize * 3.78; // mm to px approx

    final picData = await painter.toImageData(
      logicalPixels,
      format: ui.ImageByteFormat.png,
    );

    return picData!.buffer.asUint8List();
  }
}
