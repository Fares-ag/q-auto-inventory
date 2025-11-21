import 'package:flutter/material.dart';

import '../../widgets/permission_guard.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          DepartmentManagementOnly(
            child: ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: const Text('Departments'),
              subtitle: const Text('Manage departments and sub-departments'),
              onTap: () => Navigator.of(context).pushNamed('/admin/departments'),
            ),
          ),
          StaffManagementOnly(
            child: ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Staff'),
              subtitle: const Text('Invite and manage team members'),
              onTap: () => Navigator.of(context).pushNamed('/admin/staff'),
            ),
          ),
          ReportsOnly(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Reports'),
              subtitle: const Text('Configure PDF and data exports'),
              onTap: () => Navigator.of(context).pushNamed('/reports'),
            ),
          ),
          ItemManagementOnly(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import from Excel'),
              subtitle: const Text('Import items from Excel file'),
              onTap: () => Navigator.of(context).pushNamed('/admin/import'),
            ),
          ),
          DepartmentManagementOnly(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: const Text('Locations'),
              subtitle: const Text('Manage locations'),
              onTap: () => Navigator.of(context).pushNamed('/admin/locations'),
            ),
          ),
          AdminOnly(
            child: ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('System Settings'),
              subtitle: const Text('Configure global system settings'),
              onTap: () => Navigator.of(context).pushNamed('/admin/system-settings'),
            ),
          ),
          AdminOnly(
            child: ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Vehicle Check-outs'),
              subtitle: const Text('View active vehicle check-outs'),
              onTap: () => Navigator.of(context).pushNamed('/admin/vehicle-checkouts'),
            ),
          ),
          AdminOnly(
            child: ListTile(
              leading: const Icon(Icons.build_outlined),
              title: const Text('Vehicle Maintenance'),
              subtitle: const Text('View scheduled maintenance'),
              onTap: () => Navigator.of(context).pushNamed('/admin/vehicle-maintenance'),
            ),
          ),
          const Divider(),
          ItemManagementOnly(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              subtitle: const Text('Manage item categories'),
              onTap: () => Navigator.of(context).pushNamed('/admin/categories'),
            ),
          ),
          AdminOnly(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Super Admin'),
              subtitle: const Text('Access super admin dashboard'),
              onTap: () => Navigator.of(context).pushNamed('/admin/super'),
            ),
          ),
        ],
      ),
    );
  }
}
