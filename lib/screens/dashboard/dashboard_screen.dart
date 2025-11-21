import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../utils/network_utils.dart';
import '../../widgets/charts/enhanced_dashboard_charts.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';
import '../items/all_items_screen.dart';
import '../items/bulk_assign_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 56, 16, 16),
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
          final data = snapshot.data ?? const _DashboardData.empty();
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadDashboardData();
              });
              await _dashboardFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operator Dashboard',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _OverviewGrid(data: data),
                  const SizedBox(height: 24),
                  EnhancedDashboardCharts(
                    items: data.items,
                    departments: data.departments,
                    history: data.recentHistory,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(data: data),
                  const SizedBox(height: 24),
                  Text(
                    'My Recent Activity',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _RecentActivityList(entries: data.recentHistory),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<_DashboardData> _loadDashboardData() async {
    try {
      // Check network connection first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection');
      }

      final catalog = context.read<CatalogService>();
      final issueService = context.read<IssueService>();
      final historyService = context.read<HistoryService>();
      final deptService = context.read<DepartmentService>();

      final items = await catalog.listAllItems(pageSize: 500);
      final issues = await issueService.listOpenIssues(limit: 20);
      final history = await historyService.recentHistory(limit: 6);
      final departments = await deptService.listDepartments(includeInactive: false);

      final total = items.length;
      final assigned = items
          .where((item) => (item.assignedTo != null && item.assignedTo!.isNotEmpty))
          .length;
      final tagged = items
          .where((item) => (item.qrCodeUrl != null && item.qrCodeUrl!.isNotEmpty))
          .length;
      final unassigned = total - assigned;

      return _DashboardData(
        items: items,
        totalItems: total,
        assignedItems: assigned,
        unassignedItems: unassigned,
        taggedItems: tagged,
        issuesCount: issues.length,
        remindersCount: 0,
        recentHistory: history,
        departments: departments,
      );
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      rethrow;
    }
  }
}

class _DashboardData {
  const _DashboardData({
    required this.items,
    required this.totalItems,
    required this.assignedItems,
    required this.unassignedItems,
    required this.taggedItems,
    required this.issuesCount,
    required this.remindersCount,
    required this.recentHistory,
    this.departments = const [],
  });

  const _DashboardData.empty()
      : items = const [],
        totalItems = 0,
        assignedItems = 0,
        unassignedItems = 0,
        taggedItems = 0,
        issuesCount = 0,
        remindersCount = 0,
        recentHistory = const [],
        departments = const [];

  final List<InventoryItem> items;
  final int totalItems;
  final int assignedItems;
  final int unassignedItems;
  final int taggedItems;
  final int issuesCount;
  final int remindersCount;
  final List<HistoryEntry> recentHistory;
  final List<Department> departments;
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatConfig(
        label: 'Total Items',
        value: data.totalItems.toString(),
        icon: Icons.inventory_2,
        color: Colors.blue,
      ),
      _StatConfig(
        label: 'Assigned Items',
        value: data.assignedItems.toString(),
        icon: Icons.location_on,
        color: Colors.green,
      ),
      _StatConfig(
        label: 'Unassigned Items',
        value: data.unassignedItems.toString(),
        icon: Icons.push_pin_outlined,
        color: Colors.orange,
      ),
      _StatConfig(
        label: 'Tagged Items',
        value: data.taggedItems.toString(),
        icon: Icons.qr_code,
        color: Colors.purple,
      ),
      _StatConfig(
        label: 'Issues',
        value: data.issuesCount.toString(),
        icon: Icons.warning_amber_outlined,
        color: Colors.red,
      ),
      _StatConfig(
        label: 'Reminders',
        value: data.remindersCount.toString(),
        icon: Icons.notifications_active_outlined,
        color: Colors.teal,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(stat.icon, size: 32, color: stat.color),
                const SizedBox(height: 12),
                Text(
                  stat.value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Add Item',
        icon: Icons.add_box_outlined,
        color: Colors.green,
        onTap: () => Navigator.of(context).pushNamed('/items/add'),
      ),
      _QuickAction(
        label: 'View Pending',
        icon: Icons.list_alt_outlined,
        color: Colors.deepPurple,
        onTap: () => Navigator.of(context).pushNamed('/approvals'),
      ),
      _QuickAction(
        label: 'View All',
        icon: Icons.view_list,
        color: Colors.blue,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AllItemsScreen(items: data.items),
            ),
          );
        },
      ),
      _QuickAction(
        label: 'Bulk Assign',
        icon: Icons.grid_view,
        color: Colors.orange,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BulkAssignScreen(),
          ),
        ),
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) {
        final btn = _QuickActionButton(action: action);
        final needsManage = action.label == 'Add Item' || action.label == 'Bulk Assign';
        return needsManage ? ItemManagementOnly(child: btn) : btn;
      }).toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 600
          ? 220
          : (MediaQuery.of(context).size.width - 52) / 2,
      child: OutlinedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, color: action.color),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No recent activity.')),
        ),
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(entry.action),
                subtitle: Text(entry.notes ?? entry.itemId),
                trailing: Text(
                  entry.timestamp?.toLocal().toString().split(' ').first ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatConfig {
  const _StatConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
