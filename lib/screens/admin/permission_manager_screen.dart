import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class PermissionManagerScreen extends StatefulWidget {
  const PermissionManagerScreen({super.key});

  @override
  State<PermissionManagerScreen> createState() => _PermissionManagerScreenState();
}

class _PermissionManagerScreenState extends State<PermissionManagerScreen> {
  late Future<_PermissionData> _permissionFuture;

  @override
  void initState() {
    super.initState();
    _permissionFuture = _loadData();
  }

  Future<_PermissionData> _loadData() async {
    final staffService = context.read<StaffService>();
    final permissions = await staffService.listPermissionSets();
    final staff = await staffService.listStaff(activeOnly: false);
    return _PermissionData(permissionSets: permissions, staff: staff);
  }

  Future<void> _refresh() async {
    setState(() {
      _permissionFuture = _loadData();
    });
    await _permissionFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission Manager')),
      body: AdminOnly(
        showError: true,
        child: FutureBuilder<_PermissionData>(
        future: _permissionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonList(itemCount: 8, itemHeight: 64),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load permissions: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final staffService = context.read<StaffService>();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Manage Role Permissions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...data.permissionSets.map((set) => Card(
                      child: ExpansionTile(
                        title: Text(set.name),
                        subtitle: Text('${set.permissions.length} permissions'),
                        children: [
                          if (set.permissions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No permissions defined yet.'),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: set.permissions
                                  .map((permission) => Chip(label: Text(permission)))
                                  .toList(),
                            ),
                          TextButton.icon(
                            onPressed: () async {
                              final controller = TextEditingController();
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Add Permission'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(labelText: 'Permission Identifier'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
                                  ],
                                ),
                              );
                              if (result != null && result.isNotEmpty) {
                                final updated = [...set.permissions, result];
                                await staffService.updatePermissionSet(set.id, updated);
                                await _refresh();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Permission'),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                Text('User Activation/Deactivation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...data.staff.map((member) => Card(
                      child: ListTile(
                        title: Text(member.displayName),
                        subtitle: Text('Email: ${member.email}\nRole: ${member.role ?? 'Unassigned'}'),
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
                            const SizedBox(width: 8),
                            DropdownButton<String?>(
                              value: member.permissionSetId,
                              hint: const Text('Role'),
                              items: data.permissionSets
                                  .map((set) => DropdownMenuItem<String?>(value: set.id, child: Text(set.name)))
                                  .toList(),
                              onChanged: (value) async {
                                await staffService.updateStaffRole(member.id, value);
                                await _refresh();
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _PermissionData {
  const _PermissionData({required this.permissionSets, required this.staff});

  final List<PermissionSet> permissionSets;
  final List<StaffMember> staff;
}
