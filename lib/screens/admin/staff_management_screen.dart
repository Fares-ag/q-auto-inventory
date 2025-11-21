import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  late Future<List<StaffMember>> _staffFuture;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _staffFuture = context.read<StaffService>().listStaff(activeOnly: false);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _staffFuture;
  }

  Future<void> _showAddStaffDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? deptId;
    String? roleId;
    bool createLogin = true;
    final svc = context.read<StaffService>();
    final userSvc = context.read<UserService>();
    final departmentService = context.read<DepartmentService>();
    final permissionService = context.read<StaffService>();

    final departmentsList = await departmentService.listDepartments(includeInactive: false);
    final permissionList = await permissionService.listPermissionSets();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: deptId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departmentsList
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                    .toList(),
                onChanged: (value) => deptId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: roleId,
                decoration: const InputDecoration(labelText: 'Role'),
                items: permissionList
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (value) => roleId = value,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: createLogin,
                onChanged: (value) => setState(() => createLogin = value ?? true),
                title: const Text('Create login in Users collection'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _adding = true);
      try {
        final displayName = nameCtrl.text.trim();
        final email = emailCtrl.text.trim();
        final selectedDeptId = deptId;
        final selectedRoleId = roleId;

        await svc.addStaffMember(
          displayName: displayName,
          email: email,
          departmentId: selectedDeptId,
          role: selectedRoleId,
        );
        if (createLogin) {
          await userSvc.createUser(
            email: email,
            displayName: displayName,
            departmentId: selectedDeptId,
            role: selectedRoleId,
          );
        }
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member added')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add staff: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _adding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffService = context.read<StaffService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: StaffManagementOnly(
        showError: true,
        child: FutureBuilder<List<StaffMember>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonList(itemCount: 10, itemHeight: 72),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load staff: ${snapshot.error}'));
          }
          final staff = snapshot.data ?? const [];
          if (staff.isEmpty) {
            return const Center(child: Text('No staff available.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: staff.length,
              itemBuilder: (context, index) {
                final member = staff[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?')),
                    title: Text(member.displayName),
                    subtitle: Text('Email: ${member.email}\nDepartment: ${member.departmentId ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: member.isActive,
                          onChanged: (value) async {
                            await staffService.setStaffActive(member.id, value);
                            await _refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove Staff Member'),
                                content: Text('Remove ${member.displayName}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await staffService.deleteStaff(member.id);
                              await _refresh();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      ),
      floatingActionButton: StaffManagementOnly(
        child: FloatingActionButton(
          onPressed: _adding ? null : _showAddStaffDialog,
          child: _adding
              ? const CircularProgressIndicator()
              : const Icon(Icons.person_add_alt_1),
        ),
      ),
    );
  }
}
