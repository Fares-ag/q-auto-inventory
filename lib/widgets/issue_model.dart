import 'dart:io';

// This data model class defines the structure for an issue report.
class Issue {
  final String issueId;
  final String description;
  final String priority;
  final String status;
  final String reporter;
  final File? attachment;
  final DateTime createdAt;

  Issue({
    required this.issueId,
    required this.description,
    required this.priority,
    this.status = 'Open', // Default status for a new issue.
    this.reporter = 'Charlotte', // Fixed reporter name.
    this.attachment,
    required this.createdAt,
  });
}
