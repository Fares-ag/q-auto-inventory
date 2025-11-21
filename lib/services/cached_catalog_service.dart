import 'package:flutter/foundation.dart' hide Category;

import '../models/firestore_models.dart';
import 'cache_service.dart';
import 'firebase_services.dart';

/// Wrapper around CatalogService that adds caching for performance
class CachedCatalogService {
  CachedCatalogService(this._catalogService);

  final CatalogService _catalogService;
  final _cache = CacheService.instance;

  Future<List<InventoryItem>> listItems({
    int limit = 100,
    String? departmentId,
    String? categoryId,
    String? searchQuery,
    bool useCache = true,
  }) async {
    // Don't cache if search query is provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return _catalogService.listItems(
        limit: limit,
        departmentId: departmentId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
    }

    final cacheKey = CacheKeys.items(departmentId, categoryId);
    
    if (useCache) {
      final cached = _cache.get<List<InventoryItem>>(cacheKey);
      if (cached != null) {
        debugPrint('Cache hit for items: $cacheKey');
        return cached;
      }
    }

    final items = await _catalogService.listItems(
      limit: limit,
      departmentId: departmentId,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );

    // Cache the results
    _cache.set(cacheKey, items, ttl: const Duration(minutes: 2));
    return items;
  }

  Future<InventoryItem?> getItem(String id, {bool useCache = true}) async {
    final cacheKey = CacheKeys.item(id);
    
    if (useCache) {
      final cached = _cache.get<InventoryItem>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    final item = await _catalogService.getItem(id);
    if (item != null) {
      _cache.set(cacheKey, item, ttl: const Duration(minutes: 5));
    }
    return item;
  }

  Future<List<Category>> listCategories({bool useCache = true}) async {
    if (useCache) {
      final cached = _cache.get<List<Category>>(CacheKeys.categories);
      if (cached != null) {
        return cached;
      }
    }

    final categories = await _catalogService.listCategories();
    _cache.set(CacheKeys.categories, categories, ttl: const Duration(minutes: 10));
    return categories;
  }

  // Invalidate cache when items are modified
  void invalidateCache({String? itemId, String? departmentId, String? categoryId}) {
    if (itemId != null) {
      _cache.remove(CacheKeys.item(itemId));
    }
    // Invalidate all item lists
    _cache.remove(CacheKeys.items(departmentId, categoryId));
    _cache.remove(CacheKeys.items(null, null));
  }

  // Delegate other methods
  Stream<List<InventoryItem>> watchItems({
    String? status,
    String? departmentId,
    String? categoryId,
  }) {
    return _catalogService.watchItems(
      status: status,
      departmentId: departmentId,
      categoryId: categoryId,
    );
  }

  Future<String> createItem(InventoryItem item) async {
    final id = await _catalogService.createItem(item);
    invalidateCache();
    return id;
  }

  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    await _catalogService.updateItem(id, updates);
    invalidateCache(itemId: id);
  }

  Future<void> updateItemStatus(String id, String status) async {
    await _catalogService.updateItemStatus(id, status);
    invalidateCache(itemId: id);
  }

  Future<void> upsertItem(InventoryItem item) async {
    await _catalogService.upsertItem(item);
    invalidateCache(itemId: item.id);
  }

  Future<void> deleteItem(String id) async {
    await _catalogService.deleteItem(id);
    invalidateCache(itemId: id);
  }

  Future<String> generateNextAssetId() {
    return _catalogService.generateNextAssetId();
  }
}

