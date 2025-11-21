import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  PermissionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _staff =>
      _firestore.collection('staff');

  Future<String?> getUserRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['role'] as String?;
      }
      final staffDoc = await _firestore.collection('staff').doc(userId).get();
      if (staffDoc.exists) {
        return staffDoc.data()?['role'] as String?;
      }
      return null;
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

  Future<List<String>> getUserPermissions(String userId) async {
    try {
      String? role;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final udata = userDoc.data() ?? {};
        final explicit = (udata['permissions'] as List?)?.cast<String>();
        if (explicit != null && explicit.isNotEmpty) return explicit;
        role = udata['role'] as String?;
        final fromRole = await _getPermissionsFromPermissionSetId(role);
        if (fromRole.isNotEmpty) return fromRole;
      }

      final staffDoc = await _staff.doc(userId).get();
      if (staffDoc.exists) {
        final sdata = staffDoc.data() ?? {};
        final explicit = (sdata['permissions'] as List?)?.cast<String>();
        if (explicit != null && explicit.isNotEmpty) return explicit;
        final permissionSetId = sdata['permissionSetId'] as String?;
        role ??= sdata['role'] as String?;
        final fromSet = await _getPermissionsFromPermissionSetId(permissionSetId);
        if (fromSet.isNotEmpty) return fromSet;
        final fromRole = await _getPermissionsFromPermissionSetId(role);
        if (fromRole.isNotEmpty) return fromRole;
      }

      role ??= await getUserRole(userId);
      if (role != null && role.isNotEmpty) {
        final fromRole = await _getPermissionsFromPermissionSetId(role);
        if (fromRole.isNotEmpty) return fromRole;
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
}

