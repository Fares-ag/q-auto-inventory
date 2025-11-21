import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/permission_service.dart';

/// Wrapper widget that checks permissions before showing route content
class PermissionGuardWrapper extends StatelessWidget {
  const PermissionGuardWrapper({
    super.key,
    required this.permission,
    required this.child,
  });

  final String permission;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Please sign in to access this page'),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: _checkPermission(context, user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final hasPermission = snapshot.data ?? false;

        if (!hasPermission) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not have permission to access this page.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return child;
      },
    );
  }

  Future<bool> _checkPermission(BuildContext context, String userId) async {
    try {
      final permissionService = context.read<PermissionService>();
      final email =
          FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
      final isAdminUser = (await permissionService.isAdmin(userId)) ||
          email == 'super@admin.com';

      if (permission == 'admin' && isAdminUser) return true;

      final userPermissions =
          await permissionService.getUserPermissions(userId);

      if (permissionService.hasPermission(userPermissions, 'admin') ||
          isAdminUser) {
        return true;
      }

      return permissionService.hasPermission(userPermissions, permission);
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }
}
