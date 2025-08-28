// lib/widgets/super_admin_user_management.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/super_admin_create_user.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

/// A screen for super administrators to manage all users in the application.
/// Allows viewing, creating, and modifying user roles and statuses.
class SuperAdminUserManagement extends StatefulWidget {
  const SuperAdminUserManagement({Key? key}) : super(key: key);

  @override
  State<SuperAdminUserManagement> createState() =>
      _SuperAdminUserManagementState();
}

class _SuperAdminUserManagementState extends State<SuperAdminUserManagement> {
  /// A placeholder list of users for the "bulk add" prototype feature.
  final List<LocalUser> _dummyBulkUsers = [
    LocalUser(
        id: '4',
        name: 'Test User 1',
        email: 'test1@example.com',
        roleId: 'operator',
        department: 'IT',
        isActive: true),
    LocalUser(
        id: '5',
        name: 'Test User 2',
        email: 'test2@example.com',
        roleId: 'operator',
        department: 'Operations',
        isActive: true),
    LocalUser(
        id: '6',
        name: 'Test Admin 1',
        email: 'test3@example.com',
        roleId: 'admin',
        department: 'IT',
        isActive: true),
  ];

  /// Simulates a bulk user import by adding a predefined list of users to the data store.
  void _addUsersBulk() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    dataStore.addUsersBulk(_dummyBulkUsers);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Bulk users added! (prototype)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final users = dataStore.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _addUsersBulk,
            tooltip: 'Bulk Import Users',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(user.name), // Display the user's name
              subtitle: Text(
                  'Email: ${user.email}\nRole: ${user.roleId} | Status: ${user.isActive ? 'Active' : 'Inactive'}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: user.isActive,
                    onChanged: (bool newValue) {
                      dataStore.toggleUserActivation(user.id);
                    },
                  ),
                  DropdownButton<String>(
                    value: user.roleId,
                    underline: Container(), // Hides the underline
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != user.roleId) {
                        dataStore.updateUserRole(user.id, newValue);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                          value: 'superAdmin', child: Text('Super Admin')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'operator', child: Text('Operator')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SuperAdminCreateUser(
                onSave: (newUserMap) {
                  final newLocalUser = LocalUser(
                    id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                    name: newUserMap['name']!,
                    email: newUserMap['email']!,
                    roleId: newUserMap['role']!,
                    department: newUserMap['department']!,
                  );
                  dataStore.addUser(newLocalUser);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('User created successfully'),
                  ));
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
