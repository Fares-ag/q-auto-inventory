import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/bulk_qr_pdf_service.dart';
import '../../services/cache_service.dart';
import '../../services/firebase_services.dart';
import '../../services/simple_pdf_download.dart';

class BulkQrPrintScreen extends StatefulWidget {
  const BulkQrPrintScreen({super.key});

  static const String routeName = '/bulk-qr';

  @override
  State<BulkQrPrintScreen> createState() => _BulkQrPrintScreenState();
}

class _BulkQrPrintScreenState extends State<BulkQrPrintScreen> {
  bool _isGenerating = false;
  String? _statusMessage;
  String? _selectedDepartmentId;
  List<Department> _departments = [];
  Map<String, Department> _departmentById = {};
  final _cache = CacheService.instance;
  List<InventoryItem> _allItems = [];
  List<InventoryItem>? _items;
  bool _isLoadingItems = false;
  String? _loadingError;

  List<InventoryItem> get _safeItems => _items ?? const <InventoryItem>[];
  int get _totalItemCount =>
      _allItems.isNotEmpty ? _allItems.length : _safeItems.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartments();
      _loadItems();
    });
  }

  Future<void> _loadDepartments() async {
    if (!mounted) return;
    try {
      final deptService = context.read<DepartmentService>();
      final departments =
          await deptService.listDepartments(includeInactive: false);
      if (mounted) {
        final filtered = _allItems.isNotEmpty
            ? _applyFilter(_allItems, departments)
            : null;
        setState(() {
          _departments = departments;
          _departmentById = {
            for (final dept in departments) dept.id: dept,
          };
          if (filtered != null) {
            _items = filtered;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  List<InventoryItem> _applyFilter(
    List<InventoryItem> source,
    List<Department> departments,
  ) {
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      return source;
    }
    final selectedDept = departments.firstWhere(
      (d) => d.id == _selectedDepartmentId,
      orElse: () => Department(id: '', name: ''),
    );
    if (selectedDept.id.isEmpty) {
      return source;
    }
    final deptNameUpper = selectedDept.name.toUpperCase().trim();
    return source.where((item) {
      final itemDeptId = item.departmentId.trim();
      if (itemDeptId.isEmpty) return false;
      if (itemDeptId == selectedDept.id) return true;
      final itemDeptNameUpper = itemDeptId.toUpperCase().trim();
      return itemDeptNameUpper == deptNameUpper || itemDeptId == selectedDept.name;
    }).toList();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;

    setState(() {
      _isLoadingItems = _allItems.isEmpty;
      _loadingError = null;
    });

    try {
      final catalog = context.read<CatalogService>();
      final deptService = context.read<DepartmentService>();

      final cached =
          _cache.get<List<InventoryItem>>(CacheKeys.items(null, null));
      if (cached != null && cached.isNotEmpty) {
        _allItems = cached;
        final departments =
            _departments.isNotEmpty
                ? _departments
                : await deptService.listDepartments(includeInactive: false);
        if (_departments.isEmpty && mounted) {
          setState(() {
            _departments = departments;
            _departmentById = {
              for (final dept in departments) dept.id: dept,
            };
          });
        }
        final filtered = _applyFilter(_allItems, departments);
        if (mounted) {
          setState(() {
            _items = filtered;
            _isLoadingItems = false;
          });
        }
      }

      // Load ALL items from database
      debugPrint('Loading all items from database...');
      final allItems = await catalog.listAllItems(pageSize: 1000);
      debugPrint('Loaded ${allItems.length} total items from database');

      if (!mounted) return;

      _allItems = allItems;
      _cache.set(
        CacheKeys.items(null, null),
        allItems,
        ttl: const Duration(minutes: 30),
      );
      final departments =
          _departments.isNotEmpty
              ? _departments
              : await deptService.listDepartments(includeInactive: false);
      if (_departments.isEmpty && mounted) {
        setState(() {
          _departments = departments;
          _departmentById = {
            for (final dept in departments) dept.id: dept,
          };
        });
      }
      final filteredItems = _applyFilter(_allItems, departments);

      if (mounted) {
        setState(() {
          _items = filteredItems;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (mounted) {
        setState(() {
          if (_items == null) {
            _items = const <InventoryItem>[];
          }
          _isLoadingItems = false;
          _loadingError = e.toString();
        });
      }
    }
  }

  Future<void> _generateAndDownload(List<InventoryItem> items) async {
    if (items.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating PDF…';
    });

    try {
      final pdfFiles = await BulkQrPdfService.generateBulkQrPdfs(
        items,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _statusMessage = 'Processing $current of $total';
          });
        },
        pageWidthMm: 33,
        pageHeightMm: 106.68,
      );

      if (!mounted) return;

      for (var i = 0; i < pdfFiles.length; i++) {
        if (!mounted) return;
        final bytes = pdfFiles[i];
        final filename =
            'qr_labels_part_${i + 1}_of_${pdfFiles.length}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await SimplePdfDownload.downloadPdf(bytes, filename);
      }

      if (!mounted) return;
      if (!context.mounted) return;

      setState(() => _statusMessage = 'Complete!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'QR PDF generated successfully! ${pdfFiles.length} file(s) downloaded.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      if (!context.mounted) return;

      setState(() => _statusMessage = 'Failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _departmentLabelForItem(InventoryItem item) {
    final deptId = item.departmentId.trim();
    if (deptId.isEmpty) return 'N/A';
    final byId = _departmentById[deptId];
    if (byId != null) return byId.name;
    // Fallback: if item stores department name, return it as-is
    return deptId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk QR Labels')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Department Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list),
                        const SizedBox(width: 8),
                        Text(
                          'Filter by Department',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Departments'),
                        ),
                        ..._departments.map((dept) => DropdownMenuItem(
                              value: dept.id,
                              child: Text(dept.name),
                            )),
                      ],
                      onChanged: (value) {
                        final departments = _departments;
                        setState(() {
                          _selectedDepartmentId = value;
                          _items = _applyFilter(_allItems, departments);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingItems)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading items...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else if (_loadingError != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadingError!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadItems,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_safeItems.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        _selectedDepartmentId != null
                            ? 'No items found for selected department.'
                            : 'No items found.',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDepartmentId != null
                              ? 'Showing ${_safeItems.length} of $_totalItemCount items for selected department.'
                              : 'Showing all $_totalItemCount items.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_safeItems.length} items ready for QR printing.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _generateAndDownload(_safeItems),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate PDF'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(_statusMessage!),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _safeItems.length,
                  itemBuilder: (context, index) {
                    final item = _safeItems[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code_2),
                      title: Text(item.name),
                      subtitle: Text(
                          '${item.assetId} • Dept: ${_departmentLabelForItem(item)}'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
