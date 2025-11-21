import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/firestore_models.dart';

class CsvExportService {
  static Future<void> exportItemsToCsv(List<InventoryItem> items, String filename) async {
    if (items.isEmpty) {
      throw Exception('No items to export');
    }

    // CSV Header
    final headers = [
      'Asset ID',
      'Name',
      'Category',
      'Department',
      'Status',
      'Quantity',
      'Description',
      'Location',
      'Assigned To',
      'Purchase Date',
      'Warranty Expiry',
      'Last Serviced',
      'Tags',
    ];

    // Build CSV rows
    final rows = <String>[];
    rows.add(headers.join(','));

    for (final item in items) {
      final row = [
        _escapeCsvField(item.assetId),
        _escapeCsvField(item.name),
        _escapeCsvField(item.categoryId),
        _escapeCsvField(item.departmentId),
        _escapeCsvField(item.status ?? ''),
        item.quantity?.toString() ?? '',
        _escapeCsvField(item.description ?? ''),
        _escapeCsvField(item.locationId ?? ''),
        _escapeCsvField(item.assignedTo ?? ''),
        item.purchaseDate?.toIso8601String() ?? '',
        item.warrantyExpiry?.toIso8601String() ?? '',
        item.lastServicedAt?.toIso8601String() ?? '',
        item.tags.join(';'),
      ];
      rows.add(row.join(','));
    }

    final csvContent = rows.join('\n');
    final bytes = utf8.encode(csvContent);

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Inventory Export',
    );
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

