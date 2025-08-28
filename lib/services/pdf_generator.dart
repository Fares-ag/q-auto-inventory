// lib/services/pdf_generator.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/item_model.dart';

class PdfGenerator {
  static Future<void> generateTraceabilityReport(
      ItemModel item, List<HistoryEntry> history) async {
    final pdf = pw.Document();

    // Load your logo from the assets folder
    // IMPORTANT: Ensure you have a 'Q-AutoLogo.png' in your 'assets/' folder.
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/Q-AutoLogo.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildReportTitle(item),
            pw.SizedBox(height: 20),
            _buildItemDetails(item),
            pw.SizedBox(height: 20),
            _buildHistoryTable(history),
          ];
        },
      ),
    );

    // This will open a print preview screen where the user can save or print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Q-AUTO Asset Management',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(
            height: 40,
            width: 40,
            child: pw.Image(logo),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _buildReportTitle(ItemModel item) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Traceability Report',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildItemDetails(ItemModel item) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Item Details',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Divider(color: PdfColors.grey400, height: 20),
          _buildDetailRow('Asset ID:', item.id),
          _buildDetailRow('Name:', item.name),
          _buildDetailRow('Category:', item.category),
          _buildDetailRow('Department:', item.department ?? 'N/A'),
          // ADDED: Warranty Expiry row
          _buildDetailRow('Warranty Expiry:',
              item.customFields['Warranty Expiration'] ?? 'N/A'),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _buildHistoryTable(List<HistoryEntry> history) {
    final headers = ['Date', 'Action', 'Description', 'User', 'Signatures'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(4),
        3: const pw.FlexColumnWidth(3),
        4: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(header,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            );
          }).toList(),
        ),
        // Data Rows
        ...history.asMap().entries.map((entry) {
          final index = entry.key;
          final historyEntry = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(historyEntry.timestamp
                      .toLocal()
                      .toString()
                      .split(' ')[0])),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(historyEntry.title)),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(historyEntry.description)),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(historyEntry.actorEmail)),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: _buildSignatureCell(historyEntry),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildSignatureCell(HistoryEntry entry) {
    if (entry.assigneeSignature == null && entry.operatorSignature == null) {
      return pw.Text('N/A', style: const pw.TextStyle(color: PdfColors.grey));
    }
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        if (entry.assigneeSignature != null)
          _buildSignatureImage(entry.assigneeSignature!, 'Assignee'),
        if (entry.operatorSignature != null)
          _buildSignatureImage(entry.operatorSignature!, 'Operator'),
      ],
    );
  }

  static pw.Widget _buildSignatureImage(
      Uint8List signatureBytes, String label) {
    final image = pw.MemoryImage(signatureBytes);
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 2),
        pw.Container(
          width: 50,
          height: 25,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Image(image),
        ),
      ],
    );
  }
}
