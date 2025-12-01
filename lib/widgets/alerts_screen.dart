import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/services/item_service.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: const Text(
            'Alerts',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: ItemService.getItemsStream(),
        builder: (context, itemsSnapshot) {
          if (itemsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (itemsSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading alerts: ${itemsSnapshot.error}',
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            );
          }

          final items = itemsSnapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryChip(
                        label: 'Issues',
                        icon: Icons.report_gmailerrorred_outlined,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryChip(
                        label: 'Maintenance',
                        icon: Icons.build_outlined,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryChip(
                        label: 'Untagged',
                        icon: Icons.qr_code_scanner_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // High Priority Issues Section
                _buildSectionHeader(
                  title: 'High Priority Issues',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 12),
                _buildIssuesList(items),
                const SizedBox(height: 24),

                // Maintenance Alerts
                _buildSectionHeader(
                  title: 'Maintenance Required',
                  icon: Icons.build_rounded,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(height: 12),
                _buildMaintenanceAlerts(items, context),
                const SizedBox(height: 24),

                // Condition Alerts
                _buildSectionHeader(
                  title: 'Poor Condition Items',
                  icon: Icons.health_and_safety_rounded,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(height: 12),
                _buildConditionAlerts(items, context),
                const SizedBox(height: 24),

                // Untagged Items
                _buildSectionHeader(
                  title: 'Untagged Items',
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 12),
                _buildUntaggedItems(items, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesList(List<ItemModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState('No items found');
    }

    // Get issues from first few items for demo
    // In production, you might want to aggregate all issues
    if (items.isEmpty) {
      return _buildEmptyState('No high priority issues');
    }

    // Show issues from first item as example
    return StreamBuilder<List<Issue>>(
      stream: ItemDetailsService.getIssuesStream(items.first.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final issues = snapshot.data ?? [];
        final highPriorityIssues = issues
            .where((issue) => issue.priority == 'High')
            .toList();

        if (highPriorityIssues.isEmpty) {
          return _buildEmptyState('No high priority issues');
        }

        // For now, show issues from first item
        // In production, you'd want to aggregate issues from all items
        final item = items.isNotEmpty ? items.first : null;
        if (item == null) {
          return _buildEmptyState('No items found');
        }

        return Column(
          children: highPriorityIssues.map((issue) {
            return _buildIssueCard(issue, item);
          }).toList(),
        );
      },
    );
  }

  Widget _buildIssueCard(Issue issue, ItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.2),
          width: 1,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HIGH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(issue.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceAlerts(List<ItemModel> items, BuildContext context) {
    final maintenanceItems = items.where((item) {
      return item.status == 'Maintenance' || item.status == 'Offline';
    }).toList();

    if (maintenanceItems.isEmpty) {
      return _buildEmptyState('No maintenance alerts');
    }

    return Column(
      children: maintenanceItems.map((item) {
        return _buildItemAlertCard(
          item: item,
          title: 'Maintenance Required',
          subtitle: 'Status: ${item.status}',
          color: AppTheme.warningColor,
          onTap: () => _navigateToItemDetails(context, item),
        );
      }).toList(),
    );
  }

  Widget _buildConditionAlerts(List<ItemModel> items, BuildContext context) {
    final poorConditionItems = items.where((item) {
      return item.condition == 'Poor' || item.condition == 'Fair';
    }).toList();

    if (poorConditionItems.isEmpty) {
      return _buildEmptyState('No condition alerts');
    }

    return Column(
      children: poorConditionItems.map((item) {
        return _buildItemAlertCard(
          item: item,
          title: 'Condition Alert',
          subtitle: 'Condition: ${item.condition}',
          color: AppTheme.warningColor,
          onTap: () => _navigateToItemDetails(context, item),
        );
      }).toList(),
    );
  }

  Widget _buildUntaggedItems(List<ItemModel> items, BuildContext context) {
    final untaggedItems = items.where((item) => !item.isTagged).toList();

    if (untaggedItems.isEmpty) {
      return _buildEmptyState('All items are tagged');
    }

    return Column(
      children: untaggedItems.map((item) {
        return _buildItemAlertCard(
          item: item,
          title: 'Not Tagged',
          subtitle: 'This item needs a QR code',
          color: AppTheme.textSecondary,
          onTap: () => _navigateToItemDetails(context, item),
        );
      }).toList(),
    );
  }

  Widget _buildItemAlertCard({
    required ItemModel item,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }

  void _navigateToItemDetails(BuildContext context, ItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(
          item: item,
          onUpdateItem: (updatedItem) {
            // Item update will be handled by Firestore stream
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

