import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late Future<List<Category>> _categoriesFuture;
  String _searchTerm = '';
  _SortField _sortField = _SortField.name;

  @override
  void initState() {
    super.initState();
    _reloadCategories();
  }

  void _reloadCategories() {
    _categoriesFuture = context.read<CatalogService>().listCategories(includeInactive: true);
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final isActive = ValueNotifier<bool>(category?.isActive ?? true);
    final service = context.read<CatalogService>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: isActive,
                builder: (context, value, _) {
                  return SwitchListTile(
                    value: value,
                    onChanged: (newValue) => isActive.value = newValue,
                    title: const Text('Active'),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final description = descController.text.trim().isEmpty ? null : descController.text.trim();
      final active = isActive.value;
      if (category == null) {
        await service.createCategory(name: name, description: description, isActive: active);
      } else {
        final updated = Category(
          id: category.id,
          name: name,
          description: description,
          parentId: category.parentId,
          sortOrder: category.sortOrder,
          isActive: active,
        );
        await service.updateCategory(updated);
      }
      setState(_reloadCategories);
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final service = context.read<CatalogService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteCategory(category.id);
      setState(_reloadCategories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Management')),
      body: ItemManagementOnly(
        showError: true,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search categories…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _searchTerm = value.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _SortField.values.map((field) {
                    final selected = field == _sortField;
                    return ChoiceChip(
                      label: Text(field == _SortField.name ? 'Name' : 'Status'),
                      selected: selected,
                      onSelected: (_) => setState(() => _sortField = field),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(itemCount: 10, itemHeight: 64),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load categories: ${snapshot.error}'));
                }
                var categories = snapshot.data ?? const [];
                if (_searchTerm.isNotEmpty) {
                  categories = categories
                      .where((category) => category.name.toLowerCase().contains(_searchTerm))
                      .toList();
                }
                categories.sort((a, b) {
                  switch (_sortField) {
                    case _SortField.name:
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    case _SortField.status:
                      return b.isActive.toString().compareTo(a.isActive.toString());
                  }
                });
                if (categories.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.15),
                          child: const Icon(Icons.category, color: Colors.green),
                        ),
                        title: Text(category.name),
                        subtitle: Text(category.isActive ? 'Active' : 'Inactive', style: TextStyle(color: category.isActive ? Colors.green : Colors.red)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showCategoryDialog(category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(category),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: ItemManagementOnly(
        child: FloatingActionButton(
          onPressed: () => _showCategoryDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

enum _SortField { name, status }
