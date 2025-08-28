// lib/widgets/report_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart'; // <-- Add this import

class ReportPreviewScreen extends StatelessWidget {
  final List<ItemModel> items;
  final List<String> selectedFields;

  const ReportPreviewScreen({
    Key? key,
    required this.items,
    required this.selectedFields,
  }) : super(key: key);

  String _getAttributeValue(ItemModel item, String attributeKey) {
    // Helper to get the correct data for each cell
    switch (attributeKey) {
      case 'ID':
        return item.id;
      case 'Name':
        return item.name;
      case 'Category':
        return item.category;
      case 'Department':
        return item.department ?? 'N/A';
      case 'Assigned Staff':
        return item.assignedStaff ?? 'N/A';
      case 'Purchase Price':
        return item.purchasePrice?.toStringAsFixed(2) ?? 'N/A';
      case 'Purchase Date':
        return "${item.purchaseDate.toLocal()}".split(' ')[0];
      case 'Current Value':
        return item.currentValue?.toStringAsFixed(2) ?? 'N/A';
      case 'Status':
        return item.status;
      // Add any other fields from your model here
      default:
        return 'N/A';
    }
  }

  // ✅ UPDATED FUNCTION
  void _downloadReport(BuildContext context) async {
    // 1. Build the list of rows for the CSV file
    List<List<dynamic>> rows = [];
    rows.add(selectedFields); // Header row

    for (var item in items) {
      List<dynamic> row = [];
      for (var header in selectedFields) {
        row.add(_getAttributeValue(item, header));
      }
      rows.add(row);
    }

    // 2. Convert the data to a CSV string
    String csvData = const ListToCsvConverter().convert(rows);

    try {
      // 3. Save to a temporary directory (no permissions needed)
      final directory = await getTemporaryDirectory();
      final path = directory.path;
      final fileName =
          'custom_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('$path/$fileName');
      await file.writeAsString(csvData);

      // 4. Use share_plus to let the user save the file
      final xFile = XFile(file.path, name: fileName, mimeType: 'text/csv');
      await Share.shareXFiles([xFile], subject: 'Custom Inventory Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error creating report: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _downloadReport(context),
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: selectedFields
                .map((field) => DataColumn(
                    label: Text(field,
                        style: const TextStyle(fontWeight: FontWeight.bold))))
                .toList(),
            rows: items.map((item) {
              return DataRow(
                cells: selectedFields.map((field) {
                  final value = _getAttributeValue(item, field);
                  return DataCell(Text(value));
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
