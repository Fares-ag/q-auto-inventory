// Permission providers — replaces FutureBuilder(future: _checkPermission(...))
// anti-pattern. Riverpod caches results for the session.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

// ── Current user permissions ──────────────────────────────────────────────────

/// All permission strings for the current user.
/// Auto-disposed when nothing watches it; re-fetched on next access.
final currentUserPermissionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return [];
  final perm = ref.watch(permissionServiceProvider);
  return perm.getUserPermissions(user.uid);
});

/// Cached check: does the current user have [permission]?
final hasPermissionProvider = FutureProvider.autoDispose.family<bool, String>((ref, permission) async {
  final permissions = await ref.watch(currentUserPermissionsProvider.future);
  final perm = ref.watch(permissionServiceProvider);
  return perm.hasPermission(permissions, permission);
});

/// Is the current user an admin?
final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return false;
  return ref.watch(permissionServiceProvider).isAdmin(user.uid);
});

/// Is the current user a finance user?
final isFinanceProvider = FutureProvider.autoDispose<bool>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return false;
  return ref.watch(permissionServiceProvider).isFinance(user.uid);
});

// ── Per-user permission checks (for guards) ──────────────────────────────────

/// Check a specific named permission for a specific user uid.
/// Used by PermissionGuardWrapper.
final userHasPermissionProvider =
    FutureProvider.autoDispose.family<bool, _UidPermission>((ref, args) async {
  final perm = ref.watch(permissionServiceProvider);
  final permissions = await perm.getUserPermissions(args.uid);
  return perm.hasPermission(permissions, args.permission);
});

/// Bundle of item-level permission flags — replaces 3 separate FutureBuilders
/// in item_detail_screen.dart.
class ItemPermissions {
  const ItemPermissions({
    required this.canEdit,
    required this.canDelete,
    required this.canEditFinancial,
  });
  final bool canEdit;
  final bool canDelete;
  final bool canEditFinancial;
}

final itemPermissionsProvider =
    FutureProvider.autoDispose.family<ItemPermissions, String>((ref, itemId) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return const ItemPermissions(canEdit: false, canDelete: false, canEditFinancial: false);
  }
  final perm = ref.watch(permissionServiceProvider);
  // Fetch permissions once and derive all three flags.
  final permissions = await perm.getUserPermissions(user.uid);
  final canEdit = perm.hasPermission(permissions, 'manage_items') ||
      perm.hasPermission(permissions, 'admin');
  final canDelete = perm.hasPermission(permissions, 'admin');
  final canEditFinancial = perm.hasPermission(permissions, 'edit_financial_fields') ||
      perm.hasPermission(permissions, 'finance') ||
      perm.hasPermission(permissions, 'admin');
  return ItemPermissions(
    canEdit: canEdit,
    canDelete: canDelete,
    canEditFinancial: canEditFinancial,
  );
});

// ── Helper value object ───────────────────────────────────────────────────────

class _UidPermission {
  const _UidPermission(this.uid, this.permission);
  final String uid;
  final String permission;

  @override
  bool operator ==(Object other) =>
      other is _UidPermission && other.uid == uid && other.permission == permission;

  @override
  int get hashCode => Object.hash(uid, permission);
}

// Helper kept for future use if callers need to build family keys manually.
// ignore: unused_element
_UidPermission _makeUidPermission(String uid, String permission) =>
    _UidPermission(uid, permission);

// ── Auth-aware permission guard data ─────────────────────────────────────────

/// Full user data for the current user: uid + permissions + role.
class CurrentUserData {
  const CurrentUserData({
    required this.uid,
    required this.permissions,
    this.role,
  });
  final String uid;
  final List<String> permissions;
  final String? role;
}

final currentUserDataProvider = FutureProvider.autoDispose<CurrentUserData?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final perm = ref.watch(permissionServiceProvider);
  final permissions = await perm.getUserPermissions(user.uid);
  final role = await perm.getUserRole(user.uid);
  return CurrentUserData(uid: user.uid, permissions: permissions, role: role);
});
