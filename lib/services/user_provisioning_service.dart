import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class UserProvisioningResult {
  const UserProvisioningResult({
    required this.uid,
    this.temporaryPassword,
  });

  final String uid;
  final String? temporaryPassword;

  factory UserProvisioningResult.fromMap(Map<String, dynamic> data) {
    return UserProvisioningResult(
      uid: data['uid'] as String,
      temporaryPassword: data['temporaryPassword'] as String?,
    );
  }
}

class UserProvisioningException implements Exception {
  const UserProvisioningException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'UserProvisioningException: $message';
}

class UserProvisioningService {
  UserProvisioningService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<UserProvisioningResult> createAppUser({
    required String email,
    required String displayName,
    String? departmentId,
    String? roleId,
    String? password,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'createAppUser',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final response = await callable.call<Map<String, dynamic>>({
        'email': email.trim(),
        'displayName': displayName.trim(),
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
        if (roleId != null && roleId.isNotEmpty) 'roleId': roleId,
        if (password != null && password.isNotEmpty) 'password': password,
      });
      final data = Map<String, dynamic>.from(response.data);
      return UserProvisioningResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('createAppUser failed: ${e.code} ${e.message}');
      throw UserProvisioningException(
        e.message ?? 'Failed to create user account',
        code: e.code,
      );
    }
  }

  Future<void> provisionUserProfile({
    required String authUid,
    required String email,
    required String displayName,
    String? departmentId,
    String? roleId,
    List<String>? permissions,
  }) async {
    await _firestore.collection('users').doc(authUid).set({
      'email': email.trim(),
      'name': displayName.trim(),
      'displayName': displayName.trim(),
      if (departmentId != null) ...{
        'department': departmentId,
        'departmentId': departmentId,
      },
      if (roleId != null) ...{
        'roleId': roleId,
        'role': roleId,
      },
      if (permissions != null && permissions.isNotEmpty)
        'permissions': permissions,
      'isActive': true,
      'isDisabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
