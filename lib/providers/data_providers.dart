// Data providers for async data (dashboard, items list, approvals).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/firestore_models.dart';
import '../services/cache_service.dart';
import 'service_providers.dart';

// ── Dashboard ─────────────────────────────────────────────────────────────────
//
// The dashboard is split into independent providers so each section of the UI
// can render as soon as its own data arrives, instead of the entire page
// being gated on the slowest call (the full items list).

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.assigned,
    required this.unassigned,
    required this.tagged,
  });

  const DashboardStats.empty()
      : total = 0,
        assigned = 0,
        unassigned = 0,
        tagged = 0;

  final int total;
  final int assigned;
  final int unassigned;
  final int tagged;
}

DashboardStats _statsFromItems(List<InventoryItem> items) {
  int assigned = 0;
  int tagged = 0;
  for (final item in items) {
    if (item.assignedTo != null && item.assignedTo!.isNotEmpty) assigned++;
    if (item.qrCodeUrl != null && item.qrCodeUrl!.isNotEmpty) tagged++;
  }
  return DashboardStats(
    total: items.length,
    assigned: assigned,
    unassigned: items.length - assigned,
    tagged: tagged,
  );
}

bool _activityNearSameTime(DateTime? a, DateTime? b, {int seconds = 120}) {
  if (a == null || b == null) return false;
  return a.difference(b).inSeconds.abs() <= seconds;
}

DateTime? _inventoryItemLastTouched(InventoryItem i) =>
    i.updatedAt ?? i.createdAt;

/// Merges Firestore [history] with items recently updated in-app so the
/// dashboard reflects real work even when history was empty or lagging.
List<HistoryEntry> mergeDashboardActivity(
  List<HistoryEntry> history,
  List<InventoryItem> items, {
  int limit = 12,
}) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final sortedHistory = [...history]..sort((a, b) {
      final ta = a.timestamp ?? epoch;
      final tb = b.timestamp ?? epoch;
      return tb.compareTo(ta);
    });

  final datedItems = items
      .map((i) => (item: i, touched: _inventoryItemLastTouched(i)))
      .where((e) => e.touched != null)
      .toList()
    ..sort((a, b) => b.touched!.compareTo(a.touched!));

  final synthetic = <HistoryEntry>[];
  for (final e in datedItems.take(48)) {
    final i = e.item;
    final touched = e.touched!;
    synthetic.add(HistoryEntry(
      id: 'touch:${i.id}',
      itemId: i.id,
      action: 'update',
      actorId: '',
      metadata: {
        'name': i.name,
        if (i.assetId.isNotEmpty) 'assetId': i.assetId,
      },
      timestamp: touched,
    ));
  }

  final filteredSynth = synthetic.where((s) {
    return !sortedHistory.any(
      (h) =>
          h.itemId == s.itemId &&
          _activityNearSameTime(h.timestamp, s.timestamp),
    );
  });

  final merged = [...sortedHistory, ...filteredSynth]..sort((a, b) {
      final ta = a.timestamp ?? epoch;
      final tb = b.timestamp ?? epoch;
      return tb.compareTo(ta);
    });

  if (merged.length <= limit) return merged;
  return merged.sublist(0, limit);
}

/// Items list - cache-first stream. Emits in this order:
/// 1. In-memory cache (synchronous, <1ms)
/// 2. Firestore disk cache (~50ms, survives app restarts)
/// 3. Server fetch (network)
/// On second-and-later launches the UI is hydrated instantly.
final dashboardItemsProvider =
    StreamProvider.autoDispose<List<InventoryItem>>((ref) async* {
  final catalog = ref.watch(catalogServiceProvider);
  final cache = CacheService.instance;
  final cacheKey = CacheKeys.items(null, null);

  bool emitted = false;

  // Tier 1: in-memory cache.
  final mem = cache.get<List<InventoryItem>>(cacheKey);
  if (mem != null && mem.isNotEmpty) {
    yield mem;
    emitted = true;
  } else {
    // Tier 2: Firestore disk cache.
    final disk = await catalog.listAllItemsFromDisk();
    if (disk.isNotEmpty) {
      cache.set(cacheKey, disk, ttl: const Duration(minutes: 30));
      yield disk;
      emitted = true;
    }
  }

  // Tier 3: always refresh from server.
  try {
    final fresh = await catalog.listAllItems(pageSize: 1000);
    cache.set(cacheKey, fresh, ttl: const Duration(minutes: 30));
    yield fresh;
  } catch (e) {
    // If we already showed cached data, swallow the error (offline-friendly).
    // Otherwise surface it so the UI can show a retry.
    if (!emitted) rethrow;
  }
});

/// Stats - derived from the items stream so we don't double-fetch. Emits
/// fresh stats on every items emission (in-memory cache, disk cache, server).
final dashboardStatsProvider =
    StreamProvider.autoDispose<DashboardStats>((ref) {
  return ref
      .watch(dashboardItemsProvider.stream)
      .map(_statsFromItems);
});

/// Recent activity - cache-first stream.
final dashboardHistoryProvider =
    StreamProvider.autoDispose<List<HistoryEntry>>((ref) async* {
  final svc = ref.watch(historyServiceProvider);
  bool emitted = false;

  final disk = await svc.recentHistoryFromDisk(limit: 60);
  if (disk.isNotEmpty) {
    yield disk;
    emitted = true;
  }

  try {
    yield await svc.recentHistory(limit: 60);
  } catch (e) {
    if (!emitted) rethrow;
  }
});

/// Open issues count - cache-first stream.
final dashboardIssuesCountProvider =
    StreamProvider.autoDispose<int>((ref) async* {
  final svc = ref.watch(issueServiceProvider);
  bool emitted = false;

  final disk = await svc.listOpenIssuesFromDisk(limit: 50);
  if (disk.isNotEmpty) {
    yield disk.length;
    emitted = true;
  }

  try {
    final fresh = await svc.listOpenIssues(limit: 50);
    yield fresh.length;
  } catch (e) {
    if (!emitted) rethrow;
  }
});

// ── Items list ────────────────────────────────────────────────────────────────

/// Cache-first items list. Same 3-tier strategy as dashboardItemsProvider.
final allItemsProvider =
    StreamProvider.autoDispose<List<InventoryItem>>((ref) async* {
  final catalog = ref.watch(catalogServiceProvider);
  final cache = CacheService.instance;
  final cacheKey = CacheKeys.items(null, null);
  bool emitted = false;

  final mem = cache.get<List<InventoryItem>>(cacheKey);
  if (mem != null && mem.isNotEmpty) {
    yield mem;
    emitted = true;
  } else {
    final disk = await catalog.listAllItemsFromDisk();
    if (disk.isNotEmpty) {
      cache.set(cacheKey, disk, ttl: const Duration(minutes: 30));
      yield disk;
      emitted = true;
    }
  }

  try {
    final fresh = await catalog.listAllItems(pageSize: 1000);
    cache.set(cacheKey, fresh, ttl: const Duration(minutes: 30));
    yield fresh;
  } catch (e) {
    if (!emitted) rethrow;
  }
});

// ── Approvals — stream of pending items ──────────────────────────────────────

final pendingApprovalsProvider = StreamProvider.autoDispose<List<InventoryItem>>((ref) {
  final catalog = ref.watch(catalogServiceProvider);
  return catalog.watchItems(status: 'pending');
});

// ── Categories ────────────────────────────────────────────────────────────────

/// Cache-first categories. Disk-cached emit, then server refresh.
final categoriesProvider =
    StreamProvider.autoDispose<List<Category>>((ref) async* {
  final catalog = ref.watch(catalogServiceProvider);
  bool emitted = false;

  final disk = await catalog.listCategoriesFromDisk();
  if (disk.isNotEmpty) {
    yield disk;
    emitted = true;
  }

  try {
    yield await catalog.listCategories();
  } catch (e) {
    if (!emitted) rethrow;
  }
});

// ── Departments ───────────────────────────────────────────────────────────────

/// Cache-first departments. Disk-cached emit, then server refresh.
final departmentsProvider =
    StreamProvider.autoDispose<List<Department>>((ref) async* {
  final svc = ref.watch(departmentServiceProvider);
  bool emitted = false;

  final disk = await svc.listDepartmentsFromDisk(includeInactive: false);
  if (disk.isNotEmpty) {
    yield disk;
    emitted = true;
  }

  try {
    yield await svc.listDepartments(includeInactive: false);
  } catch (e) {
    if (!emitted) rethrow;
  }
});

final departmentsStreamProvider = StreamProvider.autoDispose<List<Department>>((ref) {
  return ref.watch(departmentServiceProvider).watchDepartments();
});
