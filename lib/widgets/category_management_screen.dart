// lib/widgets/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final isEditing = category != null;
    final nameController =
        TextEditingController(text: isEditing ? category.name : '');
    bool isActive = isEditing ? category.isActive : true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Category Name'),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() => isActive = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;

                final dataStore =
                    Provider.of<LocalDataStore>(context, listen: false);
                if (isEditing) {
                  dataStore.updateCategory(
                      category.id, nameController.text.trim(), isActive);
                } else {
                  dataStore.addCategory(nameController.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final categories = dataStore.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ListTile(
            title: Text(cat.name),
            subtitle: Text(cat.isActive ? 'Active' : 'Inactive',
                style:
                    TextStyle(color: cat.isActive ? Colors.green : Colors.red)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showCategoryDialog(context, category: cat),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
