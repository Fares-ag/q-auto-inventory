import 'package:flutter/foundation.dart';

import '../models/firestore_models.dart';
import 'firebase_services.dart';
import 'cache_service.dart';

/// Service to preload all assets in the background for instant access
class DataPreloaderService {
  DataPreloaderService({
    required CatalogService catalog,
    required DepartmentService departments,
    required StaffService staff,
  })  : _catalog = catalog,
        _departments = departments,
        _staff = staff;

  final CatalogService _catalog;
  final DepartmentService _departments;
  final StaffService _staff;
  final _cache = CacheService.instance;

  bool _isPreloading = false;
  bool _isPreloaded = false;
  int _loadedCount = 0;
  int _totalCount = 0;

  bool get isPreloading => _isPreloading;
  bool get isPreloaded => _isPreloaded;
  int get loadedCount => _loadedCount;
  int get totalCount => _totalCount;
  double get progress => _totalCount > 0 ? _loadedCount / _totalCount : 0.0;

  /// Start preloading all assets in the background
  Future<void> preloadAllAssets({
    VoidCallback? onProgress,
    VoidCallback? onComplete,
  }) async {
    if (_isPreloading || _isPreloaded) return;

    _isPreloading = true;
    _loadedCount = 0;
    _totalCount = 0;

    try {
      // Step 1: Preload departments and categories (fast, small data)
      debugPrint('Preloader: Loading departments and categories...');
      await Future.wait([
        _preloadDepartments(),
        _preloadCategories(),
      ]);
      onProgress?.call();

      debugPrint('Preloader: Loading all items (paged)...');
      await _preloadAllItems(
        onProgress: () {
          onProgress?.call();
        },
      );

      // Step 4: Preload staff (for assignedTo lookups)
      debugPrint('Preloader: Loading staff...');
      await _preloadStaff();

      _isPreloaded = true;
      _isPreloading = false;
      debugPrint('Preloader: Complete! Loaded $_loadedCount items');
      onComplete?.call();
    } catch (e) {
      _isPreloading = false;
      debugPrint('Preloader: Error - $e');
      rethrow;
    }
  }

  Future<void> _preloadDepartments() async {
    final depts = await _departments.listDepartments(includeInactive: false);
    // Must match keys used in DepartmentService.listDepartments
    _cache.set(
      '${CacheKeys.departments}_active',
      depts,
      ttl: const Duration(hours: 1),
    );
  }

  Future<void> _preloadCategories() async {
    final cats = await _catalog.listCategories(includeInactive: true);
    _cache.set(
      '${CacheKeys.categories}_all',
      cats,
      ttl: const Duration(hours: 1),
    );
  }

  Future<void> _preloadStaff() async {
    final staff = await _staff.listStaff();
    _cache.set(CacheKeys.staff, staff, ttl: const Duration(hours: 1));
  }

  /// Load all items in sequential pages (Firestore cursor pagination).
  /// Larger page size + no artificial delay: faster full catalog load.
  Future<void> _preloadAllItems({VoidCallback? onProgress}) async {
    const batchSize = 500;
    final List<InventoryItem> allItems = [];
    String? cursorName;
    String? cursorId;

    while (true) {
      final batch = await _catalog.listItemsPage(
        limit: batchSize,
        startAfterName: cursorName,
        startAfterId: cursorId,
      );

      if (batch.isEmpty) break;

      allItems.addAll(batch);
      _loadedCount = allItems.length;
      _totalCount = _loadedCount; // Update as we go

      if (batch.length < batchSize) {
        // Last batch
        break;
      }

      // Update cursor for next batch
      cursorName = batch.last.name;
      cursorId = batch.last.id;
      onProgress?.call();
    }

    // Cache all items with long TTL
    _cache.set(
      CacheKeys.items(null, null),
      allItems,
      ttl: const Duration(minutes: 30), // Cache for 30 minutes
    );

    debugPrint('Preloader: Cached ${allItems.length} items');
  }

  /// Clear preloaded data (useful for refresh)
  void clearPreloadedData() {
    _isPreloaded = false;
    _isPreloading = false;
    _loadedCount = 0;
    _totalCount = 0;
    _cache.remove(CacheKeys.items(null, null));
  }
}

