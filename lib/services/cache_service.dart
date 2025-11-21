/// Simple in-memory cache service for performance optimization
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final Map<String, _CacheEntry> _cache = {};
  static const Duration defaultTtl = Duration(minutes: 5);

  /// Get cached value if not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  /// Set cache value with optional TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  /// Remove specific key
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries
  void cleanup() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Get cache size
  int get size => _cache.length;
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});

  final dynamic value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache keys for consistent access
class CacheKeys {
  static String items(String? departmentId, String? categoryId) =>
      'items_${departmentId ?? 'all'}_${categoryId ?? 'all'}';
  static String departments = 'departments';
  static String categories = 'categories';
  static String staff = 'staff';
  static String item(String id) => 'item_$id';
}

