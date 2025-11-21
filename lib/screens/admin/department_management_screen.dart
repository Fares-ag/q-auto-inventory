import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  Future<void> _showDepartmentDialog(BuildContext context, {Department? department}) async {
    final nameController = TextEditingController(text: department?.name ?? '');
    final descriptionController = TextEditingController(text: department?.description ?? '');
    final service = context.read<DepartmentService>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(department == null ? 'Add Department' : 'Edit Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Department Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
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
      final description = descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim();
      if (department == null) {
        await service.addDepartment(name, description: description);
      } else {
        await service.updateDepartment(
          department.id,
          name: name,
          description: description,
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Department department) async {
    final service = context.read<DepartmentService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete "${department.name}"?'),
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
      await service.deleteDepartment(department.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DepartmentService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Department Management')),
      body: DepartmentManagementOnly(
        showError: true,
        child: StreamBuilder<List<Department>>(
        stream: service.watchDepartments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonList(itemCount: 8, itemHeight: 64),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load departments: ${snapshot.error}'));
          }
          final departments = snapshot.data ?? const [];
          if (departments.isEmpty) {
            return const Center(child: Text('No departments found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: departments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final department = departments[index];
              return ListTile(
                title: Text(department.name),
                subtitle: Text(department.isActive ? 'Active' : 'Inactive', style: TextStyle(color: department.isActive ? Colors.green : Colors.red)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(department.isActive ? Icons.visibility_off : Icons.visibility),
                      tooltip: department.isActive ? 'Deactivate' : 'Activate',
                      onPressed: () => service.setDepartmentStatus(department.id, !department.isActive),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showDepartmentDialog(context, department: department),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, department),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      ),
      floatingActionButton: DepartmentManagementOnly(
        child: FloatingActionButton(
          onPressed: () => _showDepartmentDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
