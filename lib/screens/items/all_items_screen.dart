import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../navigation/app_router.dart';
import '../../services/firebase_services.dart';
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
  String? _selectedDepartmentId;
  String? _selectedCategoryId;
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<InventoryItem> _filteredItems = [];
  List<Department> _departments = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items ?? [];
    _loadFilters();
    if (widget.items == null) {
      _loadItems();
    }
  }

  Future<void> _loadFilters() async {
    final deptService = context.read<DepartmentService>();
    final catalog = context.read<CatalogService>();
    
    final departments = await deptService.listDepartments(includeInactive: false);
    final categories = await catalog.listCategories();
    
    setState(() {
      _departments = departments;
      _categories = categories;
    });
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
      final items = await catalog.listItems(
        limit: 5000,
        departmentId: _selectedDepartmentId,
        categoryId: _selectedCategoryId,
        searchQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _filteredItems = items;
        _isLoading = false;
        _error = null;
      });
      _sortItems(); // Apply sorting after loading
    } catch (e) {
      if (!mounted) return;

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
        title: const Text('All Items'),
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
                        value: _selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
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
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
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
                  message: _searchController.text.isNotEmpty || _selectedDepartmentId != null || _selectedCategoryId != null
                      ? 'Try adjusting your filters'
                      : 'Get started by adding your first item',
                  action: _searchController.text.isEmpty && _selectedDepartmentId == null && _selectedCategoryId == null
                      ? FilledButton.icon(
                          onPressed: () => Navigator.of(context).pushNamed(AppRouter.addItemRoute),
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
                        '${item.assetId} • ${item.categoryId}${item.purchaseDate != null ? '\n${DateFormatter.formatDate(item.purchaseDate)}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.status == 'active')
                            const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          else if (item.status == 'pending')
                            const Icon(Icons.pending, color: Colors.orange, size: 20)
                          else
                            const Icon(Icons.cancel, color: Colors.grey, size: 20),
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
