// lib/widgets/issue_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/reminder_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class IssueDetailsScreen extends StatefulWidget {
  final Issue issue;
  final LocalUser reporter;

  const IssueDetailsScreen({
    Key? key,
    required this.issue,
    required this.reporter,
  }) : super(key: key);

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        );
      },
    );
  }

  void _showAddCommentDialog(IssueStatus newStatus) {
    final commentController = TextEditingController();
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration:
              const InputDecoration(hintText: 'Explain the status change...'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                // Update the status first
                dataStore.updateIssueStatus(widget.issue.issueId, newStatus);
                // Then add the related comment
                dataStore.addComment(Comment(
                  id: 'com_${DateTime.now().millisecondsSinceEpoch}',
                  itemId: widget.issue.itemId,
                  description: commentController.text,
                  authorEmail: dataStore.currentUser.email,
                  timestamp: DateTime.now(),
                ));
                Navigator.of(context).pop(); // Close comment dialog
                Navigator.of(context).pop(); // Close status dialog
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Update Issue Status'),
          children: [
            SimpleDialogOption(
                onPressed: () => _showAddCommentDialog(IssueStatus.Fixed),
                child: const Text('Fixed')),
            SimpleDialogOption(
                onPressed: () => _showAddCommentDialog(IssueStatus.NotAnIssue),
                child: const Text('Not an Issue')),
            SimpleDialogOption(
                onPressed: () =>
                    _showAddCommentDialog(IssueStatus.CreatedByError),
                child: const Text('Created by Error')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use Provider.of here to listen for changes
    final dataStore = Provider.of<LocalDataStore>(context);
    final bool canUpdateStatus = widget.issue.status == IssueStatus.Open ||
        widget.issue.status == IssueStatus.InProgress;

    // Filter comments for this specific item
    final itemComments = dataStore.comments
        .where((c) => c.itemId == widget.issue.itemId)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Issue Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Description Card ---
            _buildInfoCard(
              theme: theme,
              title: 'Description',
              child: Text(
                widget.issue.description,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // --- Details Card ---
            _buildInfoCard(
              theme: theme,
              title: 'Details',
              child: Column(
                children: [
                  _buildDetailRow(
                      theme, Icons.tag, 'Issue ID:', widget.issue.issueId),
                  const Divider(),
                  _buildDetailRow(theme, Icons.person_outline, 'Reported By:',
                      widget.reporter.name),
                  const Divider(),
                  _buildDetailRow(theme, Icons.priority_high, 'Priority:',
                      widget.issue.priority.name),
                  const Divider(),
                  _buildDetailRow(theme, Icons.task_alt, 'Status:',
                      widget.issue.status.name),
                  const Divider(),
                  _buildDetailRow(
                      theme,
                      Icons.calendar_today_outlined,
                      'Date Reported:',
                      "${widget.issue.createdAt.toLocal()}".split(' ')[0]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Attachment Card ---
            _buildInfoCard(
              theme: theme,
              title: 'Attachment',
              child: widget.issue.attachmentUrl != null &&
                      File(widget.issue.attachmentUrl!).existsSync()
                  ? GestureDetector(
                      onTap: () =>
                          _showFullImage(context, widget.issue.attachmentUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(widget.issue.attachmentUrl!),
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No Attachment Provided',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // --- Comments Card ---
            _buildInfoCard(
              theme: theme,
              title: 'Comments (${itemComments.length})',
              child: Column(
                children: itemComments.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: Text("No comments yet.")),
                        )
                      ]
                    : itemComments.map((comment) {
                        // Find the user who wrote the comment
                        final author = dataStore.users.firstWhere(
                            (user) => user.email == comment.authorEmail,
                            orElse: () => LocalUser(
                                id: '',
                                name: 'Unknown User',
                                email: '',
                                roleId: '',
                                department: ''));
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[200]!)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(comment.description),
                            subtitle: Text(
                                'By: ${author.name} on ${comment.timestamp.toLocal().toString().split(' ')[0]}'),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // --- Action Button ---
            if (canUpdateStatus)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showUpdateStatusDialog,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Update Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required ThemeData theme,
      required String title,
      required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
