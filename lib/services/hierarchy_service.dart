import 'package:cloud_firestore/cloud_firestore.dart';

/// Provides helper methods for maintaining the organisation hierarchy
/// (departments, sub-departments and locations).
class HierarchyService {
  HierarchyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _departmentsCollection =>
      _firestore.collection('departments');
  CollectionReference<Map<String, dynamic>> get _subDepartmentsCollection =>
      _firestore.collection('sub_departments');
  CollectionReference<Map<String, dynamic>> get _locationsCollection =>
      _firestore.collection('locations');

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final snapshot = await _departmentsCollection.get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<String> addDepartment(String name, String description) async {
    final normalized = name.trim().toLowerCase();
    final existing = await _departmentsCollection
        .where('nameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Department name already exists');
    }
    final doc = await _departmentsCollection.add({
      'name': name,
      'nameLower': normalized,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateDepartment(String id, String name, String description) {
    return _departmentsCollection.doc(id).update({
      'name': name,
      'nameLower': name.trim().toLowerCase(),
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDepartment(String id) async {
    final subDepartments = await _subDepartmentsCollection
        .where('departmentId', isEqualTo: id)
        .get();
    for (final doc in subDepartments.docs) {
      await doc.reference.delete();
    }
    await _departmentsCollection.doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getSubDepartments(String departmentId) async {
    final snapshot = await _subDepartmentsCollection
        .where('departmentId', isEqualTo: departmentId)
        .get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<String> addSubDepartment(
    String departmentId,
    String name,
    String description,
  ) async {
    final normalized = name.trim().toLowerCase();
    final existing = await _subDepartmentsCollection
        .where('departmentId', isEqualTo: departmentId)
        .where('nameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Sub-department name already exists in this department');
    }
    final doc = await _subDepartmentsCollection.add({
      'departmentId': departmentId,
      'name': name,
      'nameLower': normalized,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateSubDepartment(
    String id,
    String name,
    String description,
  ) {
    return _subDepartmentsCollection.doc(id).update({
      'name': name,
      'nameLower': name.trim().toLowerCase(),
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubDepartment(String id) async {
    await _subDepartmentsCollection.doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final snapshot = await _locationsCollection.get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<String> addLocation(
    String name,
    String description,
    List<String> subDepartmentIds, {
    String? departmentId,
  }) async {
    final normalized = name.trim().toLowerCase();
    final existing = await _locationsCollection
        .where('nameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Location name already exists');
    }
    final doc = await _locationsCollection.add({
      'name': name,
      'nameLower': normalized,
      'description': description,
      'subDepartmentIds': subDepartmentIds,
      'departmentId': departmentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateLocation(
    String id,
    String name,
    String description,
    List<String> subDepartmentIds, {
    String? departmentId,
  }) {
    return _locationsCollection.doc(id).update({
      'name': name,
      'nameLower': name.trim().toLowerCase(),
      'description': description,
      'subDepartmentIds': subDepartmentIds,
      'departmentId': departmentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLocation(String id) async {
    await _locationsCollection.doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getLocationsForSubDepartment(
    String subDepartmentId,
  ) async {
    final snapshot = await _locationsCollection
        .where('subDepartmentIds', arrayContains: subDepartmentId)
        .get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }
}
