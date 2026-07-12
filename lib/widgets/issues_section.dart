import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/firestore_models.dart';
import '../theme/app_theme.dart';
import '../services/firebase_services.dart';
import '../utils/date_formatter.dart';
import 'empty_state.dart';

class IssuesSection extends StatefulWidget {
  const IssuesSection({super.key, required this.itemId});

  final String itemId;

  @override
  State<IssuesSection> createState() => _IssuesSectionState();
}

class _IssuesSectionState extends State<IssuesSection> {
  Future<void> _showAddIssueDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final issueService = context.read<IssueService>();
        final issue = Issue(
          id: '',
          itemId: widget.itemId,
          title: titleController.text.trim(),
          status: 'open',
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          priority: 'medium',
          reportedBy: user?.uid ?? user?.email ?? 'anonymous',
          createdAt: DateTime.now(),
        );
        await issueService.createIssue(issue);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue reported')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reporting issue: $e')),
          );
        }
      }
    }
  }

  Future<void> _resolveIssue(String issueId) async {
    try {
      final issueService = context.read<IssueService>();
      await issueService.resolveIssue(issueId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue resolved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resolving issue: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueService = context.read<IssueService>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<Issue>>(
          future: issueService.getItemIssues(widget.itemId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final issues = snapshot.data ?? [];
            if (issues.isEmpty) {
              return const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'No Issues',
                message: 'This item has no reported issues',
              );
            }
            return Column(
              children: issues.map((issue) {
                final isOpen = issue.status == 'open';
                final errorColor = Theme.of(context).colorScheme.error;
                final successColor = AppTheme.success;
                return RepaintBoundary(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isOpen 
                        ? errorColor.withOpacity(0.08) 
                        : successColor.withOpacity(0.08),
                    child: ListTile(
                      leading: Icon(
                        isOpen ? Icons.warning : Icons.check_circle,
                        color: isOpen ? errorColor : successColor,
                      ),
                      title: Text(issue.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issue.description != null && issue.description!.isNotEmpty)
                            Text(issue.description!),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(issue.status.toUpperCase()),
                                backgroundColor: isOpen 
                                    ? errorColor.withOpacity(0.15) 
                                    : successColor.withOpacity(0.15),
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen ? errorColor : successColor,
                                ),
                              ),
                              if (issue.createdAt != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  DateFormatter.formatRelative(issue.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: isOpen
                          ? IconButton(
                              icon: Icon(Icons.check_circle, color: successColor),
                              tooltip: 'Resolve Issue',
                              onPressed: () => _resolveIssue(issue.id),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showAddIssueDialog,
          icon: const Icon(Icons.report_problem),
          label: const Text('Report Issue'),
        ),
      ],
    );
  }
}

