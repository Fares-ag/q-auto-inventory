import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/permission_providers.dart';
import '../providers/service_providers.dart';
import '../utils/app_spacing.dart';

/// Route-level permission guard. Uses Riverpod's cached [userHasPermissionProvider]
/// so the check fires once per user session, not on every rebuild.
class PermissionGuardWrapper extends ConsumerWidget {
  const PermissionGuardWrapper({
    super.key,
    required this.permission,
    required this.child,
  });

  final String permission;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

    return userData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load permissions')),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Text('Please sign in to access this page'),
            ),
          );
        }

        final permSvc = ref.read(permissionServiceProvider);
        final isAdmin = permSvc.hasPermission(user.permissions, 'admin');

        final hasAccess = isAdmin ||
            permSvc.hasPermission(user.permissions, permission);

        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Padding(
                padding: AppSpacing.pagePadding * 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    AppSpacing.gapXl2,
                    Text(
                      'Access Denied',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'You do not have permission to access this page.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapXl2,
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Go Back'),
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
}
