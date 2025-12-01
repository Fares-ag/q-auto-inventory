import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/issue_model.dart';

/// A reusable card widget for displaying issues in item details
class ItemIssueCard extends StatelessWidget {
  final Issue issue;

  const ItemIssueCard({
    super.key,
    required this.issue,
  });

  @override
  Widget build(BuildContext context) {
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
}

