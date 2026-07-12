import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/permission_providers.dart';
import '../providers/service_providers.dart';

/// Inline permission guard — shows [child] only if the current user has
/// [permission]. Uses cached Riverpod [currentUserDataProvider] so repeated
/// guards on the same screen share a single Firestore fetch.
class PermissionGuard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

    return userData.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
      data: (user) {
        if (user == null) return fallback ?? const SizedBox.shrink();

        final permSvc = ref.read(permissionServiceProvider);
        final isAdmin = permSvc.hasPermission(user.permissions, 'admin');

        final hasAccess = isAdmin ||
            permSvc.hasPermission(user.permissions, permission);

        if (hasAccess) return child;

        if (showError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have permission to access this feature.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
}

// ── Convenience wrappers ──────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => PermissionGuard(
        permission: 'admin',
        fallback: fallback,
        showError: showError,
        child: child,
      );
}

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
  Widget build(BuildContext context) => PermissionGuard(
        permission: 'manage_items',
        fallback: fallback,
        showError: showError,
        child: child,
      );
}

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
  Widget build(BuildContext context) => PermissionGuard(
        permission: 'manage_departments',
        fallback: fallback,
        showError: showError,
        child: child,
      );
}

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
  Widget build(BuildContext context) => PermissionGuard(
        permission: 'manage_staff',
        fallback: fallback,
        showError: showError,
        child: child,
      );
}

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
  Widget build(BuildContext context) => PermissionGuard(
        permission: 'view_reports',
        fallback: fallback,
        showError: showError,
        child: child,
      );
}
