// issue_model.dart

// Import the cloud_firestore package to interact with Google Firebase Firestore.
// This is necessary for using Firestore-specific classes like 'Timestamp'.
import 'package:cloud_firestore/cloud_firestore.dart';

enum IssueStatus { Open, InProgress, Fixed, NotAnIssue, CreatedByError, Closed }

enum IssuePriority { Low, Medium, High, Critical }

class Issue {
  final String issueId;
  final String itemId;
  final String description;
  final IssuePriority priority;
  IssueStatus status; // Made this non-final to allow updates
  final String reporterId;
  final String? attachmentUrl;
  final DateTime createdAt;

  Issue({
    required this.issueId,
    required this.itemId,
    required this.description,
    required this.priority,
    this.status = IssueStatus.Open,
    required this.reporterId,
    this.attachmentUrl,
    required this.createdAt,
  });

  // --- Methods for Firestore Serialization/Deserialization ---

  /// Converts the [Issue] object into a Map<String, dynamic>.
  /// This format is required for writing data to a Firestore document.
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'description': description,
      // Convert enums to their string representation (e.g., IssuePriority.High becomes "High").
      'priority': priority.name,
      'status': status.name,
      'reporterId': reporterId,
      'attachmentUrl': attachmentUrl,
      // Convert the Dart DateTime object to a Firestore Timestamp for storage.
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// A factory constructor to create an [Issue] instance from a Firestore document.
  /// 'factory' means this constructor doesn't always create a new instance of its class.
  factory Issue.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Issue(
      // The issueId is taken from the document's ID in Firestore.
      issueId: documentId,
      // Use the null-coalescing operator '??' to provide a default empty string if data is null.
      itemId: data['itemId'] ?? '',
      description: data['description'] ?? '',
      // Safely parse the priority string from Firestore back into an IssuePriority enum.
      // If the value is invalid or null, it defaults to 'Medium'.
      priority: IssuePriority.values.firstWhere(
          (e) => e.name == data['priority'],
          orElse: () => IssuePriority.Medium),
      // Safely parse the status string from Firestore back into an IssueStatus enum.
      // If the value is invalid or null, it defaults to 'Open'.
      status: IssueStatus.values.firstWhere((e) => e.name == data['status'],
          orElse: () => IssueStatus.Open),
      reporterId: data['reporterId'] ?? '',
      // attachmentUrl can be null, so no default value is needed.
      attachmentUrl: data['attachmentUrl'],
      // Convert the Firestore Timestamp back to a Dart DateTime object.
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
