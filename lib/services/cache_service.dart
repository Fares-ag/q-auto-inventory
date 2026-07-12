import 'persistent_cache_service.dart';

/// In-memory cache with optional disk persistence.
///
/// **Cold-start behaviour:**
/// 1. `main()` calls `CacheService.instance.init()` — this opens the disk
///    store and pre-hydrates the in-memory cache for known list keys.
/// 2. The first frame of every screen sees data immediately via `get()`,
///    so spinners/skeletons are skipped on subsequent app launches.
/// 3. Background refreshes from Firestore overwrite the cache as fresh
///    data arrives, but the user sees old data instantly in the meantime.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final Map<String, _CacheEntry> _cache = {};
  static const Duration defaultTtl = Duration(minutes: 5);
  // A long TTL we use when hydrating from disk so already-stale data is
  // still visible. Network refresh overwrites with normal TTL.
  static const Duration _hydrationTtl = Duration(hours: 24);

  bool _initialized = false;

  /// Open the disk store. Safe to call multiple times.
  /// Does NOT auto-hydrate any keys — callers register the keys they want
  /// hydrated via [hydrateFromDisk].
  Future<void> init() async {
    if (_initialized) return;
    await PersistentCacheService.instance.init();
    _initialized = true;
  }

  /// Read a previously persisted JSON list from disk and stash it in
  /// memory under [key] so the next [get] call returns it instantly.
  ///
  /// [fromJson] converts each map into the typed model. If the disk is
  /// empty or decoding fails, this is a no-op.
  ///
  /// Call once per data type from a top-level loader (e.g. AssetPreloader)
  /// to seed the cache before any screen mounts.
  void hydrateFromDisk<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (!_initialized) return;
    final raw = PersistentCacheService.instance.getJsonList(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final items = raw.map(fromJson).toList();
      _cache[key] = _CacheEntry(
        value: items,
        expiresAt: DateTime.now().add(_hydrationTtl),
      );
    } catch (_) {
      // Schema mismatch or corrupt entry — silently drop, network will refill.
    }
  }

  /// Get cached value if not expired.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  /// Set cache value with optional TTL. In-memory only; use [setAndPersist]
  /// for lists that should survive app restart.
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  /// Write a list of model objects to memory AND persist to disk so the
  /// next cold start can hydrate instantly. Persistence is fire-and-forget;
  /// failures are logged but never propagated.
  ///
  /// The model's [id] (Firestore doc id) is injected into each persisted
  /// JSON map as `id`, since the model's `toJson()` does not include it.
  /// On hydrate we read this back via the `fromJson(map['id'], map)` shape
  /// expected by every model factory.
  void setAndPersist<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
    String Function(T) idOf, {
    Duration? ttl,
  }) {
    set<List<T>>(key, items, ttl: ttl);
    PersistentCacheService.instance.setJsonList(
      key,
      items.map((item) {
        final m = toJson(item);
        m['id'] = idOf(item);
        return m;
      }).toList(),
    );
  }

  void remove(String key) {
    _cache.remove(key);
    PersistentCacheService.instance.remove(key);
  }

  /// Clear in-memory and disk caches. Used on logout / "wipe data" actions.
  Future<void> clear() async {
    _cache.clear();
    await PersistentCacheService.instance.clearAll();
  }

  void cleanup() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  int get size => _cache.length;
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});

  final dynamic value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache keys for consistent access.
class CacheKeys {
  static String items(String? departmentId, String? categoryId) =>
      'items_${departmentId ?? 'all'}_${categoryId ?? 'all'}';
  static String departments = 'departments';
  static String categories = 'categories';
  static String staff = 'staff';
  static String item(String id) => 'item_$id';
}
