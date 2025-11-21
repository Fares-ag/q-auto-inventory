import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';

class BulkAssignScreen extends StatefulWidget {
  const BulkAssignScreen({super.key});

  @override
  State<BulkAssignScreen> createState() => _BulkAssignScreenState();
}

class _BulkAssignScreenState extends State<BulkAssignScreen> {
  final List<String> _selectedItemIds = [];
  String? _selectedDepartmentId;
  String? _selectedStaffId;
  List<InventoryItem> _items = [];
  List<Department> _departments = [];
  List<StaffMember> _staff = [];
  bool _isLoading = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catalog = context.read<CatalogService>();
      final deptService = context.read<DepartmentService>();
      final staffService = context.read<StaffService>();

      final items = await catalog.listItems(limit: 1000);
      final departments = await deptService.listDepartments(includeInactive: false);
      final staff = await staffService.listStaff(activeOnly: true);

      setState(() {
        _items = items;
        _departments = departments;
        _staff = staff;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _assignItems() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    if (_selectedDepartmentId == null && _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department or staff member')),
      );
      return;
    }

    setState(() => _isAssigning = true);
    try {
      final catalog = context.read<CatalogService>();
      int successCount = 0;

      for (final itemId in _selectedItemIds) {
        try {
          final updates = <String, dynamic>{};
          if (_selectedDepartmentId != null) {
            updates['departmentId'] = _selectedDepartmentId;
          }
          if (_selectedStaffId != null) {
            updates['assignedTo'] = _selectedStaffId;
          }
          await catalog.updateItem(itemId, updates);
          successCount++;
        } catch (e) {
          // Continue with other items
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned $successCount item(s)'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning items: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Assign Items'),
        actions: [
          if (_isAssigning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _assignItems,
              tooltip: 'Assign Selected',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Assignment options
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign to:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedDepartmentId,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ..._departments.map((dept) => DropdownMenuItem(
                                  value: dept.id,
                                  child: Text(dept.name),
                                )),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedDepartmentId = value),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedStaffId,
                          decoration: const InputDecoration(
                            labelText: 'Staff Member',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ..._staff.map((member) => DropdownMenuItem(
                                  value: member.id,
                                  child: Text(member.displayName),
                                )),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedStaffId = value),
                        ),
                      ],
                    ),
                  ),
                ),
                // Selection info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_selectedItemIds.length} item(s) selected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                // Items list
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = _selectedItemIds.contains(item.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleItem(item.id),
                        title: Text(item.name),
                        subtitle: Text('${item.assetId} • ${item.departmentId}'),
                        secondary: CircleAvatar(
                          child: Text(item.name[0].toUpperCase()),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

