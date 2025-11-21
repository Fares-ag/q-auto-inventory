import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/permission_service.dart';

/// Widget that shows child only if user has required permission
class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showError = false,
  });

  final String permission;
  final Widget child;
  final Widget? fallback;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _checkPermission(context, user.uid, user.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return child;
        }

        if (showError && context.mounted) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have permission to access this feature.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }

  Future<bool> _checkPermission(
    BuildContext context,
    String userId,
    String? email,
  ) async {
    try {
      final permissionService = context.read<PermissionService>();
      final isAdminUser = (await permissionService.isAdmin(userId)) ||
          (email?.toLowerCase() == 'super@admin.com');

      // Admin routes: accept role-based admin or super email
      if (permission == 'admin' && isAdminUser) {
        return true;
      }

      final userPermissions =
          await permissionService.getUserPermissions(userId);

      // Treat 'admin' permission as superuser for all guards
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

/// Widget that conditionally shows content based on admin status
class AdminOnly extends StatelessWidget {
  const AdminOnly({
    super.key,
    required this.child,
    this.fallback,
    this.showError = false,
  });

  final Widget child;
  final Widget? fallback;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: 'admin',
      fallback: fallback,
      showError: showError,
      child: child,
    );
  }
}

/// Widget that conditionally shows content based on item management permission
class ItemManagementOnly extends StatelessWidget {
  const ItemManagementOnly({
    super.key,
    required this.child,
    this.fallback,
    this.showError = false,
  });

  final Widget child;
  final Widget? fallback;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: 'manage_items',
      fallback: fallback,
      showError: showError,
      child: child,
    );
  }
}

/// Widget that conditionally shows content based on department management permission
class DepartmentManagementOnly extends StatelessWidget {
  const DepartmentManagementOnly({
    super.key,
    required this.child,
    this.fallback,
    this.showError = false,
  });

  final Widget child;
  final Widget? fallback;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: 'manage_departments',
      fallback: fallback,
      showError: showError,
      child: child,
    );
  }
}

/// Widget that conditionally shows content based on staff management permission
class StaffManagementOnly extends StatelessWidget {
  const StaffManagementOnly({
    super.key,
    required this.child,
    this.fallback,
    this.showError = false,
  });

  final Widget child;
  final Widget? fallback;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: 'manage_staff',
      fallback: fallback,
      showError: showError,
      child: child,
    );
  }
}

/// Widget that conditionally shows content based on reports permission
class ReportsOnly extends StatelessWidget {
  const ReportsOnly({
    super.key,
    required this.child,
    this.fallback,
    this.showError = false,
  });

  final Widget child;
  final Widget? fallback;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: 'view_reports',
      fallback: fallback,
      showError: showError,
      child: child,
    );
  }
}
