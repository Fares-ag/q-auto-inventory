import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/firebase_services.dart';
import '../services/permission_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/root_shell.dart';
import '../screens/admin/super_admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrapper = context.watch<FirebaseBootstrapper>();
    
    return StreamBuilder<User?>(
      stream: bootstrapper.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final user = snapshot.data;
        
        if (user == null) {
          return const LoginScreen();
        }
        
        // After login, check if the user is an admin and route accordingly
        final permissionService = context.read<PermissionService>();
        return FutureBuilder<List<String>>(
          future: permissionService.getUserPermissions(user.uid),
          builder: (context, permSnap) {
            if (permSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final permissions = permSnap.data ?? const <String>[];
            final isAdmin = permissionService.hasPermission(permissions, 'admin');
            final email = user.email ?? '';
            if (isAdmin || email.toLowerCase() == 'super@admin.com') {
              return const SuperAdminDashboardScreen();
            }
            return const RootShell();
          },
        );
      },
    );
  }
}

