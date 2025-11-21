import 'package:flutter/material.dart';

import '../../widgets/permission_guard.dart';
import 'data_audit_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DepartmentManagementOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: const Text('Departments'),
                subtitle: const Text('Manage departments and sub-departments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/admin/departments'),
              ),
            ),
          ),
          ItemManagementOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categories'),
                subtitle: const Text('Manage item categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/admin/categories'),
              ),
            ),
          ),
          StaffManagementOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.people_outlined),
                title: const Text('Staff Management'),
                subtitle: const Text('Manage staff members and roles'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/admin/staff'),
              ),
            ),
          ),
          AdminOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Permissions'),
                subtitle: const Text('Manage permission sets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/admin/permissions'),
              ),
            ),
          ),
          ItemManagementOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Approval Queue'),
                subtitle: const Text('Review pending items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/approvals'),
              ),
            ),
          ),
          ReportsOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.assessment_outlined),
                title: const Text('Reports'),
                subtitle: const Text('Generate reports and exports'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/reports'),
              ),
            ),
          ),
          AdminOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.query_stats_outlined),
                title: const Text('Data Audit'),
                subtitle: const Text('View per-collection document counts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DataAuditScreen()),
                ),
              ),
            ),
          ),
          const Divider(),
          AdminOnly(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Super Admin Dashboard'),
                subtitle: const Text('Full system administration'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/admin/super'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
