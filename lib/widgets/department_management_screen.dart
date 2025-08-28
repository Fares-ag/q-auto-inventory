// lib/widgets/department_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

class DepartmentManagementScreen extends StatelessWidget {
  const DepartmentManagementScreen({Key? key}) : super(key: key);

  void _showDepartmentDialog(BuildContext context, {Department? department}) {
    final isEditing = department != null;
    final nameController =
        TextEditingController(text: isEditing ? department.name : '');
    bool isActive = isEditing ? department.isActive : true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Department' : 'Add Department'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Department Name'),
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
                final dataStore =
                    Provider.of<LocalDataStore>(context, listen: false);
                if (isEditing) {
                  dataStore.updateDepartment(
                      department.id, nameController.text.trim(), isActive);
                } else {
                  dataStore.addDepartment(nameController.text.trim());
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
    final departments = dataStore.departments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management'),
      ),
      body: ListView.builder(
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          return ListTile(
            title: Text(dept.name),
            subtitle: Text(dept.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                    color: dept.isActive ? Colors.green : Colors.red)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showDepartmentDialog(context, department: dept),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
