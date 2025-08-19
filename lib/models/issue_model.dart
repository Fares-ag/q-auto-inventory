// issue_model.dart

// Import the cloud_firestore package to interact with Google Firebase Firestore.
// This is necessary for using Firestore-specific classes like 'Timestamp'.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines the possible states an issue can be in.
/// Using an enum provides type safety and prevents invalid status values.
enum IssueStatus { Open, InProgress, Resolved, Closed }

/// Defines the priority levels for an issue.
enum IssuePriority { Low, Medium, High, Critical }

/// A data model class representing a single issue.
/// This class encapsulates all the properties and logic related to an issue.
class Issue {
  // --- Properties ---

  /// The unique identifier for the issue, typically the Firestore document ID.
  final String issueId;

  /// The ID of the item or asset this issue is associated with.
  final String itemId;

  /// A detailed description of the problem or issue.
  final String description;

  /// The priority level of the issue (e.g., Low, Medium, High).
  final IssuePriority priority;

  /// The current status of the issue (e.g., Open, InProgress).
  final IssueStatus status;

  /// The ID of the user who reported the issue.
  final String reporterId;

  /// An optional URL to an image or file attached to the issue.
  /// The '?' indicates that this can be null if there's no attachment.
  final String? attachmentUrl;

  /// The timestamp when the issue was created.
  final DateTime createdAt;

  // --- Constructor ---

  /// Creates an instance of the Issue class.
  Issue({
    required this.issueId,
    required this.itemId,
    required this.description,
    required this.priority,
    // The status defaults to 'Open' if not specified.
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
