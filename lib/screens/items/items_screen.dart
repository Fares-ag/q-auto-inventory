import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../utils/network_utils.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/paginated_list_view.dart';
import '../../widgets/skeleton_list.dart';
import '../qr/bulk_qr_print_screen.dart';
import 'all_items_screen.dart';
import 'bulk_assign_screen.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late Future<List<InventoryItem>> _itemsFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedDeptId;
  String? _selectedCategoryId;
  String? _selectedStatus; // e.g. 'available', 'assigned', etc.
  List<Department> _departments = const [];
  List<Category> _categories = const [];
  final Map<int, String> _itemPageCursors = <int, String>{};

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
    // Preload filter data in background
    Future.microtask(_bootstrapFilters);
  }

  void _refreshItems() {
    _itemPageCursors.clear();
    setState(() {
      _itemsFuture = _loadItems();
    });
  }

  Future<void> _bootstrapFilters() async {
    try {
      final deptSvc = context.read<DepartmentService>();
      final catSvc = context.read<CatalogService>();
      final ds = await deptSvc.listDepartments(includeInactive: false);
      final cs = await catSvc.listCategories(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _departments = ds;
        _categories = cs;
      });
    } catch (_) {
      // best-effort; keep UI functional without filters loaded
    }
  }

  Future<List<InventoryItem>> _loadItems() async {
    final hasNet = await NetworkUtils.hasInternetConnection();
    if (!hasNet) {
      throw Exception('No internet connection');
    }
    final catalog = context.read<CatalogService>();
    final items = await catalog.listItems(
      limit: 2000,
      departmentId: (_selectedDeptId == null || _selectedDeptId!.isEmpty)
          ? null
          : _selectedDeptId,
      categoryId: (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)
          ? null
          : _selectedCategoryId,
      searchQuery:
          _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (_selectedStatus == null || _selectedStatus!.isEmpty) return items;
    final statusLower = _selectedStatus!.toLowerCase();
    return items
        .where((e) => (e.status ?? '').toLowerCase() == statusLower)
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<InventoryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error!;
            return NetworkUtils.isNetworkError(error)
                ? NetworkErrorWidget(
                    error: error,
                    onRetry: _refreshItems,
                  )
                : ErrorRetryWidget(
                    message: NetworkUtils.getErrorMessage(error),
                    onRetry: _refreshItems,
                  );
          }
          final items = snapshot.data ?? const [];
          return RefreshIndicator(
            onRefresh: () async {
              _refreshItems();
              await _itemsFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.apartment, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q-AUTO',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Digital Asset Management',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FiltersBar(
                    searchController: _searchCtrl,
                    departments: _departments,
                    categories: _categories,
                    selectedDeptId: _selectedDeptId,
                    selectedCategoryId: _selectedCategoryId,
                    selectedStatus: _selectedStatus,
                    onApply: (deptId, catId, status, query) {
                      _selectedDeptId =
                          (deptId == null || deptId.isEmpty) ? null : deptId;
                      _selectedCategoryId =
                          (catId == null || catId.isEmpty) ? null : catId;
                      _selectedStatus =
                          (status == null || status.isEmpty) ? null : status;
                      _searchCtrl.text = query ?? '';
                      _refreshItems();
                    },
                    onClear: () {
                      _selectedDeptId = null;
                      _selectedCategoryId = null;
                      _selectedStatus = null;
                      _searchCtrl.clear();
                      _refreshItems();
                    },
                  ),
                  const SizedBox(height: 16),
                  _QuickActionsGrid(
                    onSearch: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllItemsScreen(items: items),
                        ),
                      );
                    },
                    onAddNew: () =>
                        Navigator.of(context).pushNamed('/items/add'),
                    onScan: () {
                      Navigator.of(context)
                          .pushNamed(BulkQrPrintScreen.routeName);
                    },
                    onGenerateQr: () {
                      Navigator.of(context)
                          .pushNamed(BulkQrPrintScreen.routeName);
                    },
                    onBulkAssign: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BulkAssignScreen(),
                      ),
                    ),
                    onDebugItems: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Debug tools coming soon.')),
                      );
                    },
                    onRefresh: _refreshItems,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Service State'),
                          subtitle: Text('Service and listener health checks'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: const Text('Test Listener'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Listener test triggered.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: SizedBox(
                      height: 520,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: PaginatedListView<InventoryItem>(
                          pageSize: 25,
                          loadItems: (page, size) async {
                            final catalog = context.read<CatalogService>();
                            final hasNet =
                                await NetworkUtils.hasInternetConnection();
                            if (!hasNet)
                              throw Exception('No internet connection');

                            final hasTextFilter =
                                _searchCtrl.text.trim().isNotEmpty;
                            final hasStatusFilter = _selectedStatus != null &&
                                _selectedStatus!.isNotEmpty;

                            if (hasTextFilter || hasStatusFilter) {
                              final fetchLimit = (page + 1) * size;
                              final all = await catalog.listItems(
                                limit: fetchLimit,
                                departmentId: (_selectedDeptId == null ||
                                        _selectedDeptId!.isEmpty)
                                    ? null
                                    : _selectedDeptId,
                                categoryId: (_selectedCategoryId == null ||
                                        _selectedCategoryId!.isEmpty)
                                    ? null
                                    : _selectedCategoryId,
                                searchQuery: hasTextFilter
                                    ? _searchCtrl.text.trim()
                                    : null,
                              );
                              final filtered = hasStatusFilter
                                  ? all
                                      .where((e) =>
                                          (e.status ?? '').toLowerCase() ==
                                          _selectedStatus!.toLowerCase())
                                      .toList()
                                  : all;
                              final start = page * size;
                              if (start >= filtered.length)
                                return const <InventoryItem>[];
                              final end = (start + size) > filtered.length
                                  ? filtered.length
                                  : (start + size);
                              return filtered.sublist(start, end);
                            }

                            final startAfter =
                                page == 0 ? null : _itemPageCursors[page - 1];
                            final pageItems = await catalog.listItemsPage(
                              limit: size,
                              departmentId: (_selectedDeptId == null ||
                                      _selectedDeptId!.isEmpty)
                                  ? null
                                  : _selectedDeptId,
                              categoryId: (_selectedCategoryId == null ||
                                      _selectedCategoryId!.isEmpty)
                                  ? null
                                  : _selectedCategoryId,
                              startAfterName: startAfter,
                            );
                            if (pageItems.isNotEmpty) {
                              _itemPageCursors[page] = pageItems.last.name;
                            }
                            return pageItems;
                          },
                          itemBuilder: (ctx, it, idx) =>
                              _ItemListTile(item: it),
                          emptyWidget:
                              const Center(child: Text('No items found')),
                          loadingWidget: const Padding(
                            padding: EdgeInsets.all(8),
                            child: SkeletonList(itemCount: 8, itemHeight: 64),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onSearch,
    required this.onAddNew,
    required this.onScan,
    required this.onGenerateQr,
    required this.onBulkAssign,
    required this.onDebugItems,
    required this.onRefresh,
  });

  final VoidCallback onSearch;
  final VoidCallback onAddNew;
  final VoidCallback onScan;
  final VoidCallback onGenerateQr;
  final VoidCallback onBulkAssign;
  final VoidCallback onDebugItems;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionConfig('Search', Icons.search, onSearch),
      _ActionConfig('Add New', Icons.add_box_outlined, onAddNew),
      _ActionConfig('Scan QR Code', Icons.qr_code_scanner, onScan),
      _ActionConfig(
          'Generate QR Codes', Icons.qr_code_2_outlined, onGenerateQr),
      _ActionConfig('Bulk Assign', Icons.grid_view, onBulkAssign),
      _ActionConfig('Debug Items', Icons.bug_report_outlined, onDebugItems),
      _ActionConfig('Refresh Items', Icons.refresh, onRefresh),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) {
        final btn = SizedBox(
          width: MediaQuery.of(context).size.width > 600
              ? 220
              : (MediaQuery.of(context).size.width - 52) / 2,
          child: OutlinedButton.icon(
            onPressed: action.onTap,
            icon: Icon(action.icon),
            label: Text(action.label, textAlign: TextAlign.center),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );
        final needsManage = action.label == 'Add New' ||
            action.label == 'Generate QR Codes' ||
            action.label == 'Bulk Assign';
        return needsManage ? ItemManagementOnly(child: btn) : btn;
      }).toList(),
    );
  }
}

class _ActionConfig {
  const _ActionConfig(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ItemListTile extends StatelessWidget {
  const _ItemListTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.thumbnailUrl != null
            ? Image.network(
                item.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : Container(
                width: 56,
                height: 56,
                color: Colors.grey[200],
                child: const Icon(Icons.inventory_2, color: Colors.grey),
              ),
      ),
      title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(item.categoryId),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delete coming soon.')),
          );
        },
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: item),
          ),
        );
      },
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchController,
    required this.departments,
    required this.categories,
    required this.selectedDeptId,
    required this.selectedCategoryId,
    required this.selectedStatus,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController searchController;
  final List<Department> departments;
  final List<Category> categories;
  final String? selectedDeptId;
  final String? selectedCategoryId;
  final String? selectedStatus;
  final void Function(
          String? deptId, String? categoryId, String? status, String? query)
      onApply;
  final VoidCallback onClear;

  static const _statusOptions = <String>[
    '',
    'available',
    'assigned',
    'maintenance',
    'retired'
  ];

  @override
  Widget build(BuildContext context) {
    String? dept = selectedDeptId;
    String? cat = selectedCategoryId;
    String? st = selectedStatus ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search name or asset ID',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (v) => onApply(dept, cat, st, v),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: dept,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem(value: '', child: Text('All')),
                      ...departments.map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (v) => dept = v,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: cat,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem(value: '', child: Text('All')),
                      ...categories.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => cat = v,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: st,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statusOptions
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.isEmpty ? 'All' : s)))
                        .toList(),
                    onChanged: (v) => st = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      onApply(dept, cat, st, searchController.text.trim()),
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Apply'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
