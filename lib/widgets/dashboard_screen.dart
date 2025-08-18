import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/approval_queue_screen.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

/// Main dashboard screen for operators.
/// Displays key statistics, quick actions, and recent activity.
class DashboardScreen extends StatelessWidget {
  final List<ItemModel> allItems; // List of all items in the system
  final List<Issue> openIssues; // List of currently open issues
  final List<HistoryEntry> recentHistory; // Recent user activity entries
  final VoidCallback onNavigateToItems; // Callback for navigating to item list
  final Function(ItemModel) onUpdateItem; // Callback when an item is updated

  const DashboardScreen({
    Key? key,
    required this.allItems,
    required this.openIssues,
    required this.recentHistory,
    required this.onNavigateToItems,
    required this.onUpdateItem,
  }) : super(key: key);

  /// Opens the Add Item modal as a bottom sheet
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
          onClose: () => Navigator.of(context).pop(), // Close modal
          onSave: (newItem) {
            // Save new item to local datastore and close modal
            LocalDataStore().addItem(newItem);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Navigates to the approval queue screen
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
    // Count of items not yet tagged
    final untaggedItems = allItems.where((item) => !item.isTagged).length;
    final theme = Theme.of(context);
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main dashboard title
              Text('Operator Dashboard',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Section: Attention Required
              _buildSectionTitle(theme, 'Attention Required'),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2, // Two cards per row
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent scrolling inside GridView
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  // Individual stat cards
                  _buildStatCard(theme, 'Assets Due Back', '3',
                      Icons.assignment_return_outlined, Colors.orange),
                  _buildStatCard(
                      theme,
                      'Assigned Issues',
                      openIssues.length.toString(),
                      Icons.report_problem_outlined,
                      Colors.red),
                  _buildStatCard(
                      theme,
                      'Untagged Items',
                      untaggedItems.toString(),
                      Icons.label_off_outlined,
                      Colors.blue),
                ],
              ),
              const SizedBox(height: 32),

              // Section: Quick Actions
              _buildSectionTitle(theme, 'Quick Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Quick action buttons
                  _buildQuickAction(theme, 'Add Item', Icons.add_box_outlined,
                      Colors.green, () => _showAddItemModal(context)),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                      theme,
                      'View Pending',
                      Icons.playlist_add_check_circle,
                      Colors.purple,
                      () => _navigateToApprovalQueue(context)),
                  const SizedBox(width: 16),
                  _buildQuickAction(theme, 'View All',
                      Icons.inventory_2_outlined, Colors.blueGrey, () {
                    // Navigate to FilteredItemsScreen
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                            value: LocalDataStore(),
                            child: FilteredItemsScreen(
                                items: allItems, onUpdateItem: onUpdateItem))));
                  }),
                ],
              ),
              const SizedBox(height: 32),

              // Section: Recent Activity
              _buildSectionTitle(theme, 'My Recent Activity'),
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

  /// Builds a section title widget
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600));
  }

  /// Builds a statistic card with icon, value, and title
  Widget _buildStatCard(
      ThemeData theme, String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 28),
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

  /// Builds a quick action card (tapable)
  Widget _buildQuickAction(ThemeData theme, String title, IconData icon,
      Color color, VoidCallback onTap) {
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
              Icon(icon, color: color, size: 28),
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

  /// Builds a card for a single recent history entry
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
}
