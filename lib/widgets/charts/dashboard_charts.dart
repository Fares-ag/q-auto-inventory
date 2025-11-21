import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/firestore_models.dart';

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({
    super.key,
    required this.items,
    required this.departments,
  });

  final List<InventoryItem> items;
  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusChart(items: items),
        const SizedBox(height: 24),
        _DepartmentChart(items: items, departments: departments),
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
    // Memoize the computation by doing it once
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
    for (final item in items) {
      final deptId = item.departmentId;
      if (deptId.isNotEmpty) {
        // Use lookup map for better performance
        final dept = departments.firstWhere(
          (d) => d.id == deptId,
          orElse: () => Department(id: deptId, name: deptId),
        );
        counts[dept.name] = (counts[dept.name] ?? 0) + 1;
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

