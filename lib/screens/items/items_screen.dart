import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/firestore_models.dart';
import '../../providers/permission_providers.dart';
import '../../services/firebase_services.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../utils/network_utils.dart';
import '../../utils/operator_layout.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';
import '../qr/bulk_qr_print_screen.dart';
import '../qr/qr_scanner_screen.dart';
import 'all_items_screen.dart';
import 'bulk_assign_screen.dart';
import 'item_detail_screen.dart';

// Custom cache manager for faster image loading with optimized settings
final _imageCacheManager = CacheManager(
  Config(
    'item_images',
    stalePeriod: const Duration(days: 30), // Longer cache for faster loads
    maxNrOfCacheObjects: 500, // More cached images
  ),
);

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  static const String _filtersCacheKey = 'items_filters_v1';
  String? _selectedDeptId;
  String? _selectedCategoryId;
  String? _selectedStatus;
  List<Department> _departments = const [];
  List<Category> _categories = const [];
  // Cache department/category lookups for O(1) access instead of O(n) firstWhere
  Map<String, Department> _deptMap = {};
  Map<String, Category> _catMap = {};
  Map<String, Department> _deptNameMapLower = {};
  Map<String, Category> _catNameMapLower = {};
  bool _isGridView = false;
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _filtersExpanded = false;
  Timer? _searchDebounce;
  
  // ── Items state ──────────────────────────────────────────────────────────
  // _rawItems = full accumulated list from all loaded pages.
  // _visibleItems = filtered/sorted projection of _rawItems (client-side only).
  final List<InventoryItem> _rawItems = [];
  List<InventoryItem> _visibleItems = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  // Progressive loading: pages of _pageSize items loaded one at a time.
  // _allLoaded = true once the last page arrives.
  static const int _pageSize = 50;
  bool _allLoaded = false;
  String? _pageCursorName;
  String? _pageCursorId;
  Object? _error;

  // Memoized stats - recomputed only when _visibleItems reference changes.
  Map<String, int>? _statsCache;
  List<InventoryItem>? _statsCacheKey;

  // Track when we last fetched from network so we can skip redundant
  // background refetches if the cache is fresh (<5 min old).
  DateTime? _lastNetworkFetch;
  static const Duration _networkFreshness = Duration(minutes: 5);

  final _cache = CacheService.instance;

  @override
  void initState() {
    super.initState();
    _restoreFilters();
    Future.microtask(_bootstrapFilters);
    _searchCtrl.addListener(_onSearchChanged);
    _loadItems();
  }
  
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      // Local filter only - no network call. Search filtering is instant
      // because all items are already in memory.
      _applyFiltersAndSort();
      _persistFilters();
    });
  }

  void _restoreFilters() {
    final cached = _cache.get<Map<String, dynamic>>(_filtersCacheKey);
    if (cached == null) return;
    setState(() {
      _selectedDeptId = cached['deptId'] as String?;
      _selectedCategoryId = cached['categoryId'] as String?;
      _selectedStatus = cached['status'] as String?;
      _sortBy = (cached['sortBy'] as String?) ?? _sortBy;
      _sortAscending = (cached['sortAscending'] as bool?) ?? _sortAscending;
      _isGridView = (cached['gridView'] as bool?) ?? _isGridView;
      _filtersExpanded =
          (cached['filtersExpanded'] as bool?) ?? _filtersExpanded;
      final search = cached['search'] as String?;
      if (search != null && search.isNotEmpty) {
        _searchCtrl.text = search;
      }
    });
  }

  void _persistFilters() {
    _cache.set(_filtersCacheKey, <String, dynamic>{
      'deptId': _selectedDeptId,
      'categoryId': _selectedCategoryId,
      'status': _selectedStatus,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
      'gridView': _isGridView,
      'filtersExpanded': _filtersExpanded,
      'search': _searchCtrl.text.trim(),
    });
  }

  /// Force refetch from network. Use only for the explicit refresh button or
  /// pull-to-refresh - NOT for filter/sort/search changes.
  void _refreshItems() {
    if (!mounted) return;
    setState(() {
      _rawItems.clear();
      _visibleItems = const [];
      _statsCache = null;
      _statsCacheKey = null;
      _allLoaded = false;
      _pageCursorName = null;
      _pageCursorId = null;
      _error = null;
      _lastNetworkFetch = null;
    });
    if (mounted) {
      _loadItems();
    }
  }

  /// Apply filters + sort to the in-memory raw item list. This is local only,
  /// no network calls. Runs in microtask so chained filter changes coalesce.
  void _applyFiltersAndSort() {
    if (!mounted) return;
    final raw = _rawItems;
    if (raw.isEmpty) {
      if (_visibleItems.isNotEmpty) {
        setState(() => _visibleItems = const []);
      }
      return;
    }

    final searchQuery = _searchCtrl.text.trim().toLowerCase();
    final hasSearch = searchQuery.isNotEmpty;
    final dept = (_selectedDeptId != null && _selectedDeptId!.isNotEmpty)
        ? _deptMap[_selectedDeptId!]
        : null;
    final cat = (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty)
        ? _catMap[_selectedCategoryId!]
        : null;
    final statusLower = (_selectedStatus != null && _selectedStatus!.isNotEmpty)
        ? _selectedStatus!.toLowerCase()
        : null;

    // Single pass filter (avoids multiple .where().toList() copies).
    final filtered = <InventoryItem>[];
    for (final item in raw) {
      if (dept != null && !_matchesDepartment(item, dept)) continue;
      if (cat != null && !_matchesCategory(item, cat)) continue;
      if (statusLower != null &&
          (item.status ?? '').toLowerCase() != statusLower) {
        continue;
      }
      if (hasSearch) {
        final name = item.name.toLowerCase();
        final asset = item.assetId.toLowerCase();
        final desc = (item.description ?? '').toLowerCase();
        if (!name.contains(searchQuery) &&
            !asset.contains(searchQuery) &&
            !desc.contains(searchQuery)) {
          continue;
        }
      }
      filtered.add(item);
    }

    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'assetId':
          comparison = a.assetId.compareTo(b.assetId);
          break;
        case 'status':
          comparison = (a.status ?? '').compareTo(b.status ?? '');
          break;
        case 'purchaseDate':
          if (a.purchaseDate == null && b.purchaseDate == null) {
            comparison = 0;
          } else if (a.purchaseDate == null) {
            comparison = 1;
          } else if (b.purchaseDate == null) {
            comparison = -1;
          } else {
            comparison = a.purchaseDate!.compareTo(b.purchaseDate!);
          }
          break;
        case 'name':
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _visibleItems = filtered;
      // Invalidate stats memoization since visible set changed.
      _statsCacheKey = null;
      _statsCache = null;
    });
  }

  Future<void> _bootstrapFilters() async {
    try {
      // Load in parallel for better performance
      final deptSvc = context.read<DepartmentService>();
      final catSvc = context.read<CatalogService>();
      final results = await Future.wait([
        deptSvc.listDepartments(includeInactive: false),
        catSvc.listCategories(includeInactive: true),
      ]);
      final ds = results[0] as List<Department>;
      final cs = results[1] as List<Category>;
      if (!context.mounted) return;
      // Build lookup maps for O(1) access
      final deptMap = <String, Department>{};
      final catMap = <String, Category>{};
      final deptNameMapLower = <String, Department>{};
      final catNameMapLower = <String, Category>{};
      for (final dept in ds) {
        deptMap[dept.id] = dept;
        deptNameMapLower[dept.name.trim().toLowerCase()] = dept;
      }
      for (final cat in cs) {
        catMap[cat.id] = cat;
        catNameMapLower[cat.name.trim().toLowerCase()] = cat;
      }
      
      setState(() {
        _departments = ds;
        _categories = cs;
        _deptMap = deptMap;
        _catMap = catMap;
        _deptNameMapLower = deptNameMapLower;
        _catNameMapLower = catNameMapLower;
      });
      // Re-apply filters now that dept/cat lookups are populated (only changes
      // visible items if a filter relies on these maps).
      if (_rawItems.isNotEmpty) {
        _applyFiltersAndSort();
      }
    } catch (_) {
      // best-effort; keep UI functional without filters loaded
    }
  }

  bool _matchesDepartment(InventoryItem item, Department dept) {
    final itemDept = item.departmentId.trim();
    if (itemDept.isEmpty) return false;
    if (itemDept == dept.id) return true;
    return itemDept.toLowerCase() == dept.name.trim().toLowerCase();
  }

  bool _matchesCategory(InventoryItem item, Category cat) {
    final itemCat = item.categoryId.trim();
    if (itemCat.isEmpty) return false;
    if (itemCat == cat.id) return true;
    return itemCat.toLowerCase() == cat.name.trim().toLowerCase();
  }

  String _departmentLabelFor(InventoryItem item) {
    final deptId = item.departmentId.trim();
    if (deptId.isEmpty) return 'Unassigned';
    final byId = _deptMap[deptId];
    if (byId != null) return byId.name;
    final byName = _deptNameMapLower[deptId.toLowerCase()];
    if (byName != null) return byName.name;
    return deptId;
  }

  String _categoryLabelFor(InventoryItem item) {
    final catId = item.categoryId.trim();
    if (catId.isEmpty) return 'Uncategorized';
    final byId = _catMap[catId];
    if (byId != null) return byId.name;
    final byName = _catNameMapLower[catId.toLowerCase()];
    if (byName != null) return byName.name;
    return catId;
  }

  Future<void> _loadItems({bool loadMore = false}) async {
    if (_isLoading) return;
    if (!context.mounted) return;

    // Tier 1: in-memory cache — synchronous, instant.
    final cached = _cache.get<List<InventoryItem>>(CacheKeys.items(null, null));
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _rawItems
          ..clear()
          ..addAll(cached);
        // Treat the cache as a full load so UI shows all items immediately.
        _allLoaded = true;
        _isLoading = false;
      });
      _applyFiltersAndSort();

      // Skip background refetch if we already loaded recently this session.
      final lastFetch = _lastNetworkFetch;
      if (lastFetch != null &&
          DateTime.now().difference(lastFetch) < _networkFreshness) {
        return;
      }
      // Silent background refresh — progressive.
      unawaited(_fetchItemsProgressively(showSpinner: false));
      return;
    }

    // Tier 2: Firestore disk cache — instant if items were ever loaded before.
    if (!loadMore) {
      try {
        final catalog = context.read<CatalogService>();
        final disk = await catalog.listAllItemsFromDisk();
        if (disk.isNotEmpty && mounted) {
          _cache.set(
            CacheKeys.items(null, null),
            disk,
            ttl: const Duration(minutes: 30),
          );
          setState(() {
            _rawItems
              ..clear()
              ..addAll(disk);
            _allLoaded = true;
            _isLoading = false;
          });
          _applyFiltersAndSort();
          unawaited(_fetchItemsProgressively(showSpinner: false));
          return;
        }
      } catch (_) {/* fall through to network */}
    }

    // Tier 3: nothing cached — foreground progressive load with skeleton.
    await _fetchItemsProgressively(showSpinner: true);
  }

  /// Progressive batch loader: fetches [_pageSize] items per page and emits
  /// each batch to the UI immediately instead of waiting for all pages.
  /// This means the first 50 items appear in ~200 ms while the rest silently
  /// arrive in the background — no blocking spinner for the full dataset.
  Future<void> _fetchItemsProgressively({required bool showSpinner}) async {
    if (!mounted || !context.mounted) return;

    final catalog = context.read<CatalogService>();

    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _allLoaded = false;
        _pageCursorName = null;
        _pageCursorId = null;
        _error = null;
      });
    } else {
      // Silent refresh: reset cursors and wipe raw list so we get fresh data.
      // Must be inside setState so Flutter sees a consistent snapshot.
      setState(() {
        _pageCursorName = null;
        _pageCursorId = null;
        _rawItems.clear();
        _allLoaded = false;
        _isLoadingMore = true;
      });
    }

    try {
      if (showSpinner) {
        final hasNet = await NetworkUtils.hasInternetConnection();
        if (!hasNet) throw Exception('No internet connection');
        if (mounted) setState(() => _isLoadingMore = true);
      }
      if (!mounted) return;

      // Keep fetching pages until the last one arrives.
      // _isLoadingMore is already true; we only setState per-page when new
      // data arrives to avoid triggering a rebuild on every loop iteration.
      while (mounted) {
        final page = await catalog.listItemsPage(
          limit: _pageSize,
          startAfterName: _pageCursorName,
          startAfterId: _pageCursorId,
        );

        if (!mounted) return;

        if (page.isEmpty) {
          // Last (empty) page — we're done.
          setState(() {
            _allLoaded = true;
            _isLoading = false;
            _isLoadingMore = false;
          });
          break;
        }

        _rawItems.addAll(page);

        // Advance cursor to the last item of this page.
        _pageCursorName = page.last.name;
        _pageCursorId = page.last.id;

        final isLastPage = page.length < _pageSize;

        setState(() {
          _allLoaded = isLastPage;
          _isLoading = false;
          _isLoadingMore = !isLastPage;
        });

        // Re-filter/sort after each batch so new items appear immediately.
        _applyFiltersAndSort();

        // Update the in-memory cache incrementally so other screens see partial
        // results. Persist only on the final page — repeated SharedPreferences
        // writes for hundreds of items per fetch would be wasteful.
        if (isLastPage) {
          _cache.setAndPersist<InventoryItem>(
            CacheKeys.items(null, null),
            List<InventoryItem>.from(_rawItems),
            (i) => i.toJson(),
            (i) => i.id,
            ttl: const Duration(minutes: 30),
          );
          _lastNetworkFetch = DateTime.now();
          break;
        } else {
          _cache.set(
            CacheKeys.items(null, null),
            List<InventoryItem>.from(_rawItems),
            ttl: const Duration(minutes: 30),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (showSpinner) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = e;
        });
      } else {
        debugPrint('Background items refresh error: $e');
        if (mounted) setState(() => _isLoadingMore = false);
      }
    }
  }

  // Single-pass stats calculation, memoized by list reference to avoid
  // re-iterating on every rebuild (theme changes, FAB taps, etc).
  Map<String, int> _calculateStats(List<InventoryItem> items) {
    if (identical(_statsCacheKey, items) && _statsCache != null) {
      return _statsCache!;
    }

    int assigned = 0;
    int available = 0;
    int maintenance = 0;
    for (final item in items) {
      if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
        assigned++;
      }
      final status = (item.status ?? '').toLowerCase();
      if (status == 'available') {
        available++;
      } else if (status == 'maintenance') {
        maintenance++;
      }
    }

    final stats = <String, int>{
      'total': items.length,
      'assigned': assigned,
      'available': available,
      'maintenance': maintenance,
    };
    _statsCache = stats;
    _statsCacheKey = items;
    return stats;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Items'),
        actions: [
          // View All Assets button - shows all cached items instantly
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: 'View All Assets',
            onPressed: () {
              // Load from cache instantly
              final cached = _cache.get<List<InventoryItem>>(CacheKeys.items(null, null));
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AllItemsScreen(
                    items: cached ?? _rawItems,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Bulk Print QR Codes',
            onPressed: () {
              Navigator.of(context).pushNamed(BulkQrPrintScreen.routeName);
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              _persistFilters();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshItems,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _rawItems.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SkeletonStatGrid(count: 4),
            AppSpacing.gapLg,
            const SkeletonList(itemCount: 8, itemHeight: 80),
          ],
        ),
      );
    }

    if (_error != null && _rawItems.isEmpty) {
      return NetworkUtils.isNetworkError(_error!)
          ? NetworkErrorWidget(
              error: _error!,
              onRetry: _refreshItems,
            )
          : ErrorRetryWidget(
              message: NetworkUtils.getErrorMessage(_error!),
              onRetry: _refreshItems,
            );
    }

    final items = _visibleItems;
    final stats = _calculateStats(items);

    final role = ref.watch(currentUserDataProvider).valueOrNull?.role;
    final compact = isOperatorLayoutRole(role);

    return RefreshIndicator(
      onRefresh: () async {
        _refreshItems();
      },
      child: CustomScrollView(
        // Keep ~1.5 viewports of items rendered above and below the visible
        // area so quick scrolls don't tear down image widgets and force a
        // re-decode when scrolling back. Pairs with memCacheWidth limits and
        // the 500 MB global imageCache configured in main.dart.
        cacheExtent: MediaQuery.of(context).size.height * 1.5,
        slivers: [
          // Progressive-load progress banner — only shown while loading pages.
          if (_isLoadingMore || (!_allLoaded && _rawItems.isNotEmpty))
            SliverToBoxAdapter(
              child: _LoadingProgressBanner(
                loaded: _rawItems.length,
                allLoaded: _allLoaded,
              ),
            ),
          
          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveHelper.responsivePadding(context)
                  .copyWith(bottom: AppSpacing.sm),
              child: _QuickStatsGrid(
                stats: stats,
                totalLoaded: _rawItems.length,
                allLoaded: _allLoaded,
              ),
            ),
          ),

          // Search and Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.responsivePadding(context).left,
                0,
                ResponsiveHelper.responsivePadding(context).right,
                compact ? AppSpacing.sm : ResponsiveHelper.responsiveSpacing(context),
              ),
              child: _EnhancedFiltersBar(
                searchController: _searchCtrl,
                departments: _departments,
                categories: _categories,
                selectedDeptId: _selectedDeptId,
                selectedCategoryId: _selectedCategoryId,
                selectedStatus: _selectedStatus,
                sortBy: _sortBy,
                sortAscending: _sortAscending,
                filtersExpanded: _filtersExpanded,
                onFiltersToggle: () {
                  setState(() {
                    _filtersExpanded = !_filtersExpanded;
                  });
                  _persistFilters();
                },
                onDeptChanged: (deptId) {
                  _selectedDeptId =
                      (deptId == null || deptId.isEmpty) ? null : deptId;
                  _persistFilters();
                  _applyFiltersAndSort();
                },
                onCategoryChanged: (catId) {
                  _selectedCategoryId =
                      (catId == null || catId.isEmpty) ? null : catId;
                  _persistFilters();
                  _applyFiltersAndSort();
                },
                onStatusChanged: (status) {
                  _selectedStatus =
                      (status == null || status.isEmpty) ? null : status;
                  _persistFilters();
                  _applyFiltersAndSort();
                },
                onSortChanged: (sortBy, ascending) {
                  _sortBy = sortBy;
                  _sortAscending = ascending;
                  _persistFilters();
                  _applyFiltersAndSort();
                },
                onClear: () {
                  _selectedDeptId = null;
                  _selectedCategoryId = null;
                  _selectedStatus = null;
                  _searchCtrl.clear();
                  _persistFilters();
                  _applyFiltersAndSort();
                },
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.responsivePadding(context).left,
                right: ResponsiveHelper.responsivePadding(context).right,
                bottom: AppSpacing.lg,
              ),
              child: _QuickActionsBar(
                onAddNew: () => Navigator.of(context).pushNamed('/items/add'),
                onScan: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QrScannerScreen(),
                      ),
                    ),
                onGenerateQr: () =>
                    Navigator.of(context).pushNamed(BulkQrPrintScreen.routeName),
                onBulkAssign: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BulkAssignScreen(),
                      ),
                    ),
                onAdvancedSearch: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllItemsScreen(items: items),
                    ),
                  );
                },
              ),
            ),
          ),

          // Items List/Grid
          if (items.isEmpty && !_isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No items found',
                message: _allLoaded
                    ? 'Try adjusting your filters or add a new item.'
                    : 'Still loading items, try again in a moment.',
                action: _allLoaded
                    ? FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/items/add'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add First Item'),
                      )
                    : null,
              ),
            )
          else if (_isGridView)
            SliverPadding(
              padding: ResponsiveHelper.responsivePadding(context),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveHelper.gridColumns(context),
                  crossAxisSpacing: ResponsiveHelper.responsiveSpacing(context),
                  mainAxisSpacing: ResponsiveHelper.responsiveSpacing(context),
                  childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.75 : 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= items.length) return null;
                    final item = items[index];
                    return RepaintBoundary(
                      key: ValueKey(item.id),
                      child: _ItemCard(
                        item: item,
                        departmentLabel: _departmentLabelFor(item),
                        categoryLabel: _categoryLabelFor(item),
                      ),
                    );
                  },
                  childCount: items.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  findChildIndexCallback: (key) {
                    if (key is ValueKey<String>) {
                      final idx = items.indexWhere((i) => i.id == key.value);
                      return idx >= 0 ? idx : null;
                    }
                    return null;
                  },
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.responsivePadding(context).left,
                right: ResponsiveHelper.responsivePadding(context).right,
                top: AppSpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= items.length) return null;
                    final item = items[index];
                    return RepaintBoundary(
                      key: ValueKey(item.id),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.responsiveSpacing(context),
                        ),
                        child: _EnhancedItemCard(
                          item: item,
                          departmentLabel: _departmentLabelFor(item),
                          categoryLabel: _categoryLabelFor(item),
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  findChildIndexCallback: (key) {
                    if (key is ValueKey<String>) {
                      final idx = items.indexWhere((i) => i.id == key.value);
                      return idx >= 0 ? idx : null;
                    }
                    return null;
                  },
                ),
              ),
            ),

          // Bottom footer: shows "loaded X items" once all pages arrive.
          SliverToBoxAdapter(
            child: _ListFooter(
              loaded: _rawItems.length,
              visible: items.length,
              allLoaded: _allLoaded,
              isLoading: _isLoadingMore,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  rootShellTabScrollBottomInset(context, compact: compact),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({
    required this.stats,
    required this.totalLoaded,
    required this.allLoaded,
  });

  final Map<String, int> stats;
  final int totalLoaded;
  final bool allLoaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statItems = [
      _StatItem(
        'Total${allLoaded ? '' : '+'}',
        stats['total'] ?? 0,
        Icons.inventory_2,
        theme.colorScheme.primary,
      ),
      _StatItem('Assigned', stats['assigned'] ?? 0, Icons.person, AppTheme.statusAssigned),
      _StatItem('Available', stats['available'] ?? 0, Icons.check_circle, AppTheme.statusAvailable),
      _StatItem('Maintenance', stats['maintenance'] ?? 0, Icons.build, AppTheme.statusMaintenance),
    ];

    final cross = ResponsiveHelper.metricsGridColumns(context);
    final spacing = ResponsiveHelper.responsiveSpacing(context);
    final aspect = ResponsiveHelper.isMobile(context) ? 1.3 : 1.4;

    // Shrink-wrapped GridView inside a sliver can over-report height and leave
    // a large blank band before the next sliver. Pin exact height instead.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final tileW = (maxW - spacing * (cross - 1)) / cross;
        final tileH = tileW / aspect;
        final rows = (statItems.length / cross).ceil();
        final gridH =
            rows * tileH + (rows > 1 ? (rows - 1) * spacing : 0);

        return SizedBox(
          height: gridH,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: tileH,
            ),
            itemCount: statItems.length,
            itemBuilder: (context, index) {
              final item = statItems[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(ResponsiveHelper.borderRadius(context)),
                ),
                child: Padding(
                  padding: ResponsiveHelper.cardPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: ResponsiveHelper.iconSize(context, baseSize: 28),
                        color: item.color,
                      ),
                      SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                      Text(
                        '${item.value}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: item.color,
                              fontSize:
                                  ResponsiveHelper.isMobile(context) ? 18 : 22,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize:
                                  ResponsiveHelper.isMobile(context) ? 11 : 12,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

// ── Loading progress banner ──────────────────────────────────────────────────

class _LoadingProgressBanner extends StatelessWidget {
  const _LoadingProgressBanner({
    required this.loaded,
    required this.allLoaded,
  });

  final int loaded;
  final bool allLoaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading items… $loaded loaded so far',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List footer ───────────────────────────────────────────────────────────────

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.loaded,
    required this.visible,
    required this.allLoaded,
    required this.isLoading,
  });

  final int loaded;
  final int visible;
  final bool allLoaded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String label;
    if (!allLoaded || isLoading) {
      label = 'Loading more… $loaded items so far';
    } else if (visible < loaded) {
      label = 'Showing $visible of $loaded items';
    } else {
      label = '$loaded items total';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!allLoaded || isLoading) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedFiltersBar extends StatelessWidget {
  const _EnhancedFiltersBar({
    required this.searchController,
    required this.departments,
    required this.categories,
    required this.selectedDeptId,
    required this.selectedCategoryId,
    required this.selectedStatus,
    required this.sortBy,
    required this.sortAscending,
    required this.filtersExpanded,
    required this.onFiltersToggle,
    required this.onDeptChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final List<Department> departments;
  final List<Category> categories;
  final String? selectedDeptId;
  final String? selectedCategoryId;
  final String? selectedStatus;
  final String sortBy;
  final bool sortAscending;
  final bool filtersExpanded;
  final VoidCallback onFiltersToggle;
  final ValueChanged<String?> onDeptChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final void Function(String, bool) onSortChanged;
  final VoidCallback onClear;

  static const _statusOptions = <String>['', 'available', 'assigned', 'maintenance', 'retired'];
  static const _sortOptions = <String>['name', 'assetId', 'status', 'purchaseDate'];

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedDeptId != null ||
        selectedCategoryId != null ||
        selectedStatus != null ||
        searchController.text.trim().isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context)),
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: ResponsiveHelper.cardPadding(context),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search items...',
                      hintText: 'Search by name, asset ID, or description',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(filtersExpanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: filtersExpanded ? 'Hide Filters' : 'Show Filters',
                  onPressed: onFiltersToggle,
                ),
                if (hasActiveFilters)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear All Filters',
                    onPressed: onClear,
                    color: Theme.of(context).colorScheme.error,
                  ),
              ],
            ),
          ),

          // Filters (Collapsible)
          if (filtersExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: ResponsiveHelper.cardPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters & Sort',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: ResponsiveHelper.isMobile(context) ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: selectedDeptId ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem(value: '', child: Text('All Departments')),
                            ...departments.map(
                              (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                            ),
                          ],
                          onChanged: onDeptChanged,
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.isMobile(context) ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: selectedCategoryId ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem(value: '', child: Text('All Categories')),
                            ...categories.map(
                              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                            ),
                          ],
                          onChanged: onCategoryChanged,
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.isMobile(context) ? double.infinity : 180,
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: _statusOptions
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.isEmpty ? 'All Statuses' : s.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: onStatusChanged,
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.isMobile(context) ? double.infinity : 180,
                        child: DropdownButtonFormField<String>(
                          value: sortBy,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sort By',
                            border: OutlineInputBorder(),
                          ),
                          items: _sortOptions
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s == 'purchaseDate'
                                      ? 'Purchase Date'
                                      : s.substring(0, 1).toUpperCase() + s.substring(1)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              onSortChanged(value, sortAscending);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                        tooltip: sortAscending ? 'Ascending' : 'Descending',
                        onPressed: () {
                          onSortChanged(sortBy, !sortAscending);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({
    required this.onAddNew,
    required this.onScan,
    required this.onGenerateQr,
    required this.onBulkAssign,
    required this.onAdvancedSearch,
  });

  final VoidCallback onAddNew;
  final VoidCallback onScan;
  final VoidCallback onGenerateQr;
  final VoidCallback onBulkAssign;
  final VoidCallback onAdvancedSearch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ResponsiveHelper.responsiveSpacing(context),
      runSpacing: ResponsiveHelper.responsiveSpacing(context),
      children: [
        FilledButton.icon(
          onPressed: onAddNew,
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
              vertical: 12,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
              vertical: 12,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAdvancedSearch,
          icon: const Icon(Icons.search),
          label: const Text('Advanced Search'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
              vertical: 12,
            ),
          ),
        ),
        if (!ResponsiveHelper.isMobile(context))
          OutlinedButton.icon(
            onPressed: onGenerateQr,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Generate QR'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ItemManagementOnly(
          child: OutlinedButton.icon(
            onPressed: onBulkAssign,
            icon: const Icon(Icons.grid_view),
            label: const Text('Bulk Assign'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.departmentLabel,
    required this.categoryLabel,
  });

  final InventoryItem item;
  final String departmentLabel;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = context.getStatusColor(item.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          final imageUrl = item.thumbnailUrl!;
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            cacheManager: _imageCacheManager,
                            // Decode at most ~400px wide so the in-memory
                            // bitmap is small enough that 1000s of items fit
                            // in PaintingBinding.imageCache (configured to
                            // 500MB in main.dart). Without this, each thumb
                            // can be 5+MB decoded and quickly evicts others.
                            memCacheWidth: 400,
                            // Keep showing the previously-decoded image when
                            // the widget is rebuilt — prevents the flash
                            // back to the placeholder when scrolling away
                            // and returning to the same item.
                            useOldImageOnUrlChange: true,
                            httpHeaders: const {
                              'Cache-Control': 'max-age=86400', // 24 hours
                            },
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 32,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Image failed',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            // No fade — already-cached images should appear
                            // instantly with no visible animation when the
                            // user scrolls back to a previously-seen item.
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: ResponsiveHelper.cardPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.assetId,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (departmentLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment,
                                size: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  departmentLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (categoryLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category,
                                size: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  categoryLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (item.assignedTo != null && item.assignedTo!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 12,
                                color: AppTheme.statusAssigned,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.assignedTo!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.statusAssigned,
                                        fontSize: 11,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: context.getStatusBgColor(item.status),
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Text(
                            (item.status ?? 'Unknown')
                                .substring(0, 1)
                                .toUpperCase() +
                                (item.status ?? 'Unknown').substring(1),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedItemCard extends StatelessWidget {
  const _EnhancedItemCard({
    required this.item,
    required this.departmentLabel,
    required this.categoryLabel,
  });

  final InventoryItem item;
  final String departmentLabel;
  final String categoryLabel;

  Color _getStatusColor(BuildContext context, String? status) {
    return context.getStatusColor(status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, item.status);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: Padding(
          padding: ResponsiveHelper.cardPadding(context),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          final imageUrl = item.thumbnailUrl!;
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            cacheManager: _imageCacheManager,
                            // List thumbs render at 80x80; decode at 2x retina
                            // so each in-memory bitmap is ~50KB instead of MBs.
                            memCacheWidth: 160,
                            memCacheHeight: 160,
                            useOldImageOnUrlChange: true,
                            // Instant when re-entering view from scroll.
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            httpHeaders: const {
                              'Cache-Control': 'max-age=2592000', // 30 days
                            },
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: theme.colorScheme.error,
                                  size: 24,
                                ),
                              );
                            },
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.inventory_2,
                          color: theme.colorScheme.outline,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(
                          label: Text(
                            (item.status ?? 'Unknown').substring(0, 1).toUpperCase() +
                                (item.status ?? 'Unknown').substring(1),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: context.getStatusBgColor(item.status),
                          labelStyle: TextStyle(color: statusColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asset ID: ${item.assetId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (departmentLabel.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.apartment, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                departmentLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        if (categoryLabel.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                categoryLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        if (item.assignedTo != null && item.assignedTo!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 14, color: AppTheme.statusAssigned),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.assignedTo!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.statusAssigned,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (item.purchaseDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatDateShort(item.purchaseDate),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
