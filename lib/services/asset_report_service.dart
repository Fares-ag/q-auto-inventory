// lib/services/asset_report_service.dart

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/firestore_models.dart';

class AssetReportService {
  Future<Uint8List> buildSummaryReport(List<InventoryItem> items) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text('Inventory Summary',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 12),
          _buildSummary(items),
          pw.SizedBox(height: 24),
          pw.Text('Items',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 12),
          _buildItemsTable(items),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildSummary(List<InventoryItem> items) {
    final total = items.length;
    final active = items.where((item) => item.status == 'active').length;
    final assigned = items.where((item) => item.assignedTo != null).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Bullet(text: 'Total items: $total'),
        pw.Bullet(text: 'Active: $active'),
        pw.Bullet(text: 'Assigned: $assigned'),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<InventoryItem> items) {
    const int chunkSize = 250;
    final List<List<String>> data = [];
    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      data.addAll(chunk.map((item) => [
            item.assetId,
            item.name,
            item.departmentId,
            item.assignedTo ?? '-',
            item.status ?? '-',
          ]));
    }

    return pw.Column(
      children: [
        for (int i = 0; i < data.length; i += chunkSize)
          pw.Table.fromTextArray(
            headers: const [
              'Asset ID',
              'Name',
              'Department',
              'Assigned To',
              'Status'
            ],
            data: data.skip(i).take(chunkSize).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
            },
          ),
      ],
    );
  }
}
