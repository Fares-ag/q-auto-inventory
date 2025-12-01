import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

/// Service to handle admin authentication and role management
class AdminService {
  static const String _adminsCollection = 'admins';
  static const String _usersCollection = 'users';
  static const String _authLogsCollection = 'authLogs';

  /// Check if current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return false;

      // Check in admins collection
      final adminDoc = await FirebaseService.firestore
          .collection(_adminsCollection)
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data();
        return data?['isAdmin'] == true;
      }

      // Also check by email in admins collection
      final emailQuery = await FirebaseService.firestore
          .collection(_adminsCollection)
          .where('email', isEqualTo: user.email)
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return true;
      }

      // Check in users collection for role
      final userDoc = await FirebaseService.firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['role'] == 'admin' || data?['isAdmin'] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if an email is an admin email
  static Future<bool> isAdminEmail(String email) async {
    try {
      final query = await FirebaseService.firestore
          .collection(_adminsCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Add an admin user
  static Future<void> addAdmin({
    required String email,
    required String name,
  }) async {
    try {
      // First, find the user by email in auth
      // Note: This requires the user to exist in Firebase Auth first
      final query = await FirebaseService.firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      String userId;
      if (query.docs.isNotEmpty) {
        userId = query.docs.first.id;
      } else {
        // Create a new admin document
        userId = email.toLowerCase().replaceAll('@', '_').replaceAll('.', '_');
      }

      await FirebaseService.firestore
          .collection(_adminsCollection)
          .doc(userId)
          .set({
        'email': email.toLowerCase(),
        'name': name,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add admin: $e');
    }
  }

  /// Remove admin privileges
  static Future<void> removeAdmin(String email) async {
    try {
      final query = await FirebaseService.firestore
          .collection(_adminsCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }

  /// Get list of all admins
  static Stream<List<Map<String, dynamic>>> getAdminsStream() {
    return FirebaseService.firestore
        .collection(_adminsCollection)
        .where('isAdmin', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'name': data['name'] ?? '',
          'isAdmin': data['isAdmin'] ?? false,
        };
      }).toList();
    });
  }

  /// Stream of all users with roles and metadata
  static Stream<List<Map<String, dynamic>>> getUsersStream() {
    return FirebaseService.firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? '',
          'role': data['role'] ?? 'user',
          'isActive': data['isActive'] ?? true,
          'lastLoginAt': data['lastLoginAt'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }

  /// Update a user's role and optional permissions
  static Future<void> updateUserRole({
    required String userId,
    required String email,
    required String role,
    bool? isActive,
    Map<String, bool>? permissions,
  }) async {
    final batch = FirebaseService.firestore.batch();
    final userRef =
        FirebaseService.firestore.collection(_usersCollection).doc(userId);

    batch.update(userRef, {
      'role': role,
      if (isActive != null) 'isActive': isActive,
      if (permissions != null) 'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final adminsRef = FirebaseService.firestore.collection(_adminsCollection);

    // Maintain admins collection for quick admin checks
    if (role == 'admin' || role == 'super_admin') {
      final adminDoc = adminsRef.doc(userId);
      batch.set(adminDoc, {
        'email': email.toLowerCase(),
        'name': email.toLowerCase(),
        'isAdmin': true,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Demote: remove from admins collection
      final query = await adminsRef
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  /// Log authentication events (success / failure)
  static Future<void> logAuthEvent({
    required String event,
    required String email,
    String? userId,
    String? reason,
  }) async {
    try {
      await FirebaseService.firestore.collection(_authLogsCollection).add({
        'event': event,
        'email': email.toLowerCase(),
        'userId': userId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Logging is best-effort only
    }
  }

  /// Recent authentication logs for monitoring
  static Stream<List<Map<String, dynamic>>> getRecentAuthLogs({int limit = 50}) {
    return FirebaseService.firestore
        .collection(_authLogsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'event': data['event'] ?? '',
          'email': data['email'] ?? '',
          'userId': data['userId'],
          'reason': data['reason'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }
}

