import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../services/user_provisioning_service.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/provisioned_user_result_dialog.dart';
import '../../widgets/skeleton_list.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<AppUser>> _usersFuture;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _reload();
    // Ensure default permission sets exist (Finance, Operator, Admin)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffService>().ensureDefaultPermissionSets();
    });
  }

  void _reload() {
    _usersFuture = context.read<UserService>().listUsers();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _usersFuture;
  }

  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? deptId;
    String? roleId;
    final userSvc = context.read<UserService>();
    final departmentService = context.read<DepartmentService>();
    final staffService = context.read<StaffService>();

    final departmentsList =
        await departmentService.listDepartments(includeInactive: false);
    final permissionList = await staffService.listPermissionSets();

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password (optional)',
                    helperText:
                        'Leave blank to auto-generate a temporary password',
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: departmentsList
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (value) => deptId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role *'),
                  items: permissionList
                      .map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Select a role' : null,
                  onChanged: (value) => roleId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _adding = true);
      try {
        final displayName = nameCtrl.text.trim();
        final email = emailCtrl.text.trim();
        final password = passwordCtrl.text.trim();

        final result = await userSvc.createUser(
          email: email,
          displayName: displayName,
          departmentId: deptId,
          role: roleId,
          password: password.isEmpty ? null : password,
        );
        await _refresh();
        if (context.mounted) {
          await showProvisionedUserResultDialog(
            context,
            result,
            email: email,
          );
        }
      } on UserProvisioningException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add user: $e')),
          );
        }
      } finally {
        if (context.mounted) setState(() => _adding = false);
        nameCtrl.dispose();
        emailCtrl.dispose();
        passwordCtrl.dispose();
      }
    } else {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passwordCtrl.dispose();
    }
  }

  Future<void> _showEditUserDialog(AppUser user) async {
    final nameCtrl = TextEditingController(text: user.displayName);
    final emailCtrl = TextEditingController(text: user.email);
    String? deptId = user.departmentId;
    String? roleId = user.permissionSetId;
    final userSvc = context.read<UserService>();
    final departmentService = context.read<DepartmentService>();
    final staffService = context.read<StaffService>();

    final departmentsList =
        await departmentService.listDepartments(includeInactive: false);
    final permissionList = await staffService.listPermissionSets();

    // Validate roleId - it might be a name instead of an ID
    // Try to find matching permission set by ID first, then by name
    String? validRoleId;
    if (roleId != null && roleId.isNotEmpty) {
      // First, check if it's a valid permission set ID
      final matchingById = permissionList.where((p) => p.id == roleId).toList();
      if (matchingById.length == 1) {
        validRoleId = matchingById.first.id;
      } else {
        // Not found by ID or multiple matches, try to find by name (case-insensitive)
        final roleIdLower = roleId.toLowerCase();
        final matchingByName = permissionList
            .where((p) => p.name.toLowerCase() == roleIdLower)
            .toList();
        if (matchingByName.length == 1) {
          validRoleId = matchingByName.first.id;
        } else if (matchingByName.length > 1) {
          // Multiple permission sets with same name - use the first one
          validRoleId = matchingByName.first.id;
        }
        // If no matches found, validRoleId remains null
      }
    }
    
    // Final validation: ensure validRoleId exists in permission list
    // Also check for duplicate IDs (shouldn't happen, but safety check)
    if (validRoleId != null) {
      final matchingIds = permissionList.where((p) => p.id == validRoleId).toList();
      if (matchingIds.length != 1) {
        // Either doesn't exist or has duplicates - set to null
        validRoleId = null;
      }
    }

    // Ensure deptId is valid
    String? validDeptId = deptId;
    if (deptId != null && deptId.isNotEmpty) {
      final deptExists = departmentsList.any((d) => d.id == deptId);
      if (!deptExists) {
        validDeptId = null;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: validDeptId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departmentsList
                    .map((d) =>
                        DropdownMenuItem(value: d.id, child: Text(d.name)))
                    .toList(),
                onChanged: (value) => deptId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: validRoleId != null &&
                        permissionList.any((p) => p.id == validRoleId)
                    ? validRoleId
                    : null,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Select Role'),
                  ),
                  ...permissionList
                      .map((p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.name),
                          ))
                      .toList(),
                  // If the current roleId isn't in permissionList, show it so user can see/edit
                  if (validRoleId == null && roleId != null) ...[
                    if (roleId!.isNotEmpty &&
                        !permissionList.any((p) {
                          return p.id == roleId ||
                              p.name.toLowerCase() == roleId!.toLowerCase();
                        }))
                      DropdownMenuItem<String?>(
                        value: roleId,
                        child: Text(roleId!),
                      ),
                  ],
                ],
                onChanged: (value) => roleId = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await userSvc.updateUser(
          user.id,
          email: emailCtrl.text.trim(),
          displayName: nameCtrl.text.trim(),
          departmentId: deptId,
          role: roleId,
        );
        await _refresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update user: $e')),
          );
        }
      } finally {
        // Dispose controllers after use
        nameCtrl.dispose();
        emailCtrl.dispose();
      }
    } else {
      // Dispose controllers if dialog was cancelled
      nameCtrl.dispose();
      emailCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();
    final departmentService = context.read<DepartmentService>();
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: AdminOnly(
        showError: true,
        child: FutureBuilder<List<AppUser>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(itemCount: 10, itemHeight: 72),
              );
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Failed to load users: ${snapshot.error}'));
            }
            final users = snapshot.data ?? const [];
            if (users.isEmpty) {
              return const Center(child: Text('No users available.'));
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Department>>(
                future: departmentService.listDepartments(includeInactive: true),
                builder: (context, deptSnapshot) {
                  final departments = deptSnapshot.data ?? [];
                  final deptMap = {for (var d in departments) d.id: d.name};

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final deptName = user.departmentId != null
                          ? deptMap[user.departmentId] ?? user.departmentId
                          : 'N/A';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                              child: Text(user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?')),
                          title: Text(user.displayName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${user.email}'),
                              Text('Department: $deptName'),
                              if (user.permissionSetId != null)
                                Text('Role: ${user.permissionSetId}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: !user.isDisabled,
                                onChanged: (value) async {
                                  await userService.disableUser(user.id,
                                      disabled: !value);
                                  await _refresh();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                            ],
                          ),
                          onTap: () => _showEditUserDialog(user),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: AdminOnly(
        child: FloatingActionButton(
          onPressed: _adding ? null : _showAddUserDialog,
          child: _adding
              ? const CircularProgressIndicator()
              : const Icon(Icons.person_add_alt_1),
        ),
      ),
    );
  }
}

