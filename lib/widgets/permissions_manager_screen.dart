// lib/widgets/permissions_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

class PermissionsManagerScreen extends StatefulWidget {
  const PermissionsManagerScreen({Key? key}) : super(key: key);

  @override
  _PermissionsManagerScreenState createState() =>
      _PermissionsManagerScreenState();
}

class _PermissionsManagerScreenState extends State<PermissionsManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Manager'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Role Permissions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...dataStore.permissionSets
                .map((permissionSet) =>
                    _buildPermissionSetCard(context, permissionSet))
                .toList(),
            const Divider(height: 32),
            const Text('User Activation/Deactivation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...dataStore.users
                .map((user) => _buildUserCard(context, user))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSetCard(
      BuildContext context, PermissionSet permissionSet) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(permissionSet.name),
        children: permissionSet.permissions.entries.map((permission) {
          return CheckboxListTile(
            title: Text(permission.key),
            value: permission.value,
            onChanged: (bool? newValue) {
              if (newValue != null) {
                final updatedPermissions =
                    Map<String, bool>.from(permissionSet.permissions);
                updatedPermissions[permission.key] = newValue;
                dataStore.updatePermissionSet(
                    permissionSet.id, updatedPermissions);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, LocalUser user) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(user.email),
        subtitle: Text('Role: ${user.roleId}'),
        trailing: Switch(
          value: user.isActive,
          onChanged: (bool newValue) {
            dataStore.toggleUserActivation(user.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${user.email} is now ${newValue ? 'active' : 'inactive'} (prototype)'),
            ));
          },
        ),
      ),
    );
  }
}
