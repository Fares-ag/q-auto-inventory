import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/widgets/common/stat_card.dart';
import 'package:flutter_application_1/widgets/common/history_entry_card.dart';
import 'package:flutter_application_1/widgets/common/issue_card.dart';
import 'package:flutter_application_1/widgets/common/section_header.dart';

/// Dashboard screen that provides a high-level overview of inventory statistics
class DashboardScreen extends StatelessWidget {
  final List<ItemModel> allItems;
  final List<HistoryEntry> recentHistory;
  final List<Issue> openIssues;
  final VoidCallback onNavigateToItems;

  const DashboardScreen({
    super.key,
    required this.allItems,
    required this.recentHistory,
    required this.openIssues,
    required this.onNavigateToItems,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dashboard metrics
    final int totalItems = allItems.length;
    final int taggedItems = allItems.where((item) => item.isTagged).length;
    final int writtenOffItems =
        allItems.where((item) => item.isWrittenOff).length;
    final int issueCount = openIssues.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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
                  StatCard(
                    title: 'Total Items',
                    value: totalItems.toString(),
                    icon: Icons.inventory_2,
                    gradient: AppTheme.primaryGradient,
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    title: 'Tagged Items',
                    value: taggedItems.toString(),
                    icon: Icons.label,
                    gradient: AppTheme.accentGradient,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  StatCard(
                    title: 'Open Issues',
                    value: issueCount.toString(),
                    icon: Icons.warning,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.errorColor,
                        AppTheme.errorColor.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    title: 'Written Off',
                    value: writtenOffItems.toString(),
                    icon: Icons.delete_forever,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.textTertiary,
                        AppTheme.textTertiary.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Recent Activity
              const SectionHeader(title: 'Recent Activity'),
              const SizedBox(height: 20),
              Column(
                children: recentHistory
                    .take(3)
                    .map((entry) => HistoryEntryCard(entry: entry))
                    .toList(),
              ),
              const SizedBox(height: 40),
              // Open Issues
              const SectionHeader(title: 'Open Issues'),
              const SizedBox(height: 20),
              Column(
                children: openIssues
                    .map((issue) => IssueCard(issue: issue))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
