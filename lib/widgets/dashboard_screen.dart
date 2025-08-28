// lib/widgets/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/approval_queue_screen.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  final List<ItemModel> allItems;
  final List<Issue> openIssues;
  final List<HistoryEntry> recentHistory;
  final VoidCallback onNavigateToItems;
  final Function(ItemModel) onUpdateItem;

  const DashboardScreen({
    Key? key,
    required this.allItems,
    required this.openIssues,
    required this.recentHistory,
    required this.onNavigateToItems,
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
            LocalDataStore().addItem(newItem);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final assignedItems = allItems
        .where((item) =>
            item.assignedStaff != null && item.assignedStaff!.isNotEmpty)
        .length;
    final unassignedItems = allItems.length - assignedItems;
    final taggedItems = allItems.where((item) => item.isTagged).length;
    final upcomingReminders = dataStore.reminders
        .where((r) => r.dateTime.isAfter(DateTime.now()))
        .length;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Operator Dashboard',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Overview'),
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
                      'Total Items',
                      allItems.length.toString(),
                      Icons.inventory_2_outlined,
                      Colors.blue.shade700),
                  _buildStatCard(
                      theme,
                      'Assigned Items',
                      assignedItems.toString(),
                      Icons.person_pin_circle_outlined,
                      Colors.green.shade700),
                  _buildStatCard(
                      theme,
                      'Unassigned Items',
                      unassignedItems.toString(),
                      Icons.person_pin_circle,
                      Colors.orange.shade700),
                  _buildStatCard(theme, 'Tagged Items', taggedItems.toString(),
                      Icons.qr_code_2, Colors.purple.shade700),
                  _buildStatCard(theme, 'Issues', openIssues.length.toString(),
                      Icons.report_problem_outlined, Colors.red.shade700),
                  _buildStatCard(
                      theme,
                      'Reminders',
                      upcomingReminders.toString(),
                      Icons.notifications_active_outlined,
                      Colors.teal.shade700),
                ],
              ),
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
                            value: Provider.of<LocalDataStore>(context,
                                listen: false),
                            child: FilteredItemsScreen(
                                items: allItems, onUpdateItem: onUpdateItem))));
                  }),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(theme, 'My Recent Activity'),
              const SizedBox(height: 16),
              recentHistory.isEmpty
                  ? Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('No recent activity.')),
                      ),
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
}
