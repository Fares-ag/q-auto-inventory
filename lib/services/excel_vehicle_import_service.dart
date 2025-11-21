import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/firestore_models.dart';

class ExcelVehicleImportService {
  static Future<List<InventoryItem>> loadVehiclesFromExcelAsset(
      {String assetPath = 'assets/company cars list.xlsx'}) async {
    try {
      final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
      return _decodeVehicles(bytes);
    } on Exception {
      // Try fallback uppercase extension
      final bytes =
          (await rootBundle.load('assets/company cars list.XLSX'))
              .buffer
              .asUint8List();
      return _decodeVehicles(bytes);
    }
  }

  static Future<List<InventoryItem>> loadFromAssetPath(String assetPath) async {
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
    return _decodeVehicles(bytes);
  }

  static List<InventoryItem> loadFromBytes(Uint8List bytes) {
    return _decodeVehicles(bytes);
  }

  static List<InventoryItem> _decodeVehicles(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.isNotEmpty
        ? excel.tables.values.first
        : null;
    if (sheet == null || sheet.rows.length < 2) {
      return const [];
    }

    final headers = sheet.rows.first
        .map((cell) => (cell?.value?.toString() ?? '').toLowerCase().trim())
        .toList();

    int headerIndex(String name) =>
        headers.indexWhere((value) => value == name.toLowerCase());

    final plateIdx = _firstAvailable(headers, ['plate', 'license plate']);
    final nameIdx = _firstAvailable(headers, ['name', 'description']);
    final modelIdx = headerIndex('model');
    final assignedIdx = _firstAvailable(headers, ['assigned to', 'assigned']);
    final valueIdx = _firstAvailable(headers, ['value', 'current value']);

    final List<InventoryItem> vehicles = [];

    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      String cell(int idx) =>
          idx >= 0 && idx < row.length ? (row[idx]?.value?.toString() ?? '') : '';

      final plate = cell(plateIdx);
      final name = cell(nameIdx);
      final model = cell(modelIdx);
      final assignedTo = cell(assignedIdx);
      final rawValue = cell(valueIdx).replaceAll(',', '');
      final currentValue = double.tryParse(rawValue);

      final displayName = name.isNotEmpty
          ? name
          : (model.isNotEmpty
              ? model
              : (plate.isNotEmpty ? plate : 'Vehicle $r'));

      vehicles.add(
        InventoryItem(
          id: 'vehicle_$r',
          assetId: plate.isNotEmpty ? plate : 'VEH-${r.toString().padLeft(4, '0')}',
          name: displayName,
          categoryId: 'vehicles',
          departmentId: 'fleet',
          description: model.isNotEmpty ? model : null,
          status: 'In Use',
          assignedTo: assignedTo.isEmpty ? null : assignedTo,
          customFields: {
            if (currentValue != null) 'currentValue': currentValue,
          },
          tags: plate.isNotEmpty ? [plate] : const [],
        ),
      );
    }

    return vehicles;
  }

  static int _firstAvailable(List<String> headers, List<String> keys) {
    for (final key in keys) {
      final idx = headers.indexWhere((value) => value == key);
      if (idx != -1) return idx;
    }
    return -1;
  }
}
