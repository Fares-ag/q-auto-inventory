import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/auth_session_service.dart';
import '../../services/firebase_services.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';
import '../../utils/network_utils.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/charts/enhanced_dashboard_charts.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';
import '../auth/login_screen.dart';
import '../items/item_detail_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

// Static shortcuts list - created once, reused
// Note: Using final instead of const to allow hot reload compatibility
final _shortcuts = <_ShortcutAction>[
  _ShortcutAction(
    label: 'Departments',
    icon: Icons.apartment,
    route: '/admin/departments',
  ),
  _ShortcutAction(
    label: 'Categories',
    icon: Icons.category,
    route: '/admin/categories',
  ),
  _ShortcutAction(
    label: 'Permissions',
    icon: Icons.shield_outlined,
    route: '/admin/permissions',
  ),
  _ShortcutAction(
    label: 'Staff',
    icon: Icons.group_outlined,
    route: '/admin/staff',
  ),
  _ShortcutAction(
    label: 'User Management',
    icon: Icons.people_outlined,
    route: '/admin/users',
  ),
  _ShortcutAction(
    label: 'Approvals',
    icon: Icons.approval,
    route: '/approvals',
  ),
  _ShortcutAction(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    route: '/admin/analytics',
  ),
  _ShortcutAction(
    label: 'Reports',
    icon: Icons.bar_chart,
    route: '/reports',
  ),
  _ShortcutAction(
    label: 'Import Excel',
    icon: Icons.upload_file,
    route: '/admin/import',
  ),
  _ShortcutAction(
    label: 'Data Audit',
    icon: Icons.query_stats_outlined,
    route: '/admin/data-audit',
  ),
  _ShortcutAction(
    label: 'Locations',
    icon: Icons.place_outlined,
    route: '/admin/locations',
  ),
  _ShortcutAction(
    label: 'System Settings',
    icon: Icons.tune_outlined,
    route: '/admin/system-settings',
  ),
  _ShortcutAction(
    label: 'Vehicle Check-outs',
    icon: Icons.directions_car_outlined,
    route: '/admin/vehicle-checkouts',
  ),
  _ShortcutAction(
    label: 'Vehicle Maintenance',
    icon: Icons.build_outlined,
    route: '/admin/vehicle-maintenance',
  ),
];

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  Future<_SuperAdminData>? _dashboardFuture;
  String? _selectedDepartment;
  String? _selectedStaff;

  // Memoized computed values
  List<InventoryItem>? _cachedFilteredItems;
  List<String>? _cachedUniqueDepartments;
  List<String>? _cachedUniqueStaff;
  String? _lastDepartmentFilter;
  String? _lastStaffFilter;
  _SuperAdminData? _lastData;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        // Try disk cache first for an instant first paint, then trigger the
        // full network load in the background.
        _loadFromDiskFirst();
      }
    });
  }

  Future<void> _loadFromDiskFirst() async {
    if (!mounted || !context.mounted) return;
    final catalog = context.read<CatalogService>();
    final departmentService = context.read<DepartmentService>();
    final issueService = context.read<IssueService>();
    final historyService = context.read<HistoryService>();

    // Tier 1: Firestore disk cache - returns instantly on second-and-later
    // launches. We load only the cheap pieces from disk so the dashboard
    // can render structure + counts while the heavier server fetch runs.
    final diskFutures = await Future.wait([
      catalog.listAllItemsFromDisk(),
      departmentService.listDepartmentsFromDisk(includeInactive: true),
      issueService.listOpenIssuesFromDisk(limit: 30),
      historyService.recentHistoryFromDisk(limit: 20),
    ]);
    final diskItems = diskFutures[0] as List<InventoryItem>;
    if (diskItems.isNotEmpty && mounted) {
      final diskDepts = diskFutures[1] as List<Department>;
      final diskIssues = diskFutures[2] as List<Issue>;
      final diskHistory = diskFutures[3] as List<HistoryEntry>;
      setState(() {
        _dashboardFuture = Future.value(
          _buildDashboardData(diskItems, diskDepts, const [], const [],
              diskIssues, diskHistory),
        );
      });
    }

    if (!mounted) return;
    // Tier 2: full server load runs in background and replaces the data.
    final serverFuture = _loadDashboardData();
    if (mounted) {
      setState(() => _dashboardFuture = serverFuture);
    }
  }

  Future<_SuperAdminData> _loadDashboardData() async {
    final catalog = context.read<CatalogService>();
    final departmentService = context.read<DepartmentService>();
    final staffService = context.read<StaffService>();
    final issueService = context.read<IssueService>();
    final historyService = context.read<HistoryService>();

    final results = await Future.wait([
      catalog.listAllItems(pageSize: 100),
      departmentService.listDepartments(includeInactive: true),
      catalog.listCategories(includeInactive: true),
      staffService.listStaff(activeOnly: false),
      issueService.listOpenIssues(limit: 30),
      historyService.recentHistory(limit: 20),
    ]);

    final items = results[0] as List<InventoryItem>;
    final departments = results[1] as List<Department>;
    final categories = results[2] as List<Category>;
    final staff = results[3] as List<StaffMember>;
    final issues = results[4] as List<Issue>;
    final history = results[5] as List<HistoryEntry>;
    return _buildDashboardData(
        items, departments, categories, staff, issues, history);
  }

  _SuperAdminData _buildDashboardData(
    List<InventoryItem> items,
    List<Department> departments,
    List<Category> categories,
    List<StaffMember> staff,
    List<Issue> issues,
    List<HistoryEntry> history,
  ) {

    // Optimized single-pass calculation instead of multiple where() calls
    int tagged = 0;
    int unassigned = 0;
    final categoryCounts = <String, int>{};
    final departmentCounts = <String, int>{};
    final staffCounts = <String, int>{};

    // Single pass through items for O(n) instead of O(2n + 3n)
    for (final item in items) {
      // Count tagged items
      if (item.qrCodeUrl != null && item.qrCodeUrl!.isNotEmpty) {
        tagged++;
      }
      // Count unassigned items
      if (item.assignedTo == null || item.assignedTo!.isEmpty) {
        unassigned++;
      }
      // Count by category
      categoryCounts.update(item.categoryId, (value) => value + 1,
          ifAbsent: () => 1);
      // Count by department
      final departmentKey =
          item.departmentId.isEmpty ? 'Unassigned' : item.departmentId;
      departmentCounts.update(departmentKey, (value) => value + 1,
          ifAbsent: () => 1);
      // Count by staff
      if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
        staffCounts.update(item.assignedTo!, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }

    return _SuperAdminData(
      items: items,
      departments: departments,
      categories: categories,
      staff: staff,
      history: history,
      issuesCount: issues.length,
      taggedItems: tagged,
      unassignedItems: unassigned,
      categoryCounts: categoryCounts,
      departmentCounts: departmentCounts,
      staffCounts: staffCounts,
    );
  }

  void _openRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  // Memoized computation for filtered items
  List<InventoryItem> _getFilteredItems(_SuperAdminData data) {
    // Check if we can use cached result
    if (_cachedFilteredItems != null &&
        _lastData == data &&
        _lastDepartmentFilter == _selectedDepartment &&
        _lastStaffFilter == _selectedStaff) {
      return _cachedFilteredItems!;
    }

    // Compute filtered items
    final filtered = data.items.where((item) {
      final matchesDept = _selectedDepartment == null ||
          _selectedDepartment == 'All' ||
          item.departmentId == _selectedDepartment;
      final matchesStaff = _selectedStaff == null ||
          _selectedStaff == 'All' ||
          item.assignedTo == _selectedStaff;
      return matchesDept && matchesStaff;
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Cache the result
    _cachedFilteredItems = filtered;
    _lastDepartmentFilter = _selectedDepartment;
    _lastStaffFilter = _selectedStaff;
    _lastData = data;

    return filtered;
  }

  // Memoized computation for unique departments
  List<String> _getUniqueDepartments(_SuperAdminData data) {
    if (_cachedUniqueDepartments != null && _lastData == data) {
      return _cachedUniqueDepartments!;
    }
    final unique = ['All', ...data.departmentCounts.keys.toList()..sort()];
    _cachedUniqueDepartments = unique;
    return unique;
  }

  // Memoized computation for unique staff
  List<String> _getUniqueStaff(_SuperAdminData data) {
    if (_cachedUniqueStaff != null && _lastData == data) {
      return _cachedUniqueStaff!;
    }
    final unique = ['All', ...data.staffCounts.keys.toList()..sort()];
    _cachedUniqueStaff = unique;
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Super Admin Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await signOutAndClearSession(
                  permissionService: context.read<PermissionService>(),
                );
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Data Audit',
              icon: const Icon(Icons.query_stats_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/admin/data-audit'),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
            ),
          ],
        ),
        body: FutureBuilder<_SuperAdminData>(
          // Never pass a completed empty future — show skeleton while null.
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.none ||
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(itemCount: 10, itemHeight: 72),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error!;
              return NetworkUtils.isNetworkError(error)
                  ? NetworkErrorWidget(
                      error: error,
                      onRetry: () {
                        setState(() {
                          _dashboardFuture = _loadDashboardData();
                        });
                      },
                    )
                  : ErrorRetryWidget(
                      message: NetworkUtils.getErrorMessage(error),
                      onRetry: () {
                        setState(() {
                          _dashboardFuture = _loadDashboardData();
                        });
                      },
                    );
            }
            final data = snapshot.data!;

            // Use memoized computations
            final filteredItems = _getFilteredItems(data);
            final uniqueDepartments = _getUniqueDepartments(data);
            final uniqueStaff = _getUniqueStaff(data);

            // Use responsive helper for consistent breakpoints

            // Use static shortcuts list - routes are bound in build method
            final shortcuts = _shortcuts;

            return RefreshIndicator(
              onRefresh: () async {
                // Clear cache on refresh
                _cachedFilteredItems = null;
                _cachedUniqueDepartments = null;
                _cachedUniqueStaff = null;
                _lastData = null;
                setState(() {
                  _dashboardFuture = _loadDashboardData();
                });
                await _dashboardFuture;
              },
              child: ResponsiveHelper.responsiveContainer(
                context,
                ListView(
                  padding: ResponsiveHelper.responsivePadding(context),
                  children: [
                    Text('Management',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(context)),
                    Wrap(
                      spacing: ResponsiveHelper.responsiveSpacing(context),
                      runSpacing: ResponsiveHelper.responsiveSpacing(context),
                      children: shortcuts.map((action) {
                        final btn = SizedBox(
                          width: ResponsiveHelper.shortcutButtonWidth(context),
                          child: OutlinedButton.icon(
                            onPressed: () => _openRoute(action.route),
                            icon: Icon(action.icon),
                            label: Text(action.label),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.isMobile(context)
                                    ? 16
                                    : 20,
                                horizontal:
                                    ResponsiveHelper.isMobile(context) ? 8 : 12,
                              ),
                            ),
                          ),
                        );
                        // Guard shortcuts by area
                        if (action.label == 'Analytics') {
                          return AdminOnly(child: btn);
                        }
                        if (action.label == 'Reports') {
                          return ReportsOnly(child: btn);
                        }
                        if (action.label == 'Import Excel') {
                          return ItemManagementOnly(child: btn);
                        }
                        if (action.label == 'Departments') {
                          return DepartmentManagementOnly(child: btn);
                        }
                        if (action.label == 'Staff') {
                          return StaffManagementOnly(child: btn);
                        }
                        if (action.label == 'User Management') {
                          return AdminOnly(child: btn);
                        }
                        if (action.label == 'Permissions') {
                          return AdminOnly(child: btn);
                        }
                        if (action.label == 'Approvals') {
                          return ItemManagementOnly(child: btn);
                        }
                        if (action.label == 'Categories') {
                          return ItemManagementOnly(child: btn);
                        }
                        if (action.label == 'Data Audit') {
                          return AdminOnly(child: btn);
                        }
                        if (action.label == 'Locations') {
                          return DepartmentManagementOnly(child: btn);
                        }
                        if (action.label == 'System Settings') {
                          return AdminOnly(child: btn);
                        }
                        if (action.label == 'Vehicle Check-outs') {
                          return AdminOnly(child: btn);
                        }
                        if (action.label == 'Vehicle Maintenance') {
                          return AdminOnly(child: btn);
                        }
                        return btn;
                      }).toList(),
                    ),
                    SizedBox(
                        height:
                            ResponsiveHelper.responsiveSpacing(context) * 2),
                    Text('Application Insights',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(context)),
                    _StatsGrid(data: data),
                    SizedBox(
                        height:
                            ResponsiveHelper.responsiveSpacing(context) * 2),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 400;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text('Visual Analytics',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            if (!isSmall)
                              TextButton.icon(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed('/admin/analytics'),
                                icon: Icon(
                                  Icons.analytics_outlined,
                                  size: ResponsiveHelper.iconSize(context,
                                      baseSize: 18),
                                ),
                                label: const Text('View Full Analytics'),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(context)),
                    RepaintBoundary(
                      child: EnhancedDashboardCharts(
                        items: data.items,
                        departments: data.departments,
                        categories: data.categories,
                        history: data.history,
                      ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveHelper.responsiveSpacing(context) * 2),
                    Text('Filter & View Assets',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(context)),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ResponsiveHelper.borderRadius(context))),
                      child: Padding(
                        padding: ResponsiveHelper.cardPadding(context),
                        child: Column(
                          children: [
                            ResponsiveHelper.isMobile(context)
                                ? Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue:
                                            _selectedDepartment ?? 'All',
                                        items: uniqueDepartments
                                            .map((dept) =>
                                                DropdownMenuItem<String>(
                                                    value: dept,
                                                    child: Text(dept)))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedDepartment = value;
                                            _cachedFilteredItems = null;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                            labelText: 'Department'),
                                      ),
                                      SizedBox(
                                          height: ResponsiveHelper
                                              .responsiveSpacing(context)),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedStaff ?? 'All',
                                        items: uniqueStaff
                                            .map((staff) =>
                                                DropdownMenuItem<String>(
                                                    value: staff,
                                                    child: Text(staff)))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedStaff = value;
                                            _cachedFilteredItems = null;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                            labelText: 'Staff'),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue:
                                              _selectedDepartment ?? 'All',
                                          items: uniqueDepartments
                                              .map((dept) =>
                                                  DropdownMenuItem<String>(
                                                      value: dept,
                                                      child: Text(dept)))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedDepartment = value;
                                              _cachedFilteredItems = null;
                                            });
                                          },
                                          decoration: const InputDecoration(
                                              labelText: 'Department'),
                                        ),
                                      ),
                                      SizedBox(
                                          width: ResponsiveHelper
                                              .responsiveSpacing(context)),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedStaff ?? 'All',
                                          items: uniqueStaff
                                              .map((staff) =>
                                                  DropdownMenuItem<String>(
                                                      value: staff,
                                                      child: Text(staff)))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedStaff = value;
                                              _cachedFilteredItems = null;
                                            });
                                          },
                                          decoration: const InputDecoration(
                                              labelText: 'Staff'),
                                        ),
                                      ),
                                    ],
                                  ),
                            SizedBox(
                                height: ResponsiveHelper.responsiveSpacing(
                                        context) *
                                    2),
                            ...filteredItems.take(5).map((item) => ListTile(
                                  leading:
                                      const Icon(Icons.inventory_2_outlined),
                                  title: Text(item.name),
                                  subtitle: Text(
                                      'Dept: ${item.departmentId.isEmpty ? 'Unassigned' : item.departmentId} | Assigned: ${item.assignedTo?.isNotEmpty == true ? item.assignedTo : 'None'}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ItemDetailScreen(item: item)),
                                    );
                                  },
                                )),
                            if (filteredItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                    'No assets match the current filters.'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final _SuperAdminData data;

  @override
  Widget build(BuildContext context) {
    final assigned = data.items.length - data.unassignedItems;
    final stats = [
      _StatTile(label: 'Total Items', value: data.items.length.toString(),
          icon: Icons.inventory_2_rounded, color: AppTheme.primary, bg: AppTheme.primaryContainer),
      _StatTile(label: 'Total Staff', value: data.staff.length.toString(),
          icon: Icons.people_alt_rounded, color: AppTheme.info, bg: AppTheme.infoContainer),
      _StatTile(label: 'Departments', value: data.departments.length.toString(),
          icon: Icons.business_rounded, color: AppTheme.success, bg: AppTheme.successContainer),
      _StatTile(label: 'Assigned', value: assigned.toString(),
          icon: Icons.assignment_turned_in_rounded, color: AppTheme.statusAssigned, bg: AppTheme.statusAssignedBg),
      _StatTile(label: 'Unassigned', value: data.unassignedItems.toString(),
          icon: Icons.inbox_rounded, color: AppTheme.warning, bg: AppTheme.warningContainer),
      _StatTile(label: 'Tagged', value: data.taggedItems.toString(),
          icon: Icons.qr_code_2_rounded, color: AppTheme.statusPending, bg: AppTheme.statusPendingBg),
      _StatTile(label: 'Open Issues', value: data.issuesCount.toString(),
          icon: Icons.warning_amber_rounded, color: AppTheme.error, bg: AppTheme.errorContainer),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.metricsGridColumns(context),
        mainAxisSpacing: ResponsiveHelper.responsiveSpacing(context),
        crossAxisSpacing: ResponsiveHelper.responsiveSpacing(context),
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.5 : 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                BorderRadius.circular(ResponsiveHelper.borderRadius(context)),
            border: Border.all(color: AppTheme.lightBorder, width: 1),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Padding(
            padding: ResponsiveHelper.cardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(color: s.bg, borderRadius: AppSpacing.roundedMd),
                  child: Icon(s.icon, size: 20, color: s.color),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(s.value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700, color: s.color)),
                const SizedBox(height: 2),
                Text(s.label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatTile {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
}

class _ShortcutAction {
  _ShortcutAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _SuperAdminData {
  const _SuperAdminData({
    required this.items,
    required this.departments,
    required this.categories,
    required this.staff,
    required this.history,
    required this.issuesCount,
    required this.taggedItems,
    required this.unassignedItems,
    required this.categoryCounts,
    required this.departmentCounts,
    required this.staffCounts,
  });

  final List<InventoryItem> items;
  final List<Department> departments;
  final List<Category> categories;
  final List<StaffMember> staff;
  final List<HistoryEntry> history;
  final int issuesCount;
  final int taggedItems;
  final int unassignedItems;
  final Map<String, int> categoryCounts;
  final Map<String, int> departmentCounts;
  final Map<String, int> staffCounts;
}
