import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../utils/network_utils.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';
import '../auth/login_screen.dart';
import '../items/item_detail_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  late Future<_SuperAdminData> _dashboardFuture;
  String? _selectedDepartment;
  String? _selectedStaff;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<_SuperAdminData> _loadDashboardData() async {
    final catalog = context.read<CatalogService>();
    final departmentService = context.read<DepartmentService>();
    final staffService = context.read<StaffService>();
    final issueService = context.read<IssueService>();

    final items = await catalog.listAllItems(pageSize: 1000);
    final departments = await departmentService.listDepartments(includeInactive: true);
    final staff = await staffService.listStaff(activeOnly: false);
    final issues = await issueService.listOpenIssues(limit: 200);

    final tagged = items.where((item) => item.qrCodeUrl != null && item.qrCodeUrl!.isNotEmpty).length;
    final unassigned = items.where((item) => item.assignedTo == null || item.assignedTo!.isEmpty).length;

    final categoryCounts = <String, int>{};
    final departmentCounts = <String, int>{};
    final staffCounts = <String, int>{};

    for (final item in items) {
      final departmentKey = item.departmentId.isEmpty ? 'Unassigned' : item.departmentId;
      categoryCounts.update(item.categoryId, (value) => value + 1, ifAbsent: () => 1);
      departmentCounts.update(departmentKey, (value) => value + 1, ifAbsent: () => 1);
      if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
        staffCounts.update(item.assignedTo!, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return _SuperAdminData(
      items: items,
      departments: departments,
      staff: staff,
      issuesCount: issues.length,
      taggedItems: tagged,
      unassignedItems: unassigned,
      categoryCounts: categoryCounts,
      departmentCounts: departmentCounts,
      staffCounts: staffCounts,
    );
  }

  void _openRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Data Audit',
            icon: const Icon(Icons.query_stats_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/admin/data-audit'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: FutureBuilder<_SuperAdminData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonList(itemCount: 10, itemHeight: 72),
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error!;
            return NetworkUtils.isNetworkError(error)
                ? NetworkErrorWidget(
                    error: error,
                    onRetry: () {
                      setState(() {
                        _dashboardFuture = _loadDashboardData();
                      });
                    },
                  )
                : ErrorRetryWidget(
                    message: NetworkUtils.getErrorMessage(error),
                    onRetry: () {
                      setState(() {
                        _dashboardFuture = _loadDashboardData();
                      });
                    },
                  );
          }
          final data = snapshot.data!;

          final filteredItems = data.items.where((item) {
            final matchesDept = _selectedDepartment == null || _selectedDepartment == 'All' || item.departmentId == _selectedDepartment;
            final matchesStaff = _selectedStaff == null || _selectedStaff == 'All' || item.assignedTo == _selectedStaff;
            return matchesDept && matchesStaff;
          }).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          final uniqueDepartments = ['All', ...data.departmentCounts.keys.toList()..sort()];
          final uniqueStaff = ['All', ...data.staffCounts.keys.toList()..sort()];

          final shortcuts = <_ShortcutAction>[
            _ShortcutAction(
              label: 'Departments',
              icon: Icons.apartment,
              onTap: () => _openRoute('/admin/departments'),
            ),
            _ShortcutAction(
              label: 'Categories',
              icon: Icons.category,
              onTap: () => _openRoute('/admin/categories'),
            ),
            _ShortcutAction(
              label: 'Permissions',
              icon: Icons.shield_outlined,
              onTap: () => _openRoute('/admin/permissions'),
            ),
            _ShortcutAction(
              label: 'Staff',
              icon: Icons.group_outlined,
              onTap: () => _openRoute('/admin/staff'),
            ),
            _ShortcutAction(
              label: 'Approvals',
              icon: Icons.approval,
              onTap: () => _openRoute('/approvals'),
            ),
            _ShortcutAction(
              label: 'Reports',
              icon: Icons.bar_chart,
              onTap: () => _openRoute('/reports'),
            ),
            _ShortcutAction(
              label: 'Import Excel',
              icon: Icons.upload_file,
              onTap: () => _openRoute('/admin/import'),
            ),
            _ShortcutAction(
              label: 'Data Audit',
              icon: Icons.query_stats_outlined,
              onTap: () => _openRoute('/admin/data-audit'),
            ),
            _ShortcutAction(
              label: 'Locations',
              icon: Icons.place_outlined,
              onTap: () => _openRoute('/admin/locations'),
            ),
            _ShortcutAction(
              label: 'System Settings',
              icon: Icons.tune_outlined,
              onTap: () => _openRoute('/admin/system-settings'),
            ),
            _ShortcutAction(
              label: 'Vehicle Check-outs',
              icon: Icons.directions_car_outlined,
              onTap: () => _openRoute('/admin/vehicle-checkouts'),
            ),
            _ShortcutAction(
              label: 'Vehicle Maintenance',
              icon: Icons.build_outlined,
              onTap: () => _openRoute('/admin/vehicle-maintenance'),
            ),
          ];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadDashboardData();
              });
              await _dashboardFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Management', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: shortcuts.map((action) {
                    final btn = SizedBox(
                      width: MediaQuery.of(context).size.width > 600 ? 180 : (MediaQuery.of(context).size.width - 48) / 2,
                      child: OutlinedButton.icon(
                        onPressed: action.onTap,
                        icon: Icon(action.icon),
                        label: Text(action.label),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                      ),
                    );
                    // Guard shortcuts by area
                    if (action.label == 'Reports') return ReportsOnly(child: btn);
                    if (action.label == 'Import Excel') return ItemManagementOnly(child: btn);
                    if (action.label == 'Departments') return DepartmentManagementOnly(child: btn);
                    if (action.label == 'Staff') return StaffManagementOnly(child: btn);
                    if (action.label == 'Permissions') return AdminOnly(child: btn);
                    if (action.label == 'Approvals') return ItemManagementOnly(child: btn);
                    if (action.label == 'Categories') return ItemManagementOnly(child: btn);
                    if (action.label == 'Data Audit') return AdminOnly(child: btn);
                    if (action.label == 'Locations') return DepartmentManagementOnly(child: btn);
                    if (action.label == 'System Settings') return AdminOnly(child: btn);
                    if (action.label == 'Vehicle Check-outs') return AdminOnly(child: btn);
                    if (action.label == 'Vehicle Maintenance') return AdminOnly(child: btn);
                    return btn;
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Application Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatsGrid(data: data),
                const SizedBox(height: 24),
                Text('Visual Reports', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _CategoryReportCard(categoryCounts: data.categoryCounts),
                const SizedBox(height: 12),
                _DepartmentReportCard(departmentCounts: data.departmentCounts),
                const SizedBox(height: 24),
                Text('Filter & View Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDepartment ?? 'All',
                                items: uniqueDepartments
                                    .map((dept) => DropdownMenuItem<String>(value: dept, child: Text(dept)))
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedDepartment = value),
                                decoration: const InputDecoration(labelText: 'Department'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStaff ?? 'All',
                                items: uniqueStaff
                                    .map((staff) => DropdownMenuItem<String>(value: staff, child: Text(staff)))
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedStaff = value),
                                decoration: const InputDecoration(labelText: 'Staff'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...filteredItems.take(5).map((item) => ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(item.name),
                              subtitle: Text('Dept: ${item.departmentId.isEmpty ? 'Unassigned' : item.departmentId} | Assigned: ${item.assignedTo?.isNotEmpty == true ? item.assignedTo : 'None'}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                                );
                              },
                            )),
                        if (filteredItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No assets match the current filters.'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final _SuperAdminData data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatTile(label: 'Total Items', value: data.items.length.toString(), icon: Icons.inventory_2),
      _StatTile(label: 'Total Staff', value: data.staff.length.toString(), icon: Icons.people_alt_outlined),
      _StatTile(label: 'Total Departments', value: data.departments.length.toString(), icon: Icons.apartment),
      _StatTile(label: 'Assigned Items', value: (data.items.length - data.unassignedItems).toString(), icon: Icons.assignment_turned_in_outlined),
      _StatTile(label: 'Unassigned Items', value: data.unassignedItems.toString(), icon: Icons.pending_actions_outlined),
      _StatTile(label: 'Tagged Items', value: data.taggedItems.toString(), icon: Icons.qr_code_2_outlined),
      _StatTile(label: 'Open Issues', value: data.issuesCount.toString(), icon: Icons.warning_amber_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stats[index].icon, size: 32),
              const SizedBox(height: 12),
              Text(stats[index].value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(stats[index].label),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryReportCard extends StatelessWidget {
  const _CategoryReportCard({required this.categoryCounts});

  final Map<String, int> categoryCounts;

  @override
  Widget build(BuildContext context) {
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets by Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sorted.take(6).map((entry) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.pie_chart_outline),
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                )),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No category data available.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentReportCard extends StatelessWidget {
  const _DepartmentReportCard({required this.departmentCounts});

  final Map<String, int> departmentCounts;

  @override
  Widget build(BuildContext context) {
    final sorted = departmentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets by Department', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sorted.take(6).map((entry) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                )),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No department data available.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

class _ShortcutAction {
  const _ShortcutAction({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _SuperAdminData {
  const _SuperAdminData({
    required this.items,
    required this.departments,
    required this.staff,
    required this.issuesCount,
    required this.taggedItems,
    required this.unassignedItems,
    required this.categoryCounts,
    required this.departmentCounts,
    required this.staffCounts,
  });

  final List<InventoryItem> items;
  final List<Department> departments;
  final List<StaffMember> staff;
  final int issuesCount;
  final int taggedItems;
  final int unassignedItems;
  final Map<String, int> categoryCounts;
  final Map<String, int> departmentCounts;
  final Map<String, int> staffCounts;
}
