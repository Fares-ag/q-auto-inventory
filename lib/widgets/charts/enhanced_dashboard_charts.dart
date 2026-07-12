import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/firestore_models.dart';
import '../../theme/app_theme.dart';

/// Enhanced dashboard charts with more analytics
/// Optimized with RepaintBoundary to reduce GC pressure
class EnhancedDashboardCharts extends StatelessWidget {
  const EnhancedDashboardCharts({
    super.key,
    required this.items,
    required this.departments,
    this.categories = const [],
    this.history,
  });

  final List<InventoryItem> items;
  final List<Department> departments;
  final List<Category> categories;
  final List<HistoryEntry>? history;

  @override
  Widget build(BuildContext context) {
    final activity = history;
    final clippedHistory = activity != null && activity.length > 120
        ? activity.sublist(0, 120)
        : activity;

    return RepaintBoundary(
      child: Column(
        children: [
          _StatusChart(items: items),
          const SizedBox(height: 24),
          _DepartmentChart(items: items, departments: departments),
          const SizedBox(height: 24),
          _CategoryChart(items: items, categories: categories),
          if (clippedHistory != null && clippedHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ActivityTrendChart(history: clippedHistory),
          ],
        ],
      ),
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

  static String _formatStatusLabel(String raw) {
    if (raw.isEmpty) return 'Unknown';
    return raw.split(RegExp(r'[_\s]+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = _getStatusCounts();
    if (statusCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = AppTheme.chartColors;
    final totalItems = items.length;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final entries = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      final statusEntry = entries[i];
      sections.add(
        PieChartSectionData(
          value: statusEntry.value.toDouble(),
          showTitle: false,
          title: '',
          color: colors[i % colors.length],
          radius: 56,
          borderSide: BorderSide(color: cs.surface, width: 2),
        ),
      );
    }

    return RepaintBoundary(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items by Status',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 196,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 1.5,
                          centerSpaceRadius: 46,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalItems',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          Text(
                            'items',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Breakdown',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < entries.length; i++)
                    _StatusLegendRow(
                      color: colors[i % colors.length],
                      label: _formatStatusLabel(entries[i].key),
                      count: entries[i].value,
                      percentage: entries[i].value / totalItems * 100,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLegendRow extends StatelessWidget {
  const _StatusLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  final Color color;
  final String label;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label  ·  $count (${percentage.toStringAsFixed(1)}%)',
              style: t.textTheme.bodySmall?.copyWith(height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  // Memoize department map creation for better performance
  Map<String, int> _getDepartmentCounts() {
    final counts = <String, int>{};
    // Create lookup map once for O(1) access instead of O(n) firstWhere
    final deptMap = {for (var d in departments) d.id: d.name};
    // Single pass through items
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

    // Pre-compute sorted entries to reduce allocations
    final sortedEntries = deptCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxCount = sortedEntries.first.value;
    final chartMaxY =
        math.max(4.0, (maxCount * 1.08).ceilToDouble());
    final tickInterval = chartMaxY <= 5
        ? 1.0
        : math.max(1.0, (chartMaxY / 4).roundToDouble());

    // Pre-compute bar groups to reduce allocations
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final deptEntry = sortedEntries[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: deptEntry.value.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: 18,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items by Department',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (sortedEntries.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Swipe sideways to see all departments',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 248,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minChartWidth = math.max(
                      constraints.maxWidth,
                      sortedEntries.length * 52.0,
                    );
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      child: SizedBox(
                        width: minChartWidth,
                        height: 248,
                        child: BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: chartMaxY,
                            alignment: BarChartAlignment.spaceAround,
                            groupsSpace: 8,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.grey[800]!,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  if (groupIndex < 0 ||
                                      groupIndex >= sortedEntries.length) {
                                    return null;
                                  }
                                  final e = sortedEntries[groupIndex];
                                  return BarTooltipItem(
                                    '${e.key}\n${e.value}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 52,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >= sortedEntries.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = sortedEntries[index].key;
                                    final cs =
                                        Theme.of(context).colorScheme;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: SizedBox(
                                        width: 48,
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            height: 1.15,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 34,
                                  interval: tickInterval,
                                  getTitlesWidget: (value, meta) {
                                    final v = value.round();
                                    if ((value - v).abs() > 0.001) {
                                      return const SizedBox.shrink();
                                    }
                                    if (v < 0 || v > chartMaxY + 0.01) {
                                      return const SizedBox.shrink();
                                    }
                                    final cs =
                                        Theme.of(context).colorScheme;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: Text(
                                        '$v',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: tickInterval,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.35),
                                ),
                                left: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.35),
                                ),
                              ),
                            ),
                            barGroups: barGroups,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({
    required this.items,
    required this.categories,
  });

  final List<InventoryItem> items;
  final List<Category> categories;

  Map<String, int> _getCategoryCounts() {
    final catMap = {for (var c in categories) c.id: c.name};
    final counts = <String, int>{};
    for (final item in items) {
      final id = item.categoryId;
      final label =
          id.isEmpty ? 'Uncategorized' : (catMap[id] ?? id);
      counts[label] = (counts[label] ?? 0) + 1;
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
    final sortedEntries =
        allEntries.length > 5 ? allEntries.sublist(0, 5) : allEntries;

    final maxVal = sortedEntries.first.value;
    final chartMaxY =
        math.max(4.0, (maxVal * 1.08).ceilToDouble());
    final tickInterval = chartMaxY <= 5
        ? 1.0
        : math.max(1.0, (chartMaxY / 4).roundToDouble());
    
    // Pre-compute bar groups to reduce allocations
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final catEntry = sortedEntries[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: catEntry.value.toDouble(),
              color: Theme.of(context).colorScheme.secondary,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      child: Card(
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
                    minY: 0,
                    maxY: chartMaxY,
                    alignment: BarChartAlignment.spaceAround,
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
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedEntries.length) {
                              final key = sortedEntries[index].key;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  key.length > 14
                                      ? '${key.substring(0, 14)}…'
                                      : key,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: tickInterval,
                          getTitlesWidget: (value, meta) {
                            final v = value.round();
                            if ((value - v).abs() > 0.001) {
                              return const SizedBox.shrink();
                            }
                            if (v < 0 || v > chartMaxY + 0.01) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '$v',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: tickInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          ),
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
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
    // Pre-compute values and spots to reduce allocations
    final values = <double>[];
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final value = dailyActivity[sortedDates[i]]!.toDouble();
      values.add(value);
      spots.add(FlSpot(i.toDouble(), value));
    }

    return RepaintBoundary(
      child: Card(
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
                    gridData: const FlGridData(show: true),
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
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
