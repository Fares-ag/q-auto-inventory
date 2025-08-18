// lib/widgets/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/approval_queue_screen.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/models/item_model.dart' as item_model;
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

// Main admin dashboard widget
class AdminDashboardScreen extends StatelessWidget {
  final String? userDepartment; // Department of the logged-in admin
  final Function(ItemModel) onUpdateItem; // Callback for updating an item

  const AdminDashboardScreen({
    Key? key,
    required this.userDepartment,
    required this.onUpdateItem,
  }) : super(key: key);

  // Opens a modal bottom sheet for adding a new item
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
            // Save new item to local data store, tagged with the admin's department
            LocalDataStore()
                .addItem(newItem.copyWith(department: userDepartment));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  // Handles taps on chart sections and navigates to a filtered items list
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

  // Navigates to the approval queue screen
  void _navigateToApprovalQueue(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: dataStore,
        child: const ApprovalQueueScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Access shared data store
    final dataStore = Provider.of<LocalDataStore>(context);
    final allItems = dataStore.items;

    // Filter items belonging to the current admin's department
    final departmentItems =
        allItems.where((item) => item.department == userDepartment).toList();

    // Count untagged items in this department
    final untaggedItems =
        departmentItems.where((item) => !item.isTagged).length;

    // Collect open issues linked to this department
    final openIssues = dataStore.issues
        .where((issue) => allItems.any((item) =>
            item.id == issue.itemId && item.department == userDepartment))
        .toList();

    // Recent activity history filtered by department
    final recentHistory = dataStore.history
        .where((entry) => entry.description.contains(userDepartment!))
        .toList();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard title
              Text(
                'Admin Dashboard for ${userDepartment ?? 'N/A'}',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Overview section
              _buildSectionTitle(theme, 'My Department Overview'),
              const SizedBox(height: 16),

              // Stats grid (total assets, untagged items, issues)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  _buildStatCard(
                      theme,
                      'Total Assets',
                      departmentItems.length.toString(),
                      Icons.inventory_2_outlined),
                  _buildStatCard(theme, 'Untagged Items',
                      untaggedItems.toString(), Icons.label_off_outlined),
                  _buildStatCard(
                      theme,
                      'Assigned Issues',
                      openIssues.length.toString(),
                      Icons.report_problem_outlined),
                ],
              ),
              const SizedBox(height: 24),

              // Pie chart: department assets by category
              _buildPieChartCard(context, theme, departmentItems),
              const SizedBox(height: 32),

              // Quick actions section
              _buildSectionTitle(theme, 'Quick Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickAction(theme, 'Add Item', Icons.add_box_outlined,
                      () => _showAddItemModal(context)),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                      theme,
                      'View Pending',
                      Icons.playlist_add_check_circle,
                      () => _navigateToApprovalQueue(context)),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                      theme, 'View All', Icons.inventory_2_outlined, () {
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

              // Department history section
              _buildSectionTitle(theme, 'Department History'),
              const SizedBox(height: 16),
              recentHistory.isEmpty
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No recent activity.')))
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

  // Helper to build section titles
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600));
  }

  // Helper to build statistic cards
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.black, size: 28),
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

  // Helper to build quick action buttons (Add, View Pending, View All)
  Widget _buildQuickAction(
      ThemeData theme, String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.primaryColor, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build history entry cards
  Widget _buildHistoryEntryCard(ThemeData theme, HistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(entry.icon ?? Icons.history, color: theme.primaryColor),
        title: Text(entry.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(entry.description, style: theme.textTheme.bodyMedium),
        trailing: Text(
            '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}'),
      ),
    );
  }

  // Helper to build pie chart card (assets grouped by category)
  Widget _buildPieChartCard(
      BuildContext context, ThemeData theme, List<ItemModel> items) {
    // Count number of items per category
    final Map<String, int> categoryCounts = {};
    for (var item in items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    final categories = categoryCounts.keys.toList();

    // Build pie chart sections dynamically
    List<PieChartSectionData> sections = categoryCounts.entries.map((entry) {
      final index = categories.indexOf(entry.key);
      final color = Colors.black.withOpacity((index + 1) * 0.2);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${entry.value})',
        radius: 50,
        titleStyle: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2),
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
            Text('Department Assets by Category',
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
                  // Allow tapping on pie chart sections
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
