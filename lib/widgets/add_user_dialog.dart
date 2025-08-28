// lib/widgets/add_user_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';

/// A dialog for creating a new user on the fly.
void showAddUserDialog(BuildContext context, List<Department> departments,
    Function(LocalUser) onUserCreated) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  String? selectedDepartment;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add New User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'User Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'User Email'),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: departments.map((dept) {
                    return DropdownMenuItem(
                        value: dept.name, child: Text(dept.name));
                  }).toList(),
                  onChanged: (value) {
                    selectedDepartment = value;
                  },
                  validator: (value) =>
                      value == null ? 'Please select a department' : null,
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newUser = LocalUser(
                  id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  roleId: 'operator', // Default new users to 'operator'
                  department: selectedDepartment!,
                  isActive: true,
                );
                onUserCreated(newUser);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add User'),
          ),
        ],
      );
    },
  );
}
