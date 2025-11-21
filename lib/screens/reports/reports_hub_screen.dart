import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/permission_guard.dart';

import '../../models/firestore_models.dart';
import '../../services/asset_report_service.dart';
import '../../services/csv_export_service.dart';
import '../../services/firebase_services.dart';
import '../../services/simple_pdf_download.dart';

class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  bool _isGenerating = false;
  String? _status;
  List<Department> _departments = const [];
  String? _selectedDepartmentId;
  String? _customDepartmentId;
  String? _customStatus;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final deptService = context.read<DepartmentService>();
      final departments = await deptService.listDepartments(includeInactive: false);
      if (mounted) {
        setState(() => _departments = departments);
      }
    } catch (_) {}
  }

  Future<void> _generateSummaryReport(BuildContext context) async {
    setState(() {
      _isGenerating = true;
      _status = 'Preparing data…';
    });
    try {
      final catalog = context.read<CatalogService>();
      final items = await catalog.listAllItems(pageSize: 500);
      setState(() => _status = 'Building PDF…');
      final pdf = await AssetReportService().buildSummaryReport(items);
      final filename = 'asset_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await SimplePdfDownload.downloadPdf(pdf, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report downloaded: $filename')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _status = null;
        });
      }
    }
  }

  Future<void> _exportToCsv(BuildContext context) async {
    setState(() {
      _isGenerating = true;
      _status = 'Loading items…';
    });
    try {
      final catalog = context.read<CatalogService>();
      final items = await catalog.listAllItems(pageSize: 1000);
      
      if (items.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No items to export')),
          );
        }
        return;
      }

      setState(() => _status = 'Generating CSV…');
      final filename = 'inventory_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      await CsvExportService.exportItemsToCsv(items, filename);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exported: $filename')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _status = null;
        });
      }
    }
  }

  Future<void> _generateDepartmentReport(BuildContext context) async {
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a department first')),
      );
      return;
    }
    setState(() {
      _isGenerating = true;
      _status = 'Loading department items…';
    });
    try {
      final catalog = context.read<CatalogService>();
      final items = await catalog.listAllItems(pageSize: 500);
      final filtered =
          items.where((item) => item.departmentId == _selectedDepartmentId).toList();
      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department has no items')),
        );
      } else {
        setState(() => _status = 'Building department PDF…');
        final pdf = await AssetReportService().buildSummaryReport(filtered);
        final filename =
            'dept_${_selectedDepartmentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await SimplePdfDownload.downloadPdf(pdf, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Department report downloaded: $filename')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to build department report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _status = null;
        });
      }
    }
  }

  Future<void> _generateCustomReport(BuildContext context) async {
    setState(() {
      _isGenerating = true;
      _status = 'Loading items…';
    });
    try {
      final catalog = context.read<CatalogService>();
      final items = await catalog.listAllItems(pageSize: 1000);
      Iterable<InventoryItem> filtered = items;
      if (_customDepartmentId != null && _customDepartmentId!.isNotEmpty) {
        filtered =
            filtered.where((item) => item.departmentId == _customDepartmentId);
      }
      if (_customStatus != null && _customStatus!.isNotEmpty) {
        filtered = filtered.where(
            (item) => (item.status ?? '').toLowerCase() == _customStatus);
      }
      final list = filtered.toList();
      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items match the selected filters')),
        );
      } else {
        setState(() => _status = 'Generating custom CSV…');
        final filename =
            'custom_report_${DateTime.now().millisecondsSinceEpoch}.csv';
        await CsvExportService.exportItemsToCsv(list, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Custom report exported: $filename')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export custom report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _status = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporting Hub')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Generate exportable summaries and PDF reports. Additional report types will return as we finish the migration.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ReportsOnly(
              child: FilledButton.icon(
                onPressed:
                    _isGenerating ? null : () => _generateSummaryReport(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Complete Assets Report (PDF)'),
              ),
            ),
            const SizedBox(height: 12),
            ReportsOnly(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : () => _exportToCsv(context),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Generate Full Report (CSV)'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Department Report',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDepartmentId,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: _departments
                  .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedDepartmentId = value),
            ),
            const SizedBox(height: 12),
            ReportsOnly(
              child: FilledButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _generateDepartmentReport(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate Department PDF'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Custom Report Builder',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _customDepartmentId,
              decoration: const InputDecoration(
                labelText: 'Department (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All departments')),
                ..._departments
                    .map((d) => DropdownMenuItem<String?>(value: d.id, child: Text(d.name)))
                    .toList(),
              ],
              onChanged: (value) => setState(() => _customDepartmentId = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _customStatus,
              decoration: const InputDecoration(
                labelText: 'Status (optional)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Any status')),
                DropdownMenuItem<String?>(value: 'active', child: Text('Active')),
                DropdownMenuItem<String?>(value: 'pending', child: Text('Pending')),
                DropdownMenuItem<String?>(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) => setState(() => _customStatus = value),
            ),
            const SizedBox(height: 12),
            ReportsOnly(
              child: OutlinedButton.icon(
                onPressed:
                    _isGenerating ? null : () => _generateCustomReport(context),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Export Custom CSV'),
              ),
            ),
            const SizedBox(height: 24),
            if (_isGenerating) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(_status ?? 'Working…'),
            ],
          ],
        ),
      ),
    );
  }
}
