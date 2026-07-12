// Firebase-backed service layer for Q Auto Inventory Firestore collections.
// Tune queries, indexes, and security rules to match your production project.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/firestore_models.dart';
import '../utils/asset_id_suggestion.dart';
import 'cache_service.dart';
import 'offline_queue_service.dart';
import 'user_provisioning_service.dart';

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

  void configureOfflinePersistence({bool enabled = true}) {
    // Non-blocking - just set settings
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

  /// Atomically increments the counter and returns the reserved asset id string.
  Future<String> reserveNextAssetId({String counterDocId = 'default'}) async {
    final ref = _collection.doc(counterDocId);
    return _firestore.runTransaction<String>((tx) async {
      final snapshot = await tx.get(ref);
      var prefix = 'ASSET';
      var nextValue = 1;
      if (snapshot.exists) {
        final data = snapshot.data() ?? {};
        prefix = (data['prefix'] as String?)?.trim().isNotEmpty == true
            ? (data['prefix'] as String).trim()
            : 'ASSET';
        final current = (data['currentValue'] as num?)?.toInt() ?? 0;
        nextValue = current + 1;
      }
      tx.set(
        ref,
        {'prefix': prefix, 'currentValue': nextValue},
        SetOptions(merge: true),
      );
      return '$prefix-$nextValue';
    });
  }

  /// Raises the counter floor after a manual/imported asset id is saved.
  Future<void> advanceCounterFloor(
    String savedAssetId, {
    String counterDocId = 'default',
  }) async {
    final parsed = tryParseAssetId(savedAssetId.trim());
    if (parsed == null) return;

    final ref = _collection.doc(counterDocId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        tx.set(ref, {
          'prefix': parsed.prefix,
          'currentValue': parsed.numericValue,
        });
        return;
      }
      final data = snapshot.data() ?? {};
      final prefix = (data['prefix'] as String?)?.trim().isNotEmpty == true
          ? (data['prefix'] as String).trim()
          : 'ASSET';
      if (!prefixesMatch(parsed.prefix, prefix)) return;

      final current = (data['currentValue'] as num?)?.toInt() ?? 0;
      final newVal =
          parsed.numericValue > current ? parsed.numericValue : current;
      if (newVal != current) {
        tx.set(ref, {'currentValue': newVal}, SetOptions(merge: true));
      }
    });
  }
}

class CatalogService {
  CatalogService(this._firestore, {OfflineQueueService? offlineQueue})
      : _offlineQueue = offlineQueue;

  final FirebaseFirestore _firestore;
  final _cache = CacheService.instance;
  final OfflineQueueService? _offlineQueue;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');
  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('locations');
  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection('history');

  Future<void> _executeWrite(Future<void> Function() job) async {
    if (_offlineQueue != null) {
      await _offlineQueue.enqueue(job);
      return;
    }
    await job();
  }

  Future<void> _logItemHistory(
    String itemId,
    String action, {
    Map<String, dynamic>? metadata,
    String? notes,
  }) async {
    try {
      final actorId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      await _history.add({
        'itemId': itemId,
        'action': action,
        'actorId': actorId,
        if (metadata != null) 'metadata': metadata,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        // Client clock so rows always have a resolved [timestamp] for
        // orderBy + local cache; serverTimestamp stays unset until sync and
        // can break recent-activity queries on offline/pending writes.
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('History log failed: $e');
    }
  }

  static String _historyNoteForFields(List<String> fieldKeys) {
    if (fieldKeys.isEmpty) return 'Item updated';
    final readable = fieldKeys
        .map(
          (k) => k.replaceAllMapped(
            RegExp(r'([a-z])([A-Z])'),
            (m) => '${m[1]} ${m[2]}',
          ),
        )
        .map((k) => k.replaceAll('_', ' '))
        .join(', ');
    return 'Updated: $readable';
  }

  Stream<List<Category>> watchCategories() {
    return _categories.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Category.fromJson(doc.id, doc.data()))
        .toList());
  }

  Future<List<Category>> listCategories({bool includeInactive = true}) async {
    final cacheKey =
        '${CacheKeys.categories}_${includeInactive ? 'all' : 'active'}';
    final cached = _cache.get<List<Category>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    Query<Map<String, dynamic>> query = _categories.orderBy('name');
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    final categories = snapshot.docs
        .map((doc) => Category.fromJson(doc.id, doc.data()))
        .toList();
    _cache.setAndPersist<Category>(
      cacheKey,
      categories,
      (c) => c.toJson(),
      (c) => c.id,
      ttl: const Duration(minutes: 30),
    );
    return categories;
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
    _invalidateCategoryCache();
    return category;
  }

  Future<void> updateCategory(Category category) async {
    await _categories
        .doc(category.id)
        .set(category.toJson(), SetOptions(merge: true));
    _invalidateCategoryCache();
  }

  Future<void> setCategoryStatus(String id, bool isActive) async {
    await _categories
        .doc(id)
        .set({'isActive': isActive}, SetOptions(merge: true));
    _invalidateCategoryCache();
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
    _invalidateCategoryCache();
  }

  void _invalidateCategoryCache() {
    _cache.remove('${CacheKeys.categories}_all');
    _cache.remove('${CacheKeys.categories}_active');
  }

  Future<List<InventoryItem>> listItems(
      {int limit = 100,
      String? departmentId,
      String? categoryId,
      String? searchQuery}) async {
    Query<Map<String, dynamic>> query = _items.orderBy('name'); // Add index for better performance
    
    // Note: Items may be stored with 'department'/'departmentId' or 'category'/'categoryId' fields
    // Since we can't query multiple field names, we'll do client-side filtering
    // Cap limit to prevent excessive data loading
    final effectiveLimit = limit > 1000 ? 1000 : limit;
    final snapshot = await query.limit(effectiveLimit).get();
    var items = snapshot.docs
        .map((doc) => InventoryItem.fromJson(doc.id, doc.data()))
        .toList();

    // Apply department filter client-side (items store department as name in departmentId field)
    if (departmentId != null && departmentId.isNotEmpty) {
      items = items
          .where((item) => 
              item.departmentId.trim().toLowerCase() == departmentId.trim().toLowerCase())
          .toList();
    }

    // Apply category filter client-side (items store category as name in categoryId field)
    if (categoryId != null && categoryId.isNotEmpty) {
      items = items
          .where((item) => 
              item.categoryId.trim().toLowerCase() == categoryId.trim().toLowerCase())
          .toList();
    }

    // Apply search query filter
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

  /// Server-side paginated listing ordered by name + document ID for stable pagination.
  /// Optional filters on department/category.
  /// Use [startAfterName] and [startAfterId] for cursor-based pagination.
  Future<List<InventoryItem>> listItemsPage({
    required int limit,
    String? departmentId,
    String? categoryId,
    String? startAfterName,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> query =
        _items.orderBy('name').orderBy(FieldPath.documentId);
    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (startAfterName != null &&
        startAfterName.isNotEmpty &&
        startAfterId != null &&
        startAfterId.isNotEmpty) {
      query = query.startAfter([startAfterName, startAfterId]);
    }
    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => InventoryItem.fromJson(doc.id, doc.data()))
        .toList();
  }

  /// Read items list from Firestore's local disk cache only - no network call.
  /// Returns instantly (<50ms) if data was previously fetched, empty list
  /// otherwise. Used as the first tier in cache-first reads so screens render
  /// instantly on app reload.
  Future<List<InventoryItem>> listAllItemsFromDisk({
    String? departmentId,
    String? categoryId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _items.orderBy('name');
      if (departmentId != null && departmentId.isNotEmpty) {
        query = query.where('departmentId', isEqualTo: departmentId);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      final snap = await query.get(const GetOptions(source: Source.cache));
      return snap.docs
          .map((d) => InventoryItem.fromJson(d.id, d.data()))
          .toList();
    } catch (_) {
      // Cache miss or unavailable - return empty so caller falls through to network.
      return const [];
    }
  }

  /// Read categories from Firestore disk cache. Returns empty on miss.
  Future<List<Category>> listCategoriesFromDisk(
      {bool includeInactive = true}) async {
    try {
      Query<Map<String, dynamic>> query = _categories.orderBy('name');
      if (!includeInactive) {
        query = query.where('isActive', isEqualTo: true);
      }
      final snap = await query.get(const GetOptions(source: Source.cache));
      return snap.docs
          .map((d) => Category.fromJson(d.id, d.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Fast server-side counts for the dashboard stats grid. Returns total +
  /// per-status counts WITHOUT downloading any documents. Each call is one
  /// aggregate round-trip (~50-200ms) regardless of how many items exist.
  Future<Map<String, int>> getItemCounts() async {
    Future<int> safeCount(Query<Map<String, dynamic>> q) async {
      try {
        final snap = await q.count().get();
        return snap.count ?? 0;
      } catch (e) {
        debugPrint('count() failed: $e');
        return 0;
      }
    }

    final results = await Future.wait([
      safeCount(_items),
      safeCount(_items.where('assignedTo', isGreaterThan: '')),
      safeCount(_items.where('qrCodeUrl', isGreaterThan: '')),
    ]);

    final total = results[0];
    final assigned = results[1];
    final tagged = results[2];
    return {
      'total': total,
      'assigned': assigned,
      'unassigned': total - assigned,
      'tagged': tagged,
    };
  }

  /// Fetch all items by iterating pages using name-based cursors.
  /// This avoids missing items when counts exceed a single query limit.
  /// Note: Lower pageSize reduces memory allocation and GC pressure.
  Future<List<InventoryItem>> listAllItems({
    String? departmentId,
    String? categoryId,
    int pageSize = 500, // Increased default to reduce pagination rounds
  }) async {
    final List<InventoryItem> all = <InventoryItem>[];
    String? cursorName;
    String? cursorId;
    int consecutiveEmptyPages = 0;
    const maxConsecutiveEmpty = 3; // Safety limit
    
    while (true) {
      final page = await listItemsPage(
        limit: pageSize,
        departmentId: departmentId,
        categoryId: categoryId,
        startAfterName: cursorName,
        startAfterId: cursorId,
      );
      
      if (page.isEmpty) {
        consecutiveEmptyPages++;
        if (consecutiveEmptyPages >= maxConsecutiveEmpty) {
          // Safety break if we get multiple empty pages
          break;
        }
        // Try next iteration with same cursor (in case of transient issues)
        continue;
      }
      
      consecutiveEmptyPages = 0; // Reset counter on successful page
      all.addAll(page);
      
      // Break if we got fewer items than requested (last page)
      if (page.length < pageSize) {
        break;
      }
      
      // Set cursor for next page - use last item's name + document ID
      final lastItem = page.last;
      cursorName = lastItem.name;
      cursorId = lastItem.id;
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
    // Use toJson() to ensure all fields are included
    final itemJson = item.toJson();
    itemJson['id'] = docRef.id;
    await _executeWrite(() async {
      await docRef.set(itemJson);
      await _logItemHistory(
        docRef.id,
        'create',
        metadata: {'assetId': item.assetId, 'name': item.name},
      );
    });
    return docRef.id;
  }

  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    final fieldKeys =
        updates.keys.map((k) => k.toString()).where((k) => k != 'updatedAt').toList();
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _executeWrite(() async {
      await _items.doc(id).set(updates, SetOptions(merge: true));
      await _logItemHistory(
        id,
        'update',
        metadata: {'fields': fieldKeys},
        notes: _historyNoteForFields(fieldKeys),
      );
    });
  }

  Future<void> updateItemStatus(String id, String status) async {
    await _executeWrite(() async {
      await _items.doc(id).set(
          {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
      await _logItemHistory(
        id,
        'status_update',
        metadata: {'status': status},
      );
    });
  }

  Future<void> upsertItem(InventoryItem item) async {
    await _executeWrite(() async {
      await _items.doc(item.id).set(item.toJson(), SetOptions(merge: true));
      await _logItemHistory(
        item.id,
        'upsert',
        metadata: {'assetId': item.assetId, 'name': item.name},
      );
    });
  }

  Future<void> deleteItem(String id) async {
    await _executeWrite(() async {
      await _items.doc(id).delete();
      await _logItemHistory(
        id,
        'delete',
      );
    });
  }

  /// Atomically reserves the next asset id (safe under concurrent creates).
  Future<String> reserveNextAssetId({String counterDocId = 'default'}) {
    return AssetCounterService(_firestore)
        .reserveNextAssetId(counterDocId: counterDocId);
  }

  /// Back-compat alias — prefer [reserveNextAssetId] at save time.
  Future<String> generateNextAssetId() => reserveNextAssetId();

  /// Next asset id for forms: combines live inventory patterns with the
  /// Firestore counter [currentValue] as a floor. Does **not** increment the counter.
  Future<AssetIdSuggestion> suggestNextAssetIdForForm({
    String counterDocId = 'default',
    int pageSize = 1000,
  }) async {
    final counterService = AssetCounterService(_firestore);
    final counter = await counterService.fetchCounter(counterDocId);
    final prefix = counter?.prefix ?? 'ASSET';
    final floor = counter?.currentValue ?? 0;

    final items = await listAllItems(pageSize: pageSize);
    final assetIds = items
        .map((e) => e.assetId)
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return suggestNextAssetId(
      assetIds: assetIds,
      counterPrefix: prefix,
      counterCurrentValue: floor,
    );
  }

  /// Keeps the Firestore counter aligned after a create when the saved id matches
  /// the counter prefix (supports manual edits and imports).
  /// Aligns the counter after a manual or imported asset id is persisted.
  Future<void> advanceAssetCounterAfterCreate(
    String savedAssetId, {
    String counterDocId = 'default',
  }) {
    return AssetCounterService(_firestore).advanceCounterFloor(
      savedAssetId,
      counterDocId: counterDocId,
    );
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
  final _cache = CacheService.instance;

  CollectionReference<Map<String, dynamic>> get _departments =>
      _firestore.collection('departments');
  CollectionReference<Map<String, dynamic>> get _subDepartments =>
      _firestore.collection('subDepartments');

  Stream<List<Department>> watchDepartments() {
    return _departments.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Department.fromJson(doc.id, doc.data()))
        .toList());
  }

  /// Read departments from Firestore disk cache only - no network. Returns
  /// instantly if data was previously fetched, empty list otherwise.
  Future<List<Department>> listDepartmentsFromDisk(
      {bool includeInactive = true}) async {
    try {
      Query<Map<String, dynamic>> query = !includeInactive
          ? _departments.where('isActive', isEqualTo: true)
          : _departments.orderBy('name');
      final snap = await query.get(const GetOptions(source: Source.cache));
      final list = snap.docs
          .map((d) => Department.fromJson(d.id, d.data()))
          .toList();
      if (!includeInactive) list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<List<Department>> listDepartments(
      {bool includeInactive = true}) async {
    final cacheKey =
        '${CacheKeys.departments}_${includeInactive ? 'all' : 'active'}';
    final cached = _cache.get<List<Department>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    if (!includeInactive) {
      // Avoid combining where + orderBy to prevent requiring a composite index
      final snapshot =
          await _departments.where('isActive', isEqualTo: true).get();
      final list = snapshot.docs
          .map((doc) => Department.fromJson(doc.id, doc.data()))
          .toList();
      // Client-side sort by name to preserve UI ordering
      list.sort((a, b) => a.name.compareTo(b.name));
      _cache.setAndPersist<Department>(
        cacheKey,
        list,
        (d) => d.toJson(),
        (d) => d.id,
        ttl: const Duration(minutes: 30),
      );
      return list;
    } else {
      final snapshot = await _departments.orderBy('name').get();
      final list = snapshot.docs
          .map((doc) => Department.fromJson(doc.id, doc.data()))
          .toList();
      _cache.setAndPersist<Department>(
        cacheKey,
        list,
        (d) => d.toJson(),
        (d) => d.id,
        ttl: const Duration(minutes: 30),
      );
      return list;
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
    _invalidateDepartmentCache();
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
    _invalidateDepartmentCache();
  }

  Future<void> setDepartmentStatus(String id, bool isActive) async {
    await _departments.doc(id).set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _invalidateDepartmentCache();
  }

  Future<void> deleteDepartment(String id) async {
    await _departments.doc(id).delete();
    _invalidateDepartmentCache();
  }

  void _invalidateDepartmentCache() {
    _cache.remove('${CacheKeys.departments}_all');
    _cache.remove('${CacheKeys.departments}_active');
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

  /// Disk-cached open issues - returns instantly from local cache, empty on miss.
  Future<List<Issue>> listOpenIssuesFromDisk({int limit = 100}) async {
    try {
      final snap = await _issues
          .where('status', isNotEqualTo: 'closed')
          .orderBy('status')
          .limit(limit)
          .get(const GetOptions(source: Source.cache));
      return snap.docs.map((d) => Issue.fromJson(d.id, d.data())).toList();
    } catch (_) {
      return const [];
    }
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

  /// Disk-cached recent history. Returns instantly from local cache, empty on miss.
  Future<List<HistoryEntry>> recentHistoryFromDisk({int limit = 10}) async {
    try {
      final snap = await _history
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.cache));
      return snap.docs
          .map((d) => HistoryEntry.fromJson(d.id, d.data()))
          .toList();
    } catch (_) {
      return const [];
    }
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
      {String? notes, String? signatureUrl}) async {
    await _history.add(HistoryEntry(
      id: '',
      itemId: itemId,
      action: 'check_in',
      actorId: userId,
      notes: notes,
      timestamp: DateTime.now(),
      signatureUrl: signatureUrl,
    ).toJson());
  }

  Future<void> recordCheckOut(String itemId, String userId,
      {String? notes, String? signatureUrl}) async {
    await _history.add(HistoryEntry(
      id: '',
      itemId: itemId,
      action: 'check_out',
      actorId: userId,
      notes: notes,
      timestamp: DateTime.now(),
      signatureUrl: signatureUrl,
    ).toJson());
  }

  Future<void> recordFinanceEdit(
    String itemId,
    String userId, {
    required Map<String, dynamic> updates,
    String? signatureUrl,
  }) async {
    await _history.add(
      HistoryEntry(
        id: '',
        itemId: itemId,
        action: 'finance_edit',
        actorId: userId,
        notes: 'Finance edit',
        metadata: {
          'updatedFields': updates.keys.toList(),
        },
        timestamp: DateTime.now(),
        signatureUrl: signatureUrl,
      ).toJson(),
    );
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
    String? authUid,
  }) async {
    final doc = authUid != null ? _staff.doc(authUid) : _staff.doc();
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

  Future<String> createPermissionSet({
    required String name,
    String? description,
    List<String> permissions = const [],
  }) async {
    final doc = _permissionSets.doc();
    await doc.set({
      'name': name,
      if (description != null) 'description': description,
      'permissions': permissions,
    });
    return doc.id;
  }

  Future<void> updatePermissionSet(String id, List<String> permissions) async {
    await _permissionSets
        .doc(id)
        .set({'permissions': permissions}, SetOptions(merge: true));
  }

  /// Ensures default permission sets exist (Finance, Operator, Admin, etc.)
  Future<void> ensureDefaultPermissionSets() async {
    final existing = await listPermissionSets();
    final existingNames = existing.map((p) => p.name.toLowerCase()).toSet();

    final defaultSets = [
      {
        'name': 'Finance',
        'description': 'Finance role with limited editing capabilities',
        'permissions': ['finance', 'edit_financial_fields', 'edit_asset_number', 'view_items', 'view_reports'],
      },
      {
        'name': 'Operator',
        'description': 'Standard operator role',
        'permissions': ['view_items', 'manage_items'],
      },
      {
        'name': 'Admin',
        'description': 'Administrator with full access',
        'permissions': ['admin', 'manage_items', 'manage_departments', 'manage_staff', 'view_reports', '*'],
      },
    ];

    for (final setData in defaultSets) {
      final setName = setData['name'] as String;
      if (!existingNames.contains(setName.toLowerCase())) {
        await createPermissionSet(
          name: setName,
          description: setData['description'] as String?,
          permissions: (setData['permissions'] as List).cast<String>(),
        );
      }
    }

    // Existing installs may have Operator with only view_items; merge manage_items once.
    for (final p in existing) {
      if (p.name.toLowerCase() != 'operator') continue;
      if (p.permissions.contains('manage_items')) break;
      await updatePermissionSet(p.id, [...p.permissions, 'manage_items']);
      break;
    }
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
  UserService(
    this._firestore, {
    UserProvisioningService? provisioning,
  }) : _provisioning = provisioning ?? UserProvisioningService();

  final FirebaseFirestore _firestore;
  final UserProvisioningService _provisioning;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<AppUser>> listUsers() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((doc) => AppUser.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> disableUser(String uid, {required bool disabled}) async {
    await _users.doc(uid).set({
      'isActive': !disabled, // Firestore uses 'isActive' (inverted)
      'isDisabled': disabled, // Also update isDisabled for compatibility
    }, SetOptions(merge: true));
  }

  /// Creates Auth account + `users/{authUid}` via Cloud Function (admin only).
  Future<UserProvisioningResult> createUser({
    required String email,
    required String displayName,
    String? departmentId,
    String? role,
    String? password,
  }) {
    return _provisioning.createAppUser(
      email: email,
      displayName: displayName,
      departmentId: departmentId,
      roleId: role,
      password: password,
    );
  }

  /// Links an existing Auth UID to a Firestore profile (console-created accounts).
  Future<void> linkExistingAuthUser({
    required String authUid,
    required String email,
    required String displayName,
    String? departmentId,
    String? role,
  }) {
    return _provisioning.provisionUserProfile(
      authUid: authUid,
      email: email,
      displayName: displayName,
      departmentId: departmentId,
      roleId: role,
    );
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
    if (displayName != null) {
      updates['name'] = displayName; // Firestore uses 'name'
      updates['displayName'] = displayName; // Also update displayName for compatibility
    }
    if (departmentId != null) {
      updates['department'] = departmentId; // Firestore uses 'department'
      updates['departmentId'] = departmentId; // Also update departmentId for compatibility
    }
    if (role != null) {
      updates['roleId'] = role; // Firestore uses 'roleId'
      updates['role'] = role; // Also update role for compatibility
    }
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
