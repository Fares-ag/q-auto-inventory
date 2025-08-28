// lib/widgets/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/approval_queue_screen.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String? userDepartment;
  final Function(ItemModel) onUpdateItem;

  const AdminDashboardScreen({
    Key? key,
    required this.userDepartment,
    required this.onUpdateItem,
  }) : super(key: key);

  void _showAddItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => AddItemWidget(
          onClose: () => Navigator.of(context).pop(),
          onSave: (newItem) {
            LocalDataStore()
                .addItem(newItem.copyWith(department: userDepartment));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _onChartTap(BuildContext context, String filterKey, String filterValue) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final allItems = dataStore.items
        .where((item) => item.department == userDepartment)
        .toList();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: dataStore,
        child: FilteredItemsScreen(
          items: allItems,
          onUpdateItem: onUpdateItem,
          initialFilters: {
            filterKey: filterValue,
          },
        ),
      ),
    ));
  }

  void _navigateToApprovalQueue(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const ApprovalQueueScreen(),
      ),
    ));
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final allItems = dataStore.items;
    final departmentItems =
        allItems.where((item) => item.department == userDepartment).toList();
    final untaggedItems =
        departmentItems.where((item) => !item.isTagged).length;
    final openIssues = dataStore.issues
        .where((issue) => allItems.any((item) =>
            item.id == issue.itemId && item.department == userDepartment))
        .toList();
    final recentHistory = dataStore.history
        .where((entry) => entry.description.contains(userDepartment ?? ''))
        .toList();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Department: ${userDepartment ?? 'N/A'}',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'My Department Overview'),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                      theme,
                      'Total Assets',
                      departmentItems.length.toString(),
                      Icons.inventory_2_outlined,
                      Colors.blue.shade700),
                  _buildStatCard(
                      theme,
                      'Untagged Items',
                      untaggedItems.toString(),
                      Icons.label_off_outlined,
                      Colors.orange.shade700),
                  _buildStatCard(
                      theme,
                      'Assigned Issues',
                      openIssues.length.toString(),
                      Icons.report_problem_outlined,
                      Colors.red.shade700),
                ],
              ),
              const SizedBox(height: 24),
              _buildPieChartCard(context, theme, departmentItems),
              const SizedBox(height: 32),
              _buildSectionTitle(theme, 'Quick Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickAction(theme, 'Add Item', Icons.add_box_outlined,
                      Colors.green.shade700, () => _showAddItemModal(context)),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                      theme,
                      'View Pending',
                      Icons.playlist_add_check_circle,
                      Colors.purple.shade700,
                      () => _navigateToApprovalQueue(context)),
                  const SizedBox(width: 16),
                  _buildQuickAction(theme, 'View All',
                      Icons.inventory_2_outlined, Colors.blueGrey.shade700, () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                              value: dataStore,
                              child: FilteredItemsScreen(
                                items: departmentItems,
                                onUpdateItem: onUpdateItem,
                              ),
                            )));
                  }),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(theme, 'Department History'),
              const SizedBox(height: 16),
              recentHistory.isEmpty
                  ? Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: const Center(
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Text('No recent activity.'))),
                    )
                  : Column(
                      children: recentHistory
                          .map((entry) => _buildHistoryEntryCard(theme, entry))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style: theme.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildStatCard(
      ThemeData theme, String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 32),
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

  Widget _buildQuickAction(ThemeData theme, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryEntryCard(ThemeData theme, HistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.05),
          foregroundColor: theme.primaryColor,
          child: Icon(entry.icon ?? Icons.history),
        ),
        title: Text(entry.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(entry.description,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        trailing: Text(
            '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}'),
      ),
    );
  }

  Widget _buildPieChartCard(
      BuildContext context, ThemeData theme, List<ItemModel> items) {
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
            Text('Department Assets by Category',
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
                          _onChartTap(
                              context, 'category', categories[sectionIndex]);
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
}
