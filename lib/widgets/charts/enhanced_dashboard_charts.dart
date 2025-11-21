import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/firestore_models.dart';

/// Enhanced dashboard charts with more analytics
class EnhancedDashboardCharts extends StatelessWidget {
  const EnhancedDashboardCharts({
    super.key,
    required this.items,
    required this.departments,
    this.history,
  });

  final List<InventoryItem> items;
  final List<Department> departments;
  final List<HistoryEntry>? history;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusChart(items: items),
        const SizedBox(height: 24),
        _DepartmentChart(items: items, departments: departments),
        const SizedBox(height: 24),
        _CategoryChart(items: items),
        if (history != null && history!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ActivityTrendChart(history: history!),
        ],
      ],
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.items});

  final List<InventoryItem> items;

  Map<String, int> _getStatusCounts() {
    final counts = <String, int>{};
    for (final item in items) {
      final status = item.status ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = _getStatusCounts();
    if (statusCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items by Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: statusCounts.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final statusEntry = entry.value;
                    final percentage = (statusEntry.value / items.length) * 100;
                    return PieChartSectionData(
                      value: statusEntry.value.toDouble(),
                      title: '${statusEntry.key}\n${percentage.toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentChart extends StatelessWidget {
  const _DepartmentChart({
    required this.items,
    required this.departments,
  });

  final List<InventoryItem> items;
  final List<Department> departments;

  Map<String, int> _getDepartmentCounts() {
    final counts = <String, int>{};
    final deptMap = {for (var d in departments) d.id: d.name};
    for (final item in items) {
      final deptId = item.departmentId;
      if (deptId.isNotEmpty) {
        final deptName = deptMap[deptId] ?? deptId;
        counts[deptName] = (counts[deptName] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final deptCounts = _getDepartmentCounts();
    if (deptCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = deptCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items by Department',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: sortedEntries.first.value.toDouble() * 1.2,
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
                          if (index >= 0 && index < sortedEntries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedEntries[index].key.length > 8
                                    ? '${sortedEntries[index].key.substring(0, 8)}...'
                                    : sortedEntries[index].key,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final deptEntry = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: deptEntry.value.toDouble(),
                          color: Colors.blue,
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
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.items});

  final List<InventoryItem> items;

  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{};
    for (final item in items) {
      final category = item.categoryId.isEmpty ? 'Uncategorized' : item.categoryId;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final categoryCounts = _getCategoryCounts();
    if (categoryCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final allEntries = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedEntries = allEntries.length > 5
        ? allEntries.sublist(0, 5)
        : allEntries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: sortedEntries.first.value.toDouble() * 1.2,
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
                          if (index >= 0 && index < sortedEntries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedEntries[index].key.length > 10
                                    ? '${sortedEntries[index].key.substring(0, 10)}...'
                                    : sortedEntries[index].key,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final catEntry = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: catEntry.value.toDouble(),
                          color: Colors.purple,
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
          ],
        ),
      ),
    );
  }
}

class _ActivityTrendChart extends StatelessWidget {
  const _ActivityTrendChart({required this.history});

  final List<HistoryEntry> history;

  Map<String, int> _getDailyActivity() {
    final counts = <String, int>{};
    for (final entry in history) {
      if (entry.timestamp != null) {
        final date = entry.timestamp!.toLocal();
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final dailyActivity = _getDailyActivity();
    if (dailyActivity.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = dailyActivity.keys.toList()..sort();
    final values = sortedDates.map((date) => dailyActivity[date]!.toDouble()).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Trend (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDates.length) {
                            final date = sortedDates[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                date.substring(5), // Show MM-DD
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                    LineChartBarData(
                      spots: values.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
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

