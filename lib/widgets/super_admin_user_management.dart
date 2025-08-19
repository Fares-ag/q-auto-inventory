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
        email: 'test1@example.com',
        roleId: 'operator',
        isActive: true),
    LocalUser(
        id: '5',
        email: 'test2@example.com',
        roleId: 'operator',
        isActive: true),
    LocalUser(
        id: '6', email: 'test3@example.com', roleId: 'admin', isActive: true),
  ];

  /// Simulates a bulk user import by adding a predefined list of users to the data store.
  void _addUsersBulk() {
    // Get the data store instance without listening to changes, as we are just performing an action.
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    dataStore.addUsersBulk(_dummyBulkUsers);
    // Show a confirmation message to the user.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Bulk users added! (prototype)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Access the LocalDataStore provided by the Provider package.
    // This will cause the widget to rebuild whenever the user data changes.
    final dataStore = Provider.of<LocalDataStore>(context);
    final users = dataStore.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Button to trigger the bulk user import feature.
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _addUsersBulk,
            tooltip: 'Bulk Import Users',
          ),
        ],
      ),
      // Use ListView.builder for an efficient, scrollable list of users.
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(user.email),
              subtitle: Text(
                  'Role: ${user.roleId} | Status: ${user.isActive ? 'Active' : 'Inactive'}'),
              // The trailing section contains widgets for modifying the user.
              trailing: Row(
                mainAxisSize: MainAxisSize.min, // Keep the row compact.
                children: [
                  // Switch to toggle the user's active status.
                  Switch(
                    value: user.isActive,
                    onChanged: (bool newValue) {
                      // Call the data store method to update the user's status.
                      dataStore.toggleUserActivation(user.id);
                    },
                  ),
                  // Dropdown to change the user's role.
                  DropdownButton<String>(
                    value: user.roleId,
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != user.roleId) {
                        // Call the data store method to update the role.
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
      // Floating Action Button to navigate to the user creation screen.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SuperAdminCreateUser(
                // The onSave callback is triggered when a new user is created.
                onSave: (newUser) {
                  // Create a new LocalUser object from the form data.
                  final newLocalUser = LocalUser(
                    id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                    email: newUser['email']!,
                    roleId: newUser['role']!,
                  );
                  // Add the new user to the data store.
                  dataStore.addUser(newLocalUser);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('User created (prototype)'),
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
