import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  PermissionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _staff =>
      _firestore.collection('staff');

  /// Avoid repeating the same Firestore reads right after login (AuthWrapper +
  /// Dashboard both query role/permissions).
  static const Duration _sessionCacheTtl = Duration(minutes: 15);
  String? _roleCacheUid;
  String? _roleCacheValue;
  DateTime? _roleCacheAt;
  String? _permCacheUid;
  List<String>? _permCacheValue;
  DateTime? _permCacheAt;

  bool _roleCacheHit(String userId) {
    return _roleCacheUid == userId &&
        _roleCacheAt != null &&
        DateTime.now().difference(_roleCacheAt!) < _sessionCacheTtl;
  }

  bool _permCacheHit(String userId) {
    return _permCacheUid == userId &&
        _permCacheValue != null &&
        _permCacheAt != null &&
        DateTime.now().difference(_permCacheAt!) < _sessionCacheTtl;
  }

  /// Clears in-memory role/permission cache. Call on sign-out.
  void clearSessionCache() {
    _roleCacheUid = null;
    _roleCacheValue = null;
    _roleCacheAt = null;
    _permCacheUid = null;
    _permCacheValue = null;
    _permCacheAt = null;
  }

  Future<String?> getUserRole(String userId) async {
    if (_roleCacheHit(userId)) {
      return _roleCacheValue;
    }
    final resolved = await _fetchUserRoleUncached(userId);
    _roleCacheUid = userId;
    _roleCacheValue = resolved;
    _roleCacheAt = DateTime.now();
    return resolved;
  }

  Future<String?> _fetchUserRoleUncached(String userId) async {
    try {
      String? roleId;
      
      // First, get the roleId from users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        // Check both 'roleId' and 'role' fields (Firestore uses 'roleId', but we also support 'role')
        roleId = data['roleId'] as String? ?? data['role'] as String?;
      }
      
      // If not found in users, check staff collection
      if (roleId == null) {
        final staffDoc = await _firestore.collection('staff').doc(userId).get();
        if (staffDoc.exists) {
          final data = staffDoc.data() ?? {};
          roleId = data['role'] as String? ?? data['permissionSetId'] as String?;
        }
      }
      
      if (roleId == null || roleId.isEmpty) {
        return null;
      }
      
      // Check if roleId is actually a permission set ID (look it up in permissionSets)
      try {
        final permSetDoc = await _firestore.collection('permissionSets').doc(roleId).get();
        if (permSetDoc.exists) {
          // It's a permission set ID, return the name
          final name = permSetDoc.data()?['name'] as String?;
          if (name != null && name.isNotEmpty) {
            return name;
          }
        }
        
        // Try to find by name (case-insensitive)
        final byName = await _firestore
            .collection('permissionSets')
            .where('name', isEqualTo: roleId)
            .limit(1)
            .get();
        if (byName.docs.isNotEmpty) {
          return byName.docs.first.data()['name'] as String? ?? roleId;
        }
      } catch (_) {
        // If lookup fails, return the original roleId
      }
      
      // Return the roleId as-is (might be a role name like "Finance" or an ID)
      return roleId;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  Future<List<String>> _getPermissionsFromPermissionSetId(String? idOrName) async {
    if (idOrName == null || idOrName.isEmpty) return [];
    try {
      final byId = await _firestore.collection('permissionSets').doc(idOrName).get();
      if (byId.exists) {
        final perms = byId.data()?['permissions'];
        if (perms is List) {
          return perms.cast<String>();
        }
      }
      final byName = await _firestore
          .collection('permissionSets')
          .where('name', isEqualTo: idOrName)
          .limit(1)
          .get();
      if (byName.docs.isNotEmpty) {
        final perms = byName.docs.first.data()['permissions'];
        if (perms is List) {
          return perms.cast<String>();
        }
      }
    } catch (e) {
      debugPrint('Error loading permission set: $e');
    }
    return [];
  }

  /// Ensures users with the Operator role can add/edit items even if an old
  /// Firestore permission set omitted [manage_items].
  List<String> _ensureOperatorManageItems(String? resolvedRole, List<String> perms) {
    if (perms.isEmpty) return perms;
    final r = resolvedRole?.toLowerCase() ?? '';
    if (!r.contains('operator')) return perms;
    if (perms.contains('manage_items') ||
        perms.contains('admin') ||
        perms.contains('*')) {
      return List<String>.from(perms);
    }
    return [...perms, 'manage_items'];
  }

  Future<List<String>> getUserPermissions(String userId) async {
    if (_permCacheHit(userId)) {
      return List<String>.from(_permCacheValue!);
    }
    final resolved = await _fetchUserPermissionsUncached(userId);
    _permCacheUid = userId;
    _permCacheValue = resolved;
    _permCacheAt = DateTime.now();
    return resolved;
  }

  Future<List<String>> _fetchUserPermissionsUncached(String userId) async {
    try {
      String? role;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final udata = userDoc.data() ?? {};
        final explicit = (udata['permissions'] as List?)?.cast<String>();
        if (explicit != null && explicit.isNotEmpty) return explicit;
        // Check both 'roleId' and 'role' fields (Firestore uses 'roleId')
        role = udata['roleId'] as String? ?? udata['role'] as String?;
        final fromRole = await _getPermissionsFromPermissionSetId(role);
        if (fromRole.isNotEmpty) {
          return _ensureOperatorManageItems(await getUserRole(userId), fromRole);
        }
      }

      final staffDoc = await _staff.doc(userId).get();
      if (staffDoc.exists) {
        final sdata = staffDoc.data() ?? {};
        final explicit = (sdata['permissions'] as List?)?.cast<String>();
        if (explicit != null && explicit.isNotEmpty) return explicit;
        final permissionSetId = sdata['permissionSetId'] as String?;
        role ??= sdata['role'] as String?;
        final fromSet = await _getPermissionsFromPermissionSetId(permissionSetId);
        if (fromSet.isNotEmpty) {
          return _ensureOperatorManageItems(await getUserRole(userId), fromSet);
        }
        final fromRole = await _getPermissionsFromPermissionSetId(role);
        if (fromRole.isNotEmpty) {
          return _ensureOperatorManageItems(await getUserRole(userId), fromRole);
        }
      }

      role ??= await getUserRole(userId);
      if (role != null && role.isNotEmpty) {
        final fromRole = await _getPermissionsFromPermissionSetId(role);
        if (fromRole.isNotEmpty) {
          return _ensureOperatorManageItems(await getUserRole(userId), fromRole);
        }
        if (role.toLowerCase().contains('admin')) {
          return const [
            'admin',
            'manage_items',
            'manage_departments',
            'manage_staff',
            'view_reports',
            '*',
          ];
        }
        if (role.toLowerCase().contains('finance')) {
          return const [
            'finance',
            'edit_financial_fields',
            'edit_asset_number',
            'view_items',
            'view_reports', // Finance users can view reports
          ];
        }
        if (role.toLowerCase().contains('operator')) {
          return const [
            'view_items',
            'manage_items',
          ];
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error getting user permissions: $e');
      return [];
    }
  }

  bool hasPermission(List<String> permissions, String permission) {
    return permissions.contains(permission) || permissions.contains('*');
  }

  // Quick check methods
  Future<bool> canManageItems(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'manage_items') ||
        hasPermission(permissions, 'admin');
  }

  Future<bool> canManageDepartments(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'manage_departments') ||
        hasPermission(permissions, 'admin');
  }

  Future<bool> canManageStaff(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'manage_staff') ||
        hasPermission(permissions, 'admin');
  }

  Future<bool> canViewReports(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'view_reports') ||
        hasPermission(permissions, 'admin');
  }

  Future<bool> canViewItems(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'view_items') ||
        hasPermission(permissions, 'manage_items') ||
        hasPermission(permissions, 'admin');
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final uRole = userDoc.data()?['role'] as String?;
      if (uRole != null && uRole.toLowerCase().contains('admin')) return true;
    } catch (_) {}
    try {
      final staffDoc = await _firestore.collection('staff').doc(userId).get();
      final sRole = staffDoc.data()?['role'] as String?;
      if (sRole != null && sRole.toLowerCase().contains('admin')) return true;
    } catch (_) {}
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'admin');
  }

  Future<bool> isFinance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final udata = userDoc.data() ?? {};
      // Check both 'roleId' and 'role' fields
      final uRole = udata['roleId'] as String? ?? udata['role'] as String?;
      if (uRole != null && uRole.toLowerCase().contains('finance')) return true;
    } catch (_) {}
    try {
      final staffDoc = await _firestore.collection('staff').doc(userId).get();
      final sRole = staffDoc.data()?['role'] as String?;
      if (sRole != null && sRole.toLowerCase().contains('finance')) return true;
    } catch (_) {}
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'finance');
  }

  Future<bool> canEditFinancialFields(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'edit_financial_fields') ||
        hasPermission(permissions, 'finance') ||
        hasPermission(permissions, 'admin');
  }

  Future<bool> canEditAssetNumber(String userId) async {
    final permissions = await getUserPermissions(userId);
    return hasPermission(permissions, 'edit_asset_number') ||
        hasPermission(permissions, 'finance') ||
        hasPermission(permissions, 'admin');
  }
}

