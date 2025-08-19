// lib/widgets/super_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/widgets/super_admin_user_management.dart';
import 'package:flutter_application_1/widgets/approval_queue_screen.dart';
import 'package:flutter_application_1/widgets/permissions_manager_screen.dart';
import 'package:flutter_application_1/widgets/custom_report_builder_screen.dart';
import 'package:flutter_application_1/widgets/bulk_item_import_screen.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  static const Color _primaryTextColor = Color(0xFF1A2533);
  static const Color _secondaryTextColor = Color(0xFF6C757D);
  static const Color _backgroundColor = Color(0xFFF4F7FA);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _accentColor = Colors.blue;

  String? _selectedDepartment = 'All';
  String? _selectedStaff = 'All';

  final List<String> _departments = [
    'All',
    'IT',
    'Marketing',
    'Operations',
    'HR'
  ];
  final List<String> _staff = [
    'All',
    'Ali Bin Hamad',
    'Fatima A.',
    'John Smith',
    'Jane Doe'
  ];

  void _generateReport() async {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final items = dataStore.items;

    // Prepare CSV header
    final headers = [
      'ID',
      'Name',
      'Category',
      'Department',
      'Assigned Staff',
      'Purchase Date',
      'Purchase Price',
      'Current Value',
      'Is Tagged',
      'QR Code ID',
      'Is Available',
      'Is Written Off'
    ];

    // Prepare CSV rows
    final rows = <List<String>>[];
    rows.add(headers);

    for (final item in items) {
      rows.add([
        item.id ?? '',
        item.name,
        item.category,
        item.department ?? '',
        item.assignedStaff ?? '',
        item.purchaseDate.toIso8601String(),
        item.purchasePrice?.toStringAsFixed(2) ?? '',
        item.currentValue?.toStringAsFixed(2) ?? '',
        item.isTagged ? 'Yes' : 'No',
        item.qrCodeId ?? '',
        item.isAvailable ? 'Yes' : 'No',
        item.isWrittenOff ? 'Yes' : 'No',
      ]);
    }

    // Convert to CSV string
    final csv = rows.map((row) => row.map((v) => '"$v"').join(',')).join('\n');

    try {
      String filePath;
      if (Platform.isAndroid) {
        filePath =
            '/storage/emulated/0/Download/inventory_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      } else {
        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
        } catch (_) {
          directory = await getExternalStorageDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();
        filePath =
            '${directory.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      }
      final file = File(filePath);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Inventory report saved: $filePath'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save report: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _navigateToItemDetails(ItemModel item) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
            value: LocalDataStore(),
            child: ItemDetailsScreen(
                item: item,
                onUpdateItem: (item) => LocalDataStore().updateItem(item)))));
  }

  void _navigateToUserManagement() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: LocalDataStore(),
        child: const SuperAdminUserManagement(),
      ),
    ));
  }

  void _navigateToApprovalQueue() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: LocalDataStore(),
        child: const ApprovalQueueScreen(),
      ),
    ));
  }

  void _navigateToPermissionsManager() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: LocalDataStore(),
        child: const PermissionsManagerScreen(),
      ),
    ));
  }

  void _navigateToBulkItemImport() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: LocalDataStore(),
        child: const BulkItemImportScreen(),
      ),
    ));
  }

  void _navigateToCustomReportBuilder() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: LocalDataStore(),
        child: const CustomReportBuilderScreen(),
      ),
    ));
  }

  void _onChartTap(String filterKey, String filterValue) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: dataStore,
        child: FilteredItemsScreen(
          items: dataStore.items,
          onUpdateItem: dataStore.updateItem,
          initialFilters: {
            filterKey: filterValue,
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Super Admin',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.cardColor,
        elevation: 1.0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      body: Consumer<LocalDataStore>(
        builder: (context, dataStore, child) {
          final allItems = dataStore.items;
          final pendingItems = allItems.where((item) => item.isPending).length;

          final filteredItems = allItems.where((item) {
            final byDept = _selectedDepartment == 'All' ||
                item.department == _selectedDepartment;
            final byStaff =
                _selectedStaff == 'All' || item.assignedStaff == _selectedStaff;
            return byDept && byStaff;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToUserManagement,
                          icon: const Icon(Icons.people_alt_outlined),
                          label: const Text('User Mgmt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToPermissionsManager,
                          icon: const Icon(Icons.security),
                          label: const Text('Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSectionTitle(theme, 'Asset Overview'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(theme, 'Total Items',
                        allItems.length.toString(), Icons.inventory_2),
                    _buildStatCard(
                        theme,
                        'Tagged Items',
                        allItems.where((i) => i.isTagged).length.toString(),
                        Icons.qr_code_2),
                    _buildStatCard(
                        theme,
                        'Pending Items',
                        pendingItems.toString(),
                        Icons.playlist_add_check_circle),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Filter Assets'),
                const SizedBox(height: 16),
                _buildFilterCard(theme),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Items (${filteredItems.length})'),
                const SizedBox(height: 16),
                _buildItemsOverviewCard(theme, filteredItems),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Reporting'),
                const SizedBox(height: 16),
                _buildReportCard(theme, allItems),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Import/Export'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToBulkItemImport,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Bulk Import Assets (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToCustomReportBuilder,
                  icon: const Icon(Icons.library_books_outlined),
                  label: const Text('Build Custom Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Visual Reports'),
                const SizedBox(height: 16),
                _buildPieChartCard(theme, allItems),
                const SizedBox(height: 16),
                _buildBarChartCard(theme, allItems),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildStatCard(
      ThemeData theme, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.textTheme.bodyLarge?.color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(ThemeData theme) {
    return Card(
      elevation: 2.0,
      shadowColor: theme.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    fillColor: theme.cardColor,
                    filled: true),
                items: _departments
                    .map((String value) => DropdownMenuItem<String>(
                        value: value, child: Text(value)))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedDepartment = newValue);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStaff,
                decoration: InputDecoration(
                    labelText: 'Staff',
                    border: OutlineInputBorder(),
                    fillColor: theme.cardColor,
                    filled: true),
                items: _staff
                    .map((String value) => DropdownMenuItem<String>(
                        value: value, child: Text(value)))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedStaff = newValue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsOverviewCard(ThemeData theme, List<ItemModel> items) {
    return Card(
      elevation: 2.0,
      shadowColor: theme.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: items.isEmpty
          ? const Center(
              heightFactor: 5, child: Text('No items match filters.'))
          : Column(
              children: items.map((item) {
                final isLastItem = item == items.last;
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.1),
                        child: Icon(Icons.inventory_2_outlined,
                            color: Colors.black),
                      ),
                      title: Text(item.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Dept: ${item.department ?? 'N/A'} | Assigned: ${item.assignedStaff ?? 'N/A'}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600)),
                      trailing: Icon(Icons.chevron_right,
                          color: theme.textTheme.bodySmall?.color),
                      onTap: () => _navigateToItemDetails(item),
                    ),
                    if (!isLastItem)
                      Divider(height: 1, indent: 70, color: theme.dividerColor),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildReportCard(ThemeData theme, List<ItemModel> items) {
    final totalAssets = items.length;
    final taggedAssets = items.where((i) => i.isTagged).length;
    final agingAssets = items
        .where((i) => DateTime.now().difference(i.purchaseDate).inDays > 1825)
        .length;
    final totalValue =
        items.fold(0.0, (sum, item) => sum + (item.purchasePrice ?? 0.0));

    final Map<String, int> categoryCounts = {};
    for (var item in items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    final Map<String, int> departmentCounts = {};
    for (var item in items) {
      if (item.department != null) {
        departmentCounts[item.department!] =
            (departmentCounts[item.department!] ?? 0) + 1;
      }
    }

    return Card(
      elevation: 2.0,
      shadowColor: theme.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _generateReport,
              child: const Text('Generate Inventory Report'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
            Divider(height: 30, color: theme.dividerColor),
            Text('Report Data (Prototype)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
                title: const Text('Total Assets'),
                trailing: Text(totalAssets.toString())),
            ListTile(
                title: const Text('Total Value'),
                trailing: Text('QR ${totalValue.toStringAsFixed(2)}')),
            ListTile(
                title: const Text('Tagged Assets'),
                trailing: Text(taggedAssets.toString())),
            ListTile(
                title: const Text('Aging Assets (>5yr)'),
                trailing: Text(agingAssets.toString())),
            Divider(color: theme.dividerColor),
            Text('Assets by Category',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            ...categoryCounts.entries
                .map((entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text(entry.value.toString()),
                    ))
                .toList(),
            Divider(color: theme.dividerColor),
            Text('Assets by Department',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            ...departmentCounts.entries
                .map((entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text(entry.value.toString()),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(ThemeData theme, List<ItemModel> items) {
    final Map<String, int> categoryCounts = {};
    for (var item in items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    final categories = categoryCounts.keys.toList();
    List<PieChartSectionData> sections = categoryCounts.entries.map((entry) {
      final index = categories.indexOf(entry.key);
      final color = theme.primaryColor.withOpacity((index + 1) * 0.2);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${entry.value})',
        radius: 50,
        titleStyle: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
          shadows: [
            Shadow(color: theme.shadowColor, blurRadius: 2),
          ],
        ),
      );
    }).toList();

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets by Category',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      if (event.isInterestedForInteractions &&
                          pieTouchResponse != null &&
                          pieTouchResponse.touchedSection != null) {
                        final sectionIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                        if (sectionIndex >= 0) {
                          _onChartTap('category', categories[sectionIndex]);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, List<ItemModel> items) {
    final Map<String, int> departmentCounts = {};
    for (var item in items) {
      if (item.department != null) {
        departmentCounts[item.department!] =
            (departmentCounts[item.department!] ?? 0) + 1;
      }
    }

    final departments = departmentCounts.keys.toList();
    final barGroups = departmentCounts.entries.map((entry) {
      final index = departments.indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: theme.primaryColor.withOpacity((index + 1) * 0.2),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets by Department',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                      left: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(departments.elementAt(value.toInt()),
                              style: theme.textTheme.bodySmall);
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchCallback: (event, barTouchResponse) {
                      if (event.isInterestedForInteractions &&
                          barTouchResponse != null &&
                          barTouchResponse.spot != null) {
                        final index =
                            barTouchResponse.spot!.touchedBarGroupIndex;
                        _onChartTap('department', departments[index]);
                      }
                    },
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
