// lib/widgets/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/reminder_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/issue_details_screen.dart';
import 'package:provider/provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Connect to the central data store to get live data
    final dataStore = Provider.of<LocalDataStore>(context);

    // Filter for open issues from the data store
    final openIssues =
        dataStore.issues.where((i) => i.status == IssueStatus.Open).toList();

    // Filter for upcoming reminders from the data store
    final upcomingReminders = dataStore.reminders
        .where((r) => r.dateTime.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(theme, 'Open Issues (${openIssues.length})'),
            const SizedBox(height: 16),
            openIssues.isEmpty
                ? _buildEmptyStateCard('No open issues.')
                : Column(
                    children: openIssues
                        .map((issue) =>
                            _buildIssueCard(context, issue, dataStore))
                        .toList(),
                  ),
            const SizedBox(height: 32),
            _buildSectionTitle(
                theme, 'Upcoming Reminders (${upcomingReminders.length})'),
            const SizedBox(height: 16),
            upcomingReminders.isEmpty
                ? _buildEmptyStateCard('No upcoming reminders.')
                : Column(
                    children: upcomingReminders
                        .map((reminder) => _buildReminderCard(reminder))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style: theme.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildEmptyStateCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(message, style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildIssueCard(
      BuildContext context, Issue issue, LocalDataStore dataStore) {
    // Find the user who reported the issue to display their name
    final reporter = dataStore.users.firstWhere(
        (user) => user.id == issue.reporterId,
        orElse: () => LocalUser(
            id: '', name: 'Unknown', email: '', roleId: '', department: ''));
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child:
              Icon(Icons.report_problem_outlined, color: Colors.red.shade700),
        ),
        title: Text(issue.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Priority: ${issue.priority.name}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => IssueDetailsScreen(
              issue: issue,
              reporter: reporter,
            ),
          ));
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Icon(Icons.notifications_active_outlined,
              color: Colors.orange.shade700),
        ),
        title: Text(reminder.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Due: ${reminder.dateTime.toLocal().toString().split(' ')[0]}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // In a real app, you might navigate to the item's detail screen
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tapped on reminder: ${reminder.name}'),
          ));
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
