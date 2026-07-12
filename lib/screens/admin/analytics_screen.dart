import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/network_utils.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/charts/enhanced_dashboard_charts.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../widgets/skeleton_list.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<_AnalyticsData> _analyticsFuture;
  String _selectedTimeRange = '30d'; // 7d, 30d, 90d, 1y, all

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalyticsData();
  }

  Future<_AnalyticsData> _loadAnalyticsData() async {
    final catalog = context.read<CatalogService>();
    final departmentService = context.read<DepartmentService>();
    final staffService = context.read<StaffService>();
    final historyService = context.read<HistoryService>();
    final issueService = context.read<IssueService>();

    // Load all data
    final items = await catalog.listAllItems(pageSize: 500); // Reduced from 10000 to minimize memory
    final departments = await departmentService.listDepartments(includeInactive: true);
    final categories = await catalog.listCategories(includeInactive: true);
    final staff = await staffService.listStaff(activeOnly: false);
    final issues = await issueService.listOpenIssues(limit: 200); // Reduced from 1000
    
    // Load history for trends - get recent history with large limit
    // Note: For production, consider adding pagination or date-range queries
    final allHistory = await historyService.recentHistory(limit: 500); // Reduced from 5000
    
    // Filter history by time range
    final now = DateTime.now();
    final filteredHistory = _filterHistoryByTimeRange(allHistory, now);

    // Calculate analytics
    final categoryCounts = <String, int>{};
    final departmentCounts = <String, int>{};
    final statusCounts = <String, int>{};
    final staffCounts = <String, int>{};
    final locationCounts = <String, int>{};
    final valueByDepartment = <String, double>{};
    final valueByCategory = <String, double>{};
    
    // Daily activity for trends
    final dailyActivity = <String, int>{};
    final dailyCheckIns = <String, int>{};
    final dailyCheckOuts = <String, int>{};
    
    // Monthly trends
    final monthlyActivity = <String, int>{};
    
    // Staff activity
    final staffActivity = <String, int>{};
    
    // Process items
    for (final item in items) {
      // Category counts
      final categoryKey = item.categoryId.isEmpty ? 'Uncategorized' : item.categoryId;
      categoryCounts.update(categoryKey, (value) => value + 1, ifAbsent: () => 1);
      
      // Department counts
      final deptKey = item.departmentId.isEmpty ? 'Unassigned' : item.departmentId;
      departmentCounts.update(deptKey, (value) => value + 1, ifAbsent: () => 1);
      
      // Status counts
      final statusKey = item.status ?? 'unknown';
      statusCounts.update(statusKey, (value) => value + 1, ifAbsent: () => 1);
      
      // Staff counts
      if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
        staffCounts.update(item.assignedTo!, (value) => value + 1, ifAbsent: () => 1);
      }
      
      // Location counts
      if (item.locationId != null && item.locationId!.isNotEmpty) {
        locationCounts.update(item.locationId!, (value) => value + 1, ifAbsent: () => 1);
      }
      
      // Value calculations
      final value = item.purchasePrice ?? 0.0;
      if (value > 0) {
        valueByDepartment.update(deptKey, (v) => v + value, ifAbsent: () => value);
        valueByCategory.update(categoryKey, (v) => v + value, ifAbsent: () => value);
      }
    }
    
    // Process history for trends
    for (final entry in filteredHistory) {
      if (entry.timestamp == null) continue;
      
      final date = entry.timestamp!.toLocal();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      // Daily activity
      dailyActivity.update(dateKey, (v) => v + 1, ifAbsent: () => 1);
      
      // Monthly activity
      monthlyActivity.update(monthKey, (v) => v + 1, ifAbsent: () => 1);
      
      // Check-in/Check-out
      if (entry.action == 'check_in') {
        dailyCheckIns.update(dateKey, (v) => v + 1, ifAbsent: () => 1);
      } else if (entry.action == 'check_out') {
        dailyCheckOuts.update(dateKey, (v) => v + 1, ifAbsent: () => 1);
      }
      
      // Staff activity
      staffActivity.update(entry.actorId, (v) => v + 1, ifAbsent: () => 1);
    }

    return _AnalyticsData(
      items: items,
      departments: departments,
      categories: categories,
      staff: staff,
      history: filteredHistory,
      issues: issues,
      categoryCounts: categoryCounts,
      departmentCounts: departmentCounts,
      statusCounts: statusCounts,
      staffCounts: staffCounts,
      locationCounts: locationCounts,
      valueByDepartment: valueByDepartment,
      valueByCategory: valueByCategory,
      dailyActivity: dailyActivity,
      dailyCheckIns: dailyCheckIns,
      dailyCheckOuts: dailyCheckOuts,
      monthlyActivity: monthlyActivity,
      staffActivity: staffActivity,
    );
  }

  List<HistoryEntry> _filterHistoryByTimeRange(List<HistoryEntry> history, DateTime now) {
    Duration? range;
    switch (_selectedTimeRange) {
      case '7d':
        range = const Duration(days: 7);
        break;
      case '30d':
        range = const Duration(days: 30);
        break;
      case '90d':
        range = const Duration(days: 90);
        break;
      case '1y':
        range = const Duration(days: 365);
        break;
      case 'all':
      default:
        return history;
    }
    
    final cutoff = now.subtract(range);
    return history.where((entry) {
      return entry.timestamp != null && entry.timestamp!.isAfter(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _analyticsFuture = _loadAnalyticsData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<_AnalyticsData>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                        _analyticsFuture = _loadAnalyticsData();
                      });
                    },
                  )
                : ErrorRetryWidget(
                    message: NetworkUtils.getErrorMessage(error),
                    onRetry: () {
                      setState(() {
                        _analyticsFuture = _loadAnalyticsData();
                      });
                    },
                  );
          }
          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _analyticsFuture = _loadAnalyticsData();
              });
              await _analyticsFuture;
            },
            child: ResponsiveHelper.responsiveContainer(
              context,
              ListView(
                padding: ResponsiveHelper.responsivePadding(context),
                children: [
                  // Time Range Selector
                  Card(
                    child: Padding(
                      padding: ResponsiveHelper.cardPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Range',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmall = constraints.maxWidth < 400;
                              return SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(
                                    value: '7d',
                                    label: Text(isSmall ? '7D' : '7 Days'),
                                  ),
                                  ButtonSegment(
                                    value: '30d',
                                    label: Text(isSmall ? '30D' : '30 Days'),
                                  ),
                                  ButtonSegment(
                                    value: '90d',
                                    label: Text(isSmall ? '90D' : '90 Days'),
                                  ),
                                  ButtonSegment(
                                    value: '1y',
                                    label: Text(isSmall ? '1Y' : '1 Year'),
                                  ),
                                  ButtonSegment(
                                    value: 'all',
                                    label: Text(isSmall ? 'All' : 'All Time'),
                                  ),
                                ],
                                selected: {_selectedTimeRange},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _selectedTimeRange = newSelection.first;
                                    _analyticsFuture = _loadAnalyticsData();
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                
                // Key Metrics
                Text(
                  'Key Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                _KeyMetricsGrid(data: data),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                
                // Enhanced Charts
                Text(
                  'Visual Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                EnhancedDashboardCharts(
                  items: data.items,
                  departments: data.departments,
                  categories: data.categories,
                  history: data.history,
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                
                // Activity Trends
                Text(
                  'Activity Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                _ActivityTrendsChart(
                  dailyActivity: data.dailyActivity,
                  dailyCheckIns: data.dailyCheckIns,
                  dailyCheckOuts: data.dailyCheckOuts,
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                
                // Monthly Trends
                _MonthlyTrendsChart(monthlyActivity: data.monthlyActivity),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                
                // Asset Value Analytics
                if (data.valueByDepartment.isNotEmpty || data.valueByCategory.isNotEmpty) ...[
                  Text(
                    'Asset Value Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                  _ValueByDepartmentChart(valueByDepartment: data.valueByDepartment),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                  _ValueByCategoryChart(valueByCategory: data.valueByCategory),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                ],
                
                // Staff Activity
                if (data.staffActivity.isNotEmpty) ...[
                  Text(
                    'Staff Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                  _StaffActivityChart(
                    staffActivity: data.staffActivity,
                    staff: data.staff,
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                ],
                
                // Location Distribution
                if (data.locationCounts.isNotEmpty) ...[
                  Text(
                    'Location Distribution',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                  _LocationDistributionChart(locationCounts: data.locationCounts),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                ],
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}

class _KeyMetricsGrid extends StatelessWidget {
  const _KeyMetricsGrid({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final totalValue = data.valueByDepartment.values.fold<double>(0.0, (sum, val) => sum + val);
    final avgValuePerItem = data.items.isNotEmpty ? totalValue / data.items.length : 0.0;
    final activityCount = data.dailyActivity.values.fold<int>(0, (sum, val) => sum + val);
    final checkInCount = data.dailyCheckIns.values.fold<int>(0, (sum, val) => sum + val);
    final checkOutCount = data.dailyCheckOuts.values.fold<int>(0, (sum, val) => sum + val);
    
    final colors = AppTheme.chartColors;
    final metrics = [
      _MetricTile(
        label: 'Total Assets',
        value: data.items.length.toString(),
        icon: Icons.inventory_2,
        color: colors[0],
      ),
      _MetricTile(
        label: 'Total Value',
        value: '\$${totalValue.toStringAsFixed(0)}',
        icon: Icons.attach_money,
        color: colors[1],
      ),
      _MetricTile(
        label: 'Avg Value/Item',
        value: '\$${avgValuePerItem.toStringAsFixed(0)}',
        icon: Icons.calculate,
        color: colors[2],
      ),
      _MetricTile(
        label: 'Total Activity',
        value: activityCount.toString(),
        icon: Icons.trending_up,
        color: colors[3],
      ),
      _MetricTile(
        label: 'Check-ins',
        value: checkInCount.toString(),
        icon: Icons.login,
        color: colors[4],
      ),
      _MetricTile(
        label: 'Check-outs',
        value: checkOutCount.toString(),
        icon: Icons.logout,
        color: colors[5],
      ),
      _MetricTile(
        label: 'Open Issues',
        value: data.issues.length.toString(),
        icon: Icons.warning_amber,
        color: colors[6],
      ),
      _MetricTile(
        label: 'Active Staff',
        value: data.staffActivity.length.toString(),
        icon: Icons.people,
        color: colors[7],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.metricsGridColumns(context),
        mainAxisSpacing: ResponsiveHelper.responsiveSpacing(context),
        crossAxisSpacing: ResponsiveHelper.responsiveSpacing(context),
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.3 : 1.4,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: ResponsiveHelper.cardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                metrics[index].icon,
                size: ResponsiveHelper.iconSize(context, baseSize: 28),
                color: metrics[index].color,
              ),
              SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
              Text(
                metrics[index].value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: metrics[index].color,
                      fontSize: ResponsiveHelper.isMobile(context) ? 18 : 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                metrics[index].label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: ResponsiveHelper.isMobile(context) ? 11 : 12,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTrendsChart extends StatelessWidget {
  const _ActivityTrendsChart({
    required this.dailyActivity,
    required this.dailyCheckIns,
    required this.dailyCheckOuts,
  });

  final Map<String, int> dailyActivity;
  final Map<String, int> dailyCheckIns;
  final Map<String, int> dailyCheckOuts;

  @override
  Widget build(BuildContext context) {
    if (dailyActivity.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No activity data available')),
        ),
      );
    }

    final sortedDates = dailyActivity.keys.toList()..sort();
    final last30Days = sortedDates.length > 30 ? sortedDates.sublist(sortedDates.length - 30) : sortedDates;

    return Card(
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Activity Trends (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SizedBox(
                height: ResponsiveHelper.chartHeight(context),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < last30Days.length && index % 5 == 0) {
                              final date = last30Days[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  date.substring(5), // MM-DD
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      // Total Activity
                      LineChartBarData(
                        spots: last30Days.asMap().entries.map((entry) {
                          final date = entry.value;
                          final value = dailyActivity[date] ?? 0;
                          return FlSpot(entry.key.toDouble(), value.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      ),
                      // Check-ins
                      LineChartBarData(
                        spots: last30Days.asMap().entries.map((entry) {
                          final date = entry.value;
                          final value = dailyCheckIns[date] ?? 0;
                          return FlSpot(entry.key.toDouble(), value.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Theme.of(context).colorScheme.secondary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      // Check-outs
                      LineChartBarData(
                        spots: last30Days.asMap().entries.map((entry) {
                          final date = entry.value;
                          final value = dailyCheckOuts[date] ?? 0;
                          return FlSpot(entry.key.toDouble(), value.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Theme.of(context).colorScheme.tertiary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Theme.of(context).colorScheme.primary, label: 'Total Activity'),
                const SizedBox(width: 16),
                _LegendItem(color: Theme.of(context).colorScheme.secondary, label: 'Check-ins'),
                const SizedBox(width: 16),
                _LegendItem(color: Theme.of(context).colorScheme.tertiary, label: 'Check-outs'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _MonthlyTrendsChart extends StatelessWidget {
  const _MonthlyTrendsChart({required this.monthlyActivity});

  final Map<String, int> monthlyActivity;

  @override
  Widget build(BuildContext context) {
    if (monthlyActivity.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedMonths = monthlyActivity.keys.toList()..sort();
    final values = sortedMonths.map((month) => monthlyActivity[month]!.toDouble()).toList();

    return Card(
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Activity Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SizedBox(
                height: ResponsiveHelper.chartHeight(context),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) * 1.2 : 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.grey[800]!,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedMonths.length) {
                              final month = sortedMonths[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  month.substring(5), // MM
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: values.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value,
                            color: Theme.of(context).colorScheme.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueByDepartmentChart extends StatelessWidget {
  const _ValueByDepartmentChart({required this.valueByDepartment});

  final Map<String, double> valueByDepartment;

  @override
  Widget build(BuildContext context) {
    if (valueByDepartment.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = valueByDepartment.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.length > 10 ? sorted.sublist(0, 10) : sorted;

    return Card(
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Value by Department (Top 10)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SizedBox(
                height: ResponsiveHelper.chartHeight(context),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: top10.isNotEmpty ? top10.first.value * 1.2 : 1000,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.grey[800]!,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '\$${rod.toY.toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < top10.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  top10[index].key.length > 8
                                      ? '${top10[index].key.substring(0, 8)}...'
                                      : top10[index].key,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barGroups: top10.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: Theme.of(context).colorScheme.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueByCategoryChart extends StatelessWidget {
  const _ValueByCategoryChart({required this.valueByCategory});

  final Map<String, double> valueByCategory;

  @override
  Widget build(BuildContext context) {
    if (valueByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = valueByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.length > 10 ? sorted.sublist(0, 10) : sorted;

    return Card(
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Value by Category (Top 10)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SizedBox(
                height: ResponsiveHelper.chartHeight(context),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: top10.isNotEmpty ? top10.first.value * 1.2 : 1000,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.grey[800]!,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '\$${rod.toY.toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < top10.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  top10[index].key.length > 10
                                      ? '${top10[index].key.substring(0, 10)}...'
                                      : top10[index].key,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barGroups: top10.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: Theme.of(context).colorScheme.secondary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffActivityChart extends StatelessWidget {
  const _StaffActivityChart({
    required this.staffActivity,
    required this.staff,
  });

  final Map<String, int> staffActivity;
  final List<StaffMember> staff;

  @override
  Widget build(BuildContext context) {
    if (staffActivity.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create staff lookup map
    final staffMap = {for (var s in staff) s.id: s.displayName};
    
    final sorted = staffActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.length > 10 ? sorted.sublist(0, 10) : sorted;

    return Card(
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Active Staff (Top 10)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SizedBox(
                height: ResponsiveHelper.chartHeight(context),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: top10.isNotEmpty ? top10.first.value.toDouble() * 1.2 : 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.grey[800]!,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < top10.length) {
                              final staffName = staffMap[top10[index].key] ?? top10[index].key;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  staffName.length > 8
                                      ? '${staffName.substring(0, 8)}...'
                                      : staffName,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: top10.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value.toDouble(),
                            color: Theme.of(context).colorScheme.tertiary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDistributionChart extends StatelessWidget {
  const _LocationDistributionChart({required this.locationCounts});

  final Map<String, int> locationCounts;

  @override
  Widget build(BuildContext context) {
    if (locationCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.length > 10 ? sorted.sublist(0, 10) : sorted;

    return Card(
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assets by Location (Top 10)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...top10.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key),
                      ),
                      Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: entry.value / sorted.first.value,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MetricTile {
  const _MetricTile({
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

class _AnalyticsData {
  const _AnalyticsData({
    required this.items,
    required this.departments,
    required this.categories,
    required this.staff,
    required this.history,
    required this.issues,
    required this.categoryCounts,
    required this.departmentCounts,
    required this.statusCounts,
    required this.staffCounts,
    required this.locationCounts,
    required this.valueByDepartment,
    required this.valueByCategory,
    required this.dailyActivity,
    required this.dailyCheckIns,
    required this.dailyCheckOuts,
    required this.monthlyActivity,
    required this.staffActivity,
  });

  final List<InventoryItem> items;
  final List<Department> departments;
  final List<Category> categories;
  final List<StaffMember> staff;
  final List<HistoryEntry> history;
  final List<Issue> issues;
  final Map<String, int> categoryCounts;
  final Map<String, int> departmentCounts;
  final Map<String, int> statusCounts;
  final Map<String, int> staffCounts;
  final Map<String, int> locationCounts;
  final Map<String, double> valueByDepartment;
  final Map<String, double> valueByCategory;
  final Map<String, int> dailyActivity;
  final Map<String, int> dailyCheckIns;
  final Map<String, int> dailyCheckOuts;
  final Map<String, int> monthlyActivity;
  final Map<String, int> staffActivity;
}

