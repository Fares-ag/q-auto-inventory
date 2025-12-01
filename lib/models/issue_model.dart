/// Data model for an issue report.
class Issue {
  final String issueId;
  final String description;
  final String priority;
  final String status;
  final String reporter;
  final DateTime createdAt;

  Issue({
    required this.issueId,
    required this.description,
    required this.priority,
    required this.status,
    required this.reporter,
    required this.createdAt,
  });
}


