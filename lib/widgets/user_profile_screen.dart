// lib/widgets/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/history_screen.dart';
import 'package:flutter_application_1/widgets/login_screen.dart';
import 'package:flutter_application_1/widgets/super_admin_dashboard.dart';
import 'package:flutter_application_1/widgets/admin_dashboard_screen.dart';
import 'package:flutter_application_1/widgets/settings_screen.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<LocalDataStore>(context, listen: false),
          child: const HistoryScreen(),
        ),
      ),
    );
  }

  void _navigateToSuperAdminDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<LocalDataStore>(context, listen: false),
          child: const SuperAdminDashboard(),
        ),
      ),
    );
  }

  void _navigateToAdminDashboard(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: dataStore,
          child: AdminDashboardScreen(
            userDepartment: dataStore.currentUser.department,
            onUpdateItem: dataStore.updateItem,
          ),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<LocalDataStore>(context, listen: false),
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final user = dataStore.currentUser;
    final theme = Theme.of(context);

    final bool isSuperAdmin = user.roleId == 'superAdmin';
    final bool isAdmin = user.roleId == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            // --- Profile Header ---
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.person_outline,
                        size: 32, color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: ${user.roleId}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Menu Options ---
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Column(
                children: [
                  if (isSuperAdmin)
                    _buildMenuTile(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Super Admin Dashboard',
                      onTap: () => _navigateToSuperAdminDashboard(context),
                    ),
                  if (isAdmin)
                    _buildMenuTile(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Admin Dashboard',
                      onTap: () => _navigateToAdminDashboard(context),
                    ),
                  _buildMenuTile(
                    context,
                    icon: Icons.history_outlined,
                    title: 'View Activity History',
                    onTap: () => _navigateToHistory(context),
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => _navigateToSettings(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Sign Out Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: Icon(Icons.logout, color: Colors.black),
                label: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context,
      {required IconData icon, required String title, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final Color tileColor = Colors.grey[800]!;

    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(title,
          style: theme.textTheme.titleMedium?.copyWith(color: tileColor)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
