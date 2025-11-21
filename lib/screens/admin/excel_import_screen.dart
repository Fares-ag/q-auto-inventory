import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/permission_guard.dart';

import '../../services/excel_vehicle_import_service.dart';
import '../../services/firebase_services.dart';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  File? _selectedFile;
  bool _isImporting = false;
  String? _status;
  int _importedCount = 0;
  int _errorCount = 0;
  List<String> _errors = [];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _status = null;
          _importedCount = 0;
          _errorCount = 0;
          _errors = [];
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _importFile() async {
    if (_selectedFile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file first')),
        );
      }
      return;
    }

    setState(() {
      _isImporting = true;
      _status = 'Reading file...';
      _importedCount = 0;
      _errorCount = 0;
      _errors = [];
    });

    try {
      final catalog = context.read<CatalogService>();

      setState(() => _status = 'Processing Excel file...');
      final bytes = await _selectedFile!.readAsBytes();
      final items = ExcelVehicleImportService.loadFromBytes(bytes);

      if (items.isEmpty) {
        setState(() {
          _isImporting = false;
          _status = 'No items found in file';
        });
        return;
      }

      setState(() => _status = 'Importing ${items.length} items...');

      for (int i = 0; i < items.length; i++) {
        try {
          await catalog.createItem(items[i]);
          setState(() {
            _importedCount++;
            _status = 'Imported $_importedCount/${items.length} items...';
          });
        } catch (e) {
          setState(() {
            _errorCount++;
            _errors.add('Item ${i + 1}: $e');
          });
        }
      }

      if (context.mounted) {
        setState(() {
          _isImporting = false;
          _status = 'Import complete!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported $_importedCount items${_errorCount > 0 ? ' ($_errorCount errors)' : ''}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isImporting = false;
          _status = 'Import failed: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Excel'),
        actions: [
          ItemManagementOnly(
            child: (_selectedFile != null && !_isImporting)
                ? IconButton(
                    icon: const Icon(Icons.upload),
                    tooltip: 'Import',
                    onPressed: _importFile,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: ItemManagementOnly(
        showError: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Items from Excel',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select an Excel file (.xlsx or .xls) to import items into the inventory.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isImporting ? null : _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Select Excel File'),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'File selected',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      _selectedFile!.path.split(Platform.pathSeparator).last,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                    _status = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isImporting || _status != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isImporting) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          _status ?? 'Ready',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_importedCount > 0 || _errorCount > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (_importedCount > 0) ...[
                                Chip(
                                  label: Text('✓ $_importedCount imported'),
                                  backgroundColor: Colors.green[100],
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (_errorCount > 0) ...[
                                Chip(
                                  label: Text('✗ $_errorCount errors'),
                                  backgroundColor: Colors.red[100],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red[50],
                  child: ExpansionTile(
                    title: Text('Errors (${_errors.length})'),
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _errors.take(10).map((error) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                error,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Excel File Format',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Excel file should have columns for:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ...['Name', 'Asset ID', 'Category', 'Department', 'Description', 'Quantity']
                          .map((col) => Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(col, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

