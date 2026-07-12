import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../navigation/app_router.dart';
import '../../services/firebase_services.dart';
import '../../services/cache_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/network_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';

class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({super.key, this.items});

  final List<InventoryItem>? items;

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  final _searchController = TextEditingController();
  static const String _filtersCacheKey = 'all_items_filters_v1';
  String? _selectedDepartmentId;
  String? _selectedCategoryId;
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<InventoryItem> _filteredItems = [];
  List<Department> _departments = [];
  List<Category> _categories = [];
  Map<String, Department> _deptMap = {};
  Map<String, Department> _deptNameMapLower = {};
  Map<String, Category> _catMap = {};
  Map<String, Category> _catNameMapLower = {};
  bool _isLoading = false;
  Object? _error;
  final _cache = CacheService.instance;

  @override
  void initState() {
    super.initState();
    _restoreFilters();
    // Load from cache instantly if available
    _loadFromCache();
    _loadFilters();
    if (widget.items == null) {
      _loadItems();
    } else {
      _filteredItems = widget.items!;
    }
  }
  
  void _loadFromCache() {
    // Try to load from cache first for instant display
    final cached = _cache.get<List<InventoryItem>>(CacheKeys.items(null, null));
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _filteredItems = cached;
        _isLoading = false;
      });
      _sortItems();
    }
  }

  Future<void> _loadFilters() async {
    final deptService = context.read<DepartmentService>();
    final catalog = context.read<CatalogService>();

    final departments =
        await deptService.listDepartments(includeInactive: false);
    final categories = await catalog.listCategories();

    setState(() {
      _departments = departments;
      _categories = categories;
      _deptMap = {for (final d in departments) d.id: d};
      _deptNameMapLower = {
        for (final d in departments) d.name.trim().toLowerCase(): d
      };
      _catMap = {for (final c in categories) c.id: c};
      _catNameMapLower = {
        for (final c in categories) c.name.trim().toLowerCase(): c
      };
    });
  }

  bool _matchesDepartment(InventoryItem item, Department dept) {
    final itemDept = item.departmentId.trim();
    if (itemDept.isEmpty) return false;
    if (itemDept == dept.id) return true;
    return itemDept.toLowerCase() == dept.name.trim().toLowerCase();
  }

  bool _matchesCategory(InventoryItem item, Category cat) {
    final itemCat = item.categoryId.trim();
    if (itemCat.isEmpty) return false;
    if (itemCat == cat.id) return true;
    return itemCat.toLowerCase() == cat.name.trim().toLowerCase();
  }

  String _departmentLabelFor(InventoryItem item) {
    final deptId = item.departmentId.trim();
    if (deptId.isEmpty) return 'Unassigned';
    final byId = _deptMap[deptId];
    if (byId != null) return byId.name;
    final byName = _deptNameMapLower[deptId.toLowerCase()];
    if (byName != null) return byName.name;
    return deptId;
  }

  String _categoryLabelFor(InventoryItem item) {
    final catId = item.categoryId.trim();
    if (catId.isEmpty) return 'Uncategorized';
    final byId = _catMap[catId];
    if (byId != null) return byId.name;
    final byName = _catNameMapLower[catId.toLowerCase()];
    if (byName != null) return byName.name;
    return catId;
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check network connection first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection');
      }

      final catalog = context.read<CatalogService>();
      
      // Load ALL items from database (no limit)
      final allItems = await catalog.listAllItems();
      
      // Apply filters client-side
      var items = allItems;
      
      if (_selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty) {
        final dept = _deptMap[_selectedDepartmentId];
        if (dept != null) {
          items = items.where((item) => _matchesDepartment(item, dept)).toList();
        }
      }
      
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        final cat = _catMap[_selectedCategoryId];
        if (cat != null) {
          items = items.where((item) => _matchesCategory(item, cat)).toList();
        }
      }
      
      if (_searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        items = items.where((item) =>
          item.name.toLowerCase().contains(query) ||
          item.assetId.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false)
        ).toList();
      }

      if (!context.mounted) return;

      setState(() {
        _filteredItems = items;
        _isLoading = false;
        _error = null;
      });
      _sortItems(); // Apply sorting after loading
      _persistFilters();
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        _isLoading = false;
        _error = e;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkUtils.getErrorMessage(e)),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadItems,
            ),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _loadItems();
    _persistFilters();
  }

  void _sortItems() {
    setState(() {
      _filteredItems.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'assetId':
            comparison = a.assetId.compareTo(b.assetId);
            break;
          case 'status':
            comparison = (a.status ?? '').compareTo(b.status ?? '');
            break;
          case 'purchaseDate':
            final aDate = a.purchaseDate ?? DateTime(1970);
            final bDate = b.purchaseDate ?? DateTime(1970);
            comparison = aDate.compareTo(bDate);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    });
    _persistFilters();
  }

  void _restoreFilters() {
    final cached = _cache.get<Map<String, dynamic>>(_filtersCacheKey);
    if (cached == null) return;
    setState(() {
      _selectedDepartmentId = cached['deptId'] as String?;
      _selectedCategoryId = cached['categoryId'] as String?;
      _sortBy = (cached['sortBy'] as String?) ?? _sortBy;
      _sortAscending = (cached['sortAscending'] as bool?) ?? _sortAscending;
      final search = cached['search'] as String?;
      if (search != null && search.isNotEmpty) {
        _searchController.text = search;
      }
    });
  }

  void _persistFilters() {
    _cache.set(_filtersCacheKey, <String, dynamic>{
      'deptId': _selectedDepartmentId,
      'categoryId': _selectedCategoryId,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
      'search': _searchController.text.trim(),
    });
  }

  Future<void> _showSortDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sort Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Name'),
                value: 'name',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              RadioListTile<String>(
                title: const Text('Asset ID'),
                value: 'assetId',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              RadioListTile<String>(
                title: const Text('Status'),
                value: 'status',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              RadioListTile<String>(
                title: const Text('Purchase Date'),
                value: 'purchaseDate',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Ascending'),
                value: _sortAscending,
                onChanged: (value) => setState(() => _sortAscending = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _sortItems();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Assets'),
            if (_filteredItems.isNotEmpty)
              Text(
                '${_filteredItems.length} items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ..._departments.map((dept) => DropdownMenuItem(
                                value: dept.id,
                                child: Text(dept.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDepartmentId = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ..._categories
                              .where((c) => c.isActive)
                              .map((cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadItems();
        },
        child: _isLoading && _filteredItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _filteredItems.isEmpty
                ? NetworkUtils.isNetworkError(_error!)
                    ? NetworkErrorWidget(
                        error: _error,
                        onRetry: _loadItems,
                      )
                    : ErrorRetryWidget(
                        message: NetworkUtils.getErrorMessage(_error!),
                        onRetry: _loadItems,
                      )
                : _filteredItems.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No Items Found',
                        message: _searchController.text.isNotEmpty ||
                                _selectedDepartmentId != null ||
                                _selectedCategoryId != null
                            ? 'Try adjusting your filters'
                            : 'Get started by adding your first item',
                        action: _searchController.text.isEmpty &&
                                _selectedDepartmentId == null &&
                                _selectedCategoryId == null
                            ? FilledButton.icon(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(AppRouter.addItemRoute),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              )
                            : null,
                      )
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(item.name[0].toUpperCase()),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              'Asset: ${item.assetId} • Dept: ${_departmentLabelFor(item)} • Cat: ${_categoryLabelFor(item)}'
                              '${item.purchaseDate != null ? '\n${DateFormatter.formatDate(item.purchaseDate)}' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.status == 'active')
                                  Icon(Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary, size: 20)
                                else if (item.status == 'pending')
                                  Icon(Icons.pending,
                                      color: Theme.of(context).colorScheme.secondary, size: 20)
                                else
                                  Icon(Icons.cancel,
                                      color: Theme.of(context).colorScheme.outline, size: 20),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.itemDetailsRoute,
                                arguments: ItemDetailArgs(item: item),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
