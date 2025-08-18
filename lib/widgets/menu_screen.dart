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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    // CORRECTED: Wrap the destination screen in a provider
                    builder: (context) => ChangeNotifierProvider.value(
                      value: LocalDataStore(),
                      child: const SuperAdminDashboard(),
                    ),
                  ),
                ),
                child: const Text('Super Admin Dashboard'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    // CORRECTED: Wrap the destination screen in a provider
                    builder: (context) => ChangeNotifierProvider.value(
                      value: LocalDataStore(),
                      child: const AdminDashboardScreen(
                        userDepartment: 'IT',
                        onUpdateItem: print,
                      ),
                    ),
                  ),
                ),
                child: const Text('Admin Dashboard'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    // CORRECTED: Wrap the destination screen in a provider
                    builder: (context) => ChangeNotifierProvider.value(
                      value: LocalDataStore(),
                      child: const HistoryScreen(),
                    ),
                  ),
                ),
                child: const Text('View All History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
