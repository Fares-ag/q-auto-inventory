// lib/widgets/super_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/widgets/super_admin_user_management.dart';
import 'package:flutter_application_1/widgets/approval_queue_screen.dart';
import 'package:flutter_application_1/widgets/permissions_manager_screen.dart';
import 'package:flutter_application_1/widgets/custom_report_builder_screen.dart';
import 'package:flutter_application_1/widgets/bulk_item_import_screen.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/traceability_report_screen.dart'; // ADD THIS IMPORT
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'login_screen.dart';
import 'department_management_screen.dart';
import 'category_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  String? _selectedDepartment = 'All';
  String? _selectedStaff = 'All';

  void _generateReport() async {
    // 1. Request storage permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      // 2. If permission is granted, proceed to create and save the file
      final dataStore = Provider.of<LocalDataStore>(context, listen: false);
      final items = dataStore.items;
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
      final rows = <List<dynamic>>[];
      rows.add(headers);
      for (final item in items) {
        rows.add([
          item.id,
          item.name,
          item.category,
          item.department ?? '',
          item.assignedStaff ?? '',
          item.purchaseDate.toIso8601String(),
          item.purchasePrice?.toStringAsFixed(2) ?? '',
          item.currentValue?.toStringAsFixed(2) ?? '',
          item.isTagged,
          item.qrCodeId ?? '',
          item.isAvailable,
          item.isWrittenOff,
        ]);
      }
      String csv = const ListToCsvConverter().convert(rows);

      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        final file = File(
            '$path/full_inventory_report_${DateTime.now().millisecondsSinceEpoch}.csv');
        await file.writeAsString(csv);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Report saved to: ${file.path}'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      // 3. If permission is denied, inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Storage permission is required to save reports.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToItemDetails(BuildContext context, ItemModel item) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
            value: dataStore,
            child: ItemDetailsScreen(
                item: item,
                onUpdateItem: (item) => dataStore.updateItem(item)))));
  }

  void _navigateToUserManagement() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const SuperAdminUserManagement(),
      ),
    ));
  }

  void _navigateToDepartmentManagement() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const DepartmentManagementScreen(),
      ),
    ));
  }

  void _navigateToCategoryManagement() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const CategoryManagementScreen(),
      ),
    ));
  }

  void _navigateToApprovalQueue() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const ApprovalQueueScreen(),
      ),
    ));
  }

  void _navigateToPermissionsManager() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const PermissionsManagerScreen(),
      ),
    ));
  }

  void _navigateToBulkItemImport() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const BulkItemImportScreen(),
      ),
    ));
  }

  void _navigateToCustomReportBuilder() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const CustomReportBuilderScreen(),
      ),
    ));
  }

  // ADDED: Navigation method for the new screen
  void _navigateToTraceabilityReport() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const TraceabilityReportScreen(),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<LocalDataStore>(
        builder: (context, dataStore, child) {
          final allItems = dataStore.items;
          final allUsers = dataStore.users;
          final allDepartments = dataStore.departments;
          final assignedItems = allItems
              .where((item) =>
                  item.assignedStaff != null && item.assignedStaff!.isNotEmpty)
              .length;
          final unassignedItems = allItems.length - assignedItems;
          final taggedItems = allItems.where((item) => item.isTagged).length;
          final openIssues = dataStore.issues
              .where((i) => i.status == IssueStatus.Open)
              .length;

          final departments = [
            'All',
            ...dataStore.departments.map((d) => d.name).toSet().toList()
          ];
          final staff = [
            'All',
            ...dataStore.users.map((u) => u.email).toSet().toList()
          ];

          final filteredItems = allItems.where((item) {
            final byDept = _selectedDepartment == 'All' ||
                item.department == _selectedDepartment;
            final byStaff =
                _selectedStaff == 'All' || item.assignedStaff == _selectedStaff;
            return byDept && byStaff;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(theme, 'Management'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _buildTopButton(
                      onPressed: _navigateToUserManagement,
                      icon: Icons.people_alt_outlined,
                      label: 'Users',
                    ),
                    _buildTopButton(
                      onPressed: _navigateToPermissionsManager,
                      icon: Icons.security,
                      label: 'Permissions',
                    ),
                    _buildTopButton(
                      onPressed: _navigateToDepartmentManagement,
                      icon: Icons.business_outlined,
                      label: 'Departments',
                    ),
                    _buildTopButton(
                      onPressed: _navigateToCategoryManagement,
                      icon: Icons.category_outlined,
                      label: 'Categories',
                    ),
                    _buildTopButton(
                      onPressed: _navigateToBulkItemImport,
                      icon: Icons.cloud_upload_outlined,
                      label: 'Bulk Import',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Application Insights'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(theme, 'Total Items',
                        allItems.length.toString(), Icons.inventory_2),
                    _buildStatCard(theme, 'Total Users',
                        allUsers.length.toString(), Icons.people),
                    _buildStatCard(theme, 'Total Departments',
                        allDepartments.length.toString(), Icons.business),
                    _buildStatCard(
                        theme,
                        'Assigned Items',
                        assignedItems.toString(),
                        Icons.person_pin_circle_outlined),
                    _buildStatCard(theme, 'Unassigned Items',
                        unassignedItems.toString(), Icons.person_pin_circle),
                    _buildStatCard(theme, 'Tagged Items',
                        taggedItems.toString(), Icons.qr_code_2),
                    _buildStatCard(theme, 'Open Issues', openIssues.toString(),
                        Icons.report_problem_outlined),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Filter & View Assets'),
                const SizedBox(height: 16),
                _buildFilterCard(theme, departments, staff),
                const SizedBox(height: 16),
                _buildItemsOverviewCard(theme, filteredItems),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Reporting'),
                const SizedBox(height: 16),
                _buildReportCard(theme, allItems),
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

  Widget _buildTopButton(
      {required VoidCallback onPressed,
      required IconData icon,
      required String label}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style: theme.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildStatCard(
      ThemeData theme, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              Text(title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(
      ThemeData theme, List<String> departments, List<String> staff) {
    return Card(
      elevation: 1.0,
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
                    fillColor: Colors.grey[50],
                    filled: true),
                items: departments
                    .map((String value) => DropdownMenuItem<String>(
                        value: value, child: Text(value)))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedDepartment = newValue);
                  }
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
                    fillColor: Colors.grey[50],
                    filled: true),
                items: staff
                    .map((String value) => DropdownMenuItem<String>(
                        value: value, child: Text(value)))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedStaff = newValue);
                  }
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
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: items.isEmpty
          ? const Center(
              heightFactor: 5, child: Text('No items match filters.'))
          : Column(
              children: items.take(5).map((item) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.05),
                    child:
                        Icon(Icons.inventory_2_outlined, color: Colors.black),
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
                  onTap: () => _navigateToItemDetails(context, item),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildReportCard(ThemeData theme, List<ItemModel> items) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Generate Full Report (CSV)'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _navigateToCustomReportBuilder,
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Build Custom Report'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 12),
            // ADDED: New button for the traceability report
            ElevatedButton.icon(
              onPressed: _navigateToTraceabilityReport,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Traceability Report'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
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
      final color =
          Colors.primaries[index % Colors.primaries.length].withOpacity(0.8);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${entry.value})',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets by Category',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
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
            color: Colors.blueAccent.withOpacity(0.8),
            width: 22,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets by Department',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
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
                          if (value.toInt() < departments.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(departments.elementAt(value.toInt()),
                                  style: theme.textTheme.bodySmall),
                            );
                          }
                          return const Text('');
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
