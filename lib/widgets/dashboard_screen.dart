import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/item_model.dart';
import 'package:flutter_application_1/widgets/history_entry_model.dart';
import 'package:flutter_application_1/widgets/issue_model.dart';

// This is the new dashboard screen that provides a high-level overview.
class DashboardScreen extends StatelessWidget {
  final List<ItemModel> allItems;
  final List<HistoryEntry> recentHistory;
  final List<Issue> openIssues;
  final VoidCallback onNavigateToItems;

  const DashboardScreen({
    Key? key,
    required this.allItems,
    required this.recentHistory,
    required this.openIssues,
    required this.onNavigateToItems,
  }) : super(key: key);

  // Helper function to build a stat card.
  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build a quick action button.
  Widget _buildQuickActionButton(BuildContext context, String title,
      IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build a history entry card.
  Widget _buildHistoryEntryCard(HistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, size: 24, color: Colors.blue),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} at ${entry.timestamp.hour}:${entry.timestamp.minute}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build an issue card.
  Widget _buildIssueCard(Issue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Priority: ${issue.priority}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Status: ${issue.status}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(issue.description),
          const SizedBox(height: 8),
          Text(
            'Issue ID: ${issue.issueId}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Reporter: ${issue.reporter}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dashboard metrics
    final int totalItems = allItems.length;
    final int taggedItems = allItems.where((item) => item.isTagged).length;
    final int writtenOffItems =
        allItems.where((item) => item.isWrittenOff).length;
    final int issueCount = openIssues.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards
              Row(
                children: [
                  _buildStatCard(context, 'Total Items', totalItems.toString(),
                      Icons.inventory_2, Colors.purple),
                  const SizedBox(width: 16),
                  _buildStatCard(context, 'Tagged Items',
                      taggedItems.toString(), Icons.label, Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(context, 'Open Issues', issueCount.toString(),
                      Icons.warning, Colors.red),
                  const SizedBox(width: 16),
                  _buildStatCard(
                      context,
                      'Written Off',
                      writtenOffItems.toString(),
                      Icons.delete_forever,
                      Colors.grey),
                ],
              ),
              const SizedBox(height: 40),
              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: recentHistory
                    .take(3) // Display a limited number of recent activities
                    .map((entry) => _buildHistoryEntryCard(entry))
                    .toList(),
              ),
              const SizedBox(height: 40),
              // Open Issues
              const Text(
                'Open Issues',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children:
                    openIssues.map((issue) => _buildIssueCard(issue)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
