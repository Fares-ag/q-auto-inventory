// Skeleton Firebase service layer rebuilt from Firestore collections.
// These implementations are placeholders—wire them up to the actual
// Firebase project, add error handling, and adjust queries to match
// your data model once you inspect the live documents.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/firestore_models.dart';

class FirebaseBootstrapper {
  FirebaseBootstrapper({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  Future<void> ensureSignedInAnonymously() async {
    final current = _auth.currentUser;
    if (current != null) return;
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      // Anonymous auth is disabled or restricted - continue without it
      // This allows the app to work if Firestore rules permit unauthenticated access
      // or if users will authenticate via email/password or other methods
      debugPrint('Anonymous sign-in failed (may be disabled): $e');
    }
  }

  Future<void> configureOfflinePersistence({bool enabled = true}) async {
    _firestore.settings = Settings(persistenceEnabled: enabled);
  }
}

class AssetCounterService {
  AssetCounterService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('assetCounter');

  Future<AssetCounter?> fetchCounter(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return AssetCounter.fromJson(doc.id, doc.data()!);
  }

  Future<void> saveCounter(AssetCounter counter) async {
    await _collection.doc(counter.id).set(counter.toJson());
  }

  Future<int> incrementCounter(String id) async {
    final ref = _collection.doc(id);
    return _firestore.runTransaction<int>((tx) async {
      final snapshot = await tx.get(ref);
      final current = snapshot.exists
          ? (snapshot.data()?['currentValue'] as num?)?.toInt() ?? 0
          : 0;
      final next = current + 1;
      tx.set(ref, {'currentValue': next}, SetOptions(merge: true));
      return next;
    });
  }
}

class CatalogService {
  CatalogService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');
  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('locations');

  Stream<List<Category>> watchCategories() {
    return _categories.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Category.fromJson(doc.id, doc.data()))
        .toList());
  }

  Future<List<Category>> listCategories({bool includeInactive = true}) async {
    Query<Map<String, dynamic>> query = _categories.orderBy('name');
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Category.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<Category> createCategory({
    required String name,
    String? description,
    String? parentId,
    bool isActive = true,
  }) async {
    final doc = _categories.doc();
    final category = Category(
      id: doc.id,
      name: name,
      description: description,
      parentId: parentId,
      sortOrder: null,
      isActive: isActive,
    );
    await doc.set(category.toJson());
    return category;
  }

  Future<void> updateCategory(Category category) async {
    await _categories
        .doc(category.id)
        .set(category.toJson(), SetOptions(merge: true));
  }

  Future<void> setCategoryStatus(String id, bool isActive) async {
    await _categories
        .doc(id)
        .set({'isActive': isActive}, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  Future<List<InventoryItem>> listItems(
      {int limit = 100,
      String? departmentId,
      String? categoryId,
      String? searchQuery}) async {
    Query<Map<String, dynamic>> query = _items;
    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    final snapshot = await query.limit(limit).get();
    var items = snapshot.docs
        .map((doc) => InventoryItem.fromJson(doc.id, doc.data()))
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      items = items
          .where((item) =>
              item.name.toLowerCase().contains(lowerQuery) ||
              item.assetId.toLowerCase().contains(lowerQuery) ||
              (item.description?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    }

    return items;
  }

  Stream<List<InventoryItem>> watchItems(
      {String? status, String? departmentId, String? categoryId}) {
    Query<Map<String, dynamic>> query = _items.orderBy('name');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryItem.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Server-side paginated listing ordered by name. Optional filters on department/category.
  /// Use [startAfterName] for cursor-based pagination (must be the 'name' of last item).
  Future<List<InventoryItem>> listItemsPage({
    required int limit,
    String? departmentId,
    String? categoryId,
    String? startAfterName,
  }) async {
    Query<Map<String, dynamic>> query = _items.orderBy('name');
    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (startAfterName != null && startAfterName.isNotEmpty) {
      query = query.startAfter([startAfterName]);
    }
    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => InventoryItem.fromJson(doc.id, doc.data()))
        .toList();
  }

  /// Fetch all items by iterating pages using name-based cursors.
  /// This avoids missing items when counts exceed a single query limit.
  Future<List<InventoryItem>> listAllItems({
    String? departmentId,
    String? categoryId,
    int pageSize = 500,
  }) async {
    final List<InventoryItem> all = <InventoryItem>[];
    String? cursor;
    while (true) {
      final page = await listItemsPage(
        limit: pageSize,
        departmentId: departmentId,
        categoryId: categoryId,
        startAfterName: cursor,
      );
      if (page.isEmpty) break;
      all.addAll(page);
      cursor = page.last.name;
      if (page.length < pageSize) break;
    }
    return all;
  }

  Future<InventoryItem?> getItem(String id) async {
    final doc = await _items.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return InventoryItem.fromJson(doc.id, data);
  }

  Future<String> createItem(InventoryItem item) async {
    final docRef = _items.doc();
    final newItem = InventoryItem(
      id: docRef.id,
      assetId: item.assetId,
      name: item.name,
      categoryId: item.categoryId,
      departmentId: item.departmentId,
      description: item.description,
      quantity: item.quantity,
      status: item.status ?? 'pending',
      locationId: item.locationId,
      assignedTo: item.assignedTo,
      purchaseDate: item.purchaseDate,
      warrantyExpiry: item.warrantyExpiry,
      lastServicedAt: item.lastServicedAt,
      tags: item.tags,
      thumbnailUrl: item.thumbnailUrl,
      qrCodeUrl: item.qrCodeUrl,
      customFields: item.customFields,
    );
    await docRef.set(newItem.toJson());
    return docRef.id;
  }

  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _items.doc(id).set(updates, SetOptions(merge: true));
  }

  Future<void> updateItemStatus(String id, String status) async {
    await _items.doc(id).set(
        {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  Future<void> upsertItem(InventoryItem item) async {
    await _items.doc(item.id).set(item.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  Future<String> generateNextAssetId() async {
    final counterService = AssetCounterService(_firestore);
    final counter = await counterService.fetchCounter('default');
    if (counter == null) {
      await counterService.saveCounter(const AssetCounter(
        id: 'default',
        prefix: 'ASSET',
        currentValue: 1,
      ));
      return 'ASSET-1';
    }
    final nextValue = counter.currentValue + 1;
    await counterService.saveCounter(AssetCounter(
      id: 'default',
      prefix: counter.prefix,
      currentValue: nextValue,
    ));
    return '${counter.prefix}-$nextValue';
  }

  Future<List<Location>> listLocations() async {
    final query = await _locations.get();
    return query.docs
        .map((doc) => Location.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<String> createLocation({
    required String name,
    String? address,
    String? notes,
    String? parentLocationId,
    bool isPrimary = false,
  }) async {
    final doc = _locations.doc();
    final location = Location(
      id: doc.id,
      name: name,
      address: address,
      notes: notes,
      parentLocationId: parentLocationId,
      isPrimary: isPrimary,
    );
    await doc.set(location.toJson());
    return doc.id;
  }

  Future<void> updateLocation(Location location) async {
    await _locations
        .doc(location.id)
        .set(location.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteLocation(String id) async {
    await _locations.doc(id).delete();
  }
}

class DepartmentService {
  DepartmentService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _departments =>
      _firestore.collection('departments');
  CollectionReference<Map<String, dynamic>> get _subDepartments =>
      _firestore.collection('subDepartments');

  Stream<List<Department>> watchDepartments() {
    return _departments.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Department.fromJson(doc.id, doc.data()))
        .toList());
  }

  Future<List<Department>> listDepartments(
      {bool includeInactive = true}) async {
    if (!includeInactive) {
      // Avoid combining where + orderBy to prevent requiring a composite index
      final snapshot =
          await _departments.where('isActive', isEqualTo: true).get();
      final list = snapshot.docs
          .map((doc) => Department.fromJson(doc.id, doc.data()))
          .toList();
      // Client-side sort by name to preserve UI ordering
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    } else {
      final snapshot = await _departments.orderBy('name').get();
      return snapshot.docs
          .map((doc) => Department.fromJson(doc.id, doc.data()))
          .toList();
    }
  }

  Future<String> addDepartment(String name, {String? description}) async {
    final normalized = name.trim();
    final doc = await _departments.add({
      'name': normalized,
      'nameLower': normalized.toLowerCase(),
      'description': description,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateDepartment(
    String id, {
    String? name,
    String? description,
    String? managerId,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) {
      updates['name'] = name;
      updates['nameLower'] = name.trim().toLowerCase();
    }
    if (description != null) updates['description'] = description;
    if (managerId != null) updates['managerId'] = managerId;
    await _departments.doc(id).set(updates, SetOptions(merge: true));
  }

  Future<void> setDepartmentStatus(String id, bool isActive) async {
    await _departments.doc(id).set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDepartment(String id) async {
    await _departments.doc(id).delete();
  }

  Future<List<SubDepartment>> listSubDepartments(String departmentId) async {
    final List<SubDepartment> results = <SubDepartment>[];
    // Primary collection (camelCase)
    final q1 = await _subDepartments
        .where('departmentId', isEqualTo: departmentId)
        .get();
    results.addAll(q1.docs.map((d) => SubDepartment.fromJson(d.id, d.data())));
    // Alternate collection (snake_case)
    try {
      final q2 = await _firestore
          .collection('sub_departments')
          .where('departmentId', isEqualTo: departmentId)
          .get();
      results
          .addAll(q2.docs.map((d) => SubDepartment.fromJson(d.id, d.data())));
    } catch (_) {}
    // Deduplicate by id
    final Map<String, SubDepartment> byId = {
      for (final sd in results) sd.id: sd,
    };
    return byId.values.toList();
  }
}

class CommentService {
  CommentService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _comments =>
      _firestore.collection('comments');

  Stream<List<Comment>> watchComments(String entityId) {
    return _comments
        .where('entityId', isEqualTo: entityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> addComment(Comment comment) async {
    await _comments.add(comment.toJson());
  }

  Future<void> deleteComment(String commentId) async {
    await _comments.doc(commentId).delete();
  }

  Future<List<Comment>> listComments(String entityId) async {
    final snapshot = await _comments
        .where('entityId', isEqualTo: entityId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Comment.fromJson(doc.id, doc.data()))
        .toList();
  }
}

class IssueService {
  IssueService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _issues =>
      _firestore.collection('issues');
  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection('history');

  Future<List<Issue>> listOpenIssues({int limit = 100}) async {
    final query = await _issues
        .where('status', isNotEqualTo: 'closed')
        .orderBy('status')
        .limit(limit)
        .get();
    return query.docs.map((doc) => Issue.fromJson(doc.id, doc.data())).toList();
  }

  Future<String> createIssue(Issue issue) async {
    final docRef = _issues.doc();
    final newIssue = Issue(
      id: docRef.id,
      itemId: issue.itemId,
      title: issue.title,
      status: issue.status,
      description: issue.description,
      priority: issue.priority,
      reportedBy: issue.reportedBy,
      assignedTo: issue.assignedTo,
      createdAt: DateTime.now(),
    );
    await docRef.set(newIssue.toJson());
    return docRef.id;
  }

  Future<void> saveIssue(Issue issue) async {
    await _issues.doc(issue.id).set(issue.toJson(), SetOptions(merge: true));
  }

  Future<void> resolveIssue(String id) async {
    await _issues.doc(id).set({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Issue>> getItemIssues(String itemId) async {
    final snapshot = await _issues
        .where('itemId', isEqualTo: itemId)
        .where('status', isNotEqualTo: 'closed')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Issue.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> addHistory(HistoryEntry entry) async {
    await _history.add(entry.toJson());
  }
}

class HistoryService {
  HistoryService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection('history');

  Future<List<HistoryEntry>> recentHistory({int limit = 10}) async {
    final snapshot = await _history
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => HistoryEntry.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<List<HistoryEntry>> getItemHistory(String itemId,
      {int limit = 50}) async {
    final snapshot = await _history
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => HistoryEntry.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> recordCheckIn(String itemId, String userId,
      {String? notes}) async {
    await _history.add(HistoryEntry(
      id: '',
      itemId: itemId,
      action: 'check_in',
      actorId: userId,
      notes: notes,
      timestamp: DateTime.now(),
    ).toJson());
  }

  Future<void> recordCheckOut(String itemId, String userId,
      {String? notes}) async {
    await _history.add(HistoryEntry(
      id: '',
      itemId: itemId,
      action: 'check_out',
      actorId: userId,
      notes: notes,
      timestamp: DateTime.now(),
    ).toJson());
  }
}

class StaffService {
  StaffService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _staff =>
      _firestore.collection('staff');
  CollectionReference<Map<String, dynamic>> get _permissionSets =>
      _firestore.collection('permissionSets');

  Future<List<StaffMember>> listStaff({bool activeOnly = true}) async {
    Query<Map<String, dynamic>> query = _staff.orderBy('displayName');
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => StaffMember.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateStaffRole(String staffId, String? roleId) async {
    await _staff.doc(staffId).set({
      'permissionSetId': roleId,
      'role': roleId,
    }, SetOptions(merge: true));
  }

  Future<void> setStaffActive(String staffId, bool isActive) async {
    await _staff
        .doc(staffId)
        .set({'isActive': isActive}, SetOptions(merge: true));
  }

  Future<void> deleteStaff(String staffId) async {
    await _staff.doc(staffId).delete();
  }

  Future<String> addStaffMember({
    required String displayName,
    required String email,
    String? departmentId,
    String? role,
  }) async {
    final doc = _staff.doc();
    await doc.set({
      'displayName': displayName,
      'email': email,
      'departmentId': departmentId,
      'role': role,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateStaffMember(
    String staffId, {
    String? displayName,
    String? email,
    String? departmentId,
    String? role,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (email != null) updates['email'] = email;
    if (departmentId != null) updates['departmentId'] = departmentId;
    if (role != null) updates['role'] = role;
    await _staff.doc(staffId).set(updates, SetOptions(merge: true));
  }

  Future<List<PermissionSet>> listPermissionSets() async {
    final snapshot = await _permissionSets.get();
    return snapshot.docs
        .map((doc) => PermissionSet.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> updatePermissionSet(String id, List<String> permissions) async {
    await _permissionSets
        .doc(id)
        .set({'permissions': permissions}, SetOptions(merge: true));
  }
}

class SystemSettingsService {
  SystemSettingsService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _systemDoc =>
      _firestore.collection('system').doc('config');

  Future<SystemSettings?> fetchSettings() async {
    final snapshot = await _systemDoc.get();
    if (!snapshot.exists) return null;
    return SystemSettings.fromJson(snapshot.id, snapshot.data()!);
  }

  Future<void> updateSettings(SystemSettings settings) async {
    await _systemDoc.set(settings.toJson(), SetOptions(merge: true));
  }
}

class UserService {
  UserService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<AppUser>> listUsers() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((doc) => AppUser.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> disableUser(String uid, {required bool disabled}) async {
    await _users
        .doc(uid)
        .set({'isDisabled': disabled}, SetOptions(merge: true));
  }

  Future<String> createUser({
    required String email,
    required String displayName,
    String? departmentId,
    String? role,
  }) async {
    final doc = _users.doc();
    await doc.set({
      'email': email,
      'displayName': displayName,
      'departmentId': departmentId,
      'role': role,
      'isDisabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateUser(
    String userId, {
    String? email,
    String? displayName,
    String? departmentId,
    String? role,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (email != null) updates['email'] = email;
    if (displayName != null) updates['displayName'] = displayName;
    if (departmentId != null) updates['departmentId'] = departmentId;
    if (role != null) updates['role'] = role;
    await _users.doc(userId).set(updates, SetOptions(merge: true));
  }
}

class VehicleService {
  VehicleService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _checkInOut =>
      _firestore.collection('vehicle_checkinout');
  CollectionReference<Map<String, dynamic>> get _maintenance =>
      _firestore.collection('vehicle_maintenance');

  Stream<List<VehicleCheckInOut>> watchActiveCheckouts() {
    return _checkInOut.where('completed', isEqualTo: false).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => VehicleCheckInOut.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> logCheckInOut(VehicleCheckInOut record) async {
    await _checkInOut.add(record.toJson());
  }

  Future<List<VehicleMaintenance>> listMaintenance(String vehicleId) async {
    final snapshot = await _maintenance
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('scheduledDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => VehicleMaintenance.fromJson(doc.id, doc.data()))
        .toList();
  }
}
