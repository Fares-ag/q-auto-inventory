import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Notifications')),
      body: FutureBuilder<_AlertsData>(
        future: _loadAlertsData(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load alerts: ${snapshot.error}'));
          }
          final data = snapshot.data ?? const _AlertsData();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Open Issues (${data.openIssues.length})',
                child: data.openIssues.isEmpty
                    ? const _EmptyState(message: 'No open issues.')
                    : Column(
                        children: data.openIssues
                            .map((issue) => _IssueTile(issue: issue))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Upcoming Reminders (${data.upcomingReminders.length})',
                child: data.upcomingReminders.isEmpty
                    ? const _EmptyState(message: 'No upcoming reminders.')
                    : Column(
                        children: data.upcomingReminders
                            .map((reminder) => _ReminderTile(reminder: reminder))
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_AlertsData> _loadAlertsData(BuildContext context) async {
    final issueService = context.read<IssueService>();
    final issues = await issueService.listOpenIssues(limit: 20);
    // Reminder data is not yet modelled; return empty list for now.
    return _AlertsData(openIssues: issues, upcomingReminders: const []);
  }
}

class _AlertsData {
  const _AlertsData({this.openIssues = const [], this.upcomingReminders = const []});

  final List<Issue> openIssues;
  final List<ReminderInfo> upcomingReminders;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(issue.title),
      subtitle: Text('Priority: ${issue.priority ?? 'Unknown'}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final ReminderInfo reminder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reminder.title),
      subtitle:
          Text(reminder.dueDate != null ? reminder.dueDate!.toLocal().toString() : 'No due date'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}

class ReminderInfo {
  const ReminderInfo({required this.title, this.dueDate});

  final String title;
  final DateTime? dueDate;
}
