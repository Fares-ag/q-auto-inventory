// lib/widgets/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/super_admin_dashboard.dart';
import 'package:flutter_application_1/widgets/admin_dashboard_screen.dart';
import 'package:flutter_application_1/widgets/history_screen.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuTile(
                context,
                icon: Icons.admin_panel_settings_outlined,
                title: 'Super Admin Dashboard',
                onTap: () {
                  final dataStore =
                      Provider.of<LocalDataStore>(context, listen: false);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: dataStore,
                      child: const SuperAdminDashboard(),
                    ),
                  ));
                },
              ),
              _buildMenuTile(
                context,
                icon: Icons.dashboard_outlined,
                title: 'Admin Dashboard',
                onTap: () {
                  final dataStore =
                      Provider.of<LocalDataStore>(context, listen: false);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: dataStore,
                      child: AdminDashboardScreen(
                        userDepartment: 'IT', // Example department
                        onUpdateItem: dataStore.updateItem,
                      ),
                    ),
                  ));
                },
              ),
              _buildMenuTile(
                context,
                icon: Icons.history_outlined,
                title: 'View All History',
                onTap: () {
                  final dataStore =
                      Provider.of<LocalDataStore>(context, listen: false);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: dataStore,
                      child: const HistoryScreen(),
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context,
      {required IconData icon, required String title, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final tileColor = Colors.grey[800];

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
