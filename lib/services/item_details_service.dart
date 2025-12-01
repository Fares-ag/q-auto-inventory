import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/comment_model.dart';
import 'package:flutter_application_1/models/attachment_model.dart';
import 'package:flutter_application_1/models/information_model.dart';

/// Service class to handle item details operations

/// Service class to handle item details operations
class ItemDetailsService {
  static const String _itemsCollection = 'items';
  static const String _commentsSubcollection = 'comments';
  static const String _attachmentsSubcollection = 'attachments';
  static const String _historySubcollection = 'history';
  static const String _informationSubcollection = 'information';
  static const String _issuesSubcollection = 'issues';

  // Comments
  static Stream<List<Comment>> getCommentsStream(String itemId) {
    return FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_commentsSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<String> addComment(String itemId, Comment comment) async {
    final docRef = await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_commentsSubcollection)
        .add(comment.toMap());
    return docRef.id;
  }

  // Attachments
  static Stream<List<Attachment>> getAttachmentsStream(String itemId) {
    return FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_attachmentsSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Attachment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<String> addAttachment(String itemId, Attachment attachment) async {
    final docRef = await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_attachmentsSubcollection)
        .add(attachment.toMap());
    return docRef.id;
  }

  static Future<void> updateAttachment(String itemId, String attachmentId, String url) async {
    await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_attachmentsSubcollection)
        .doc(attachmentId)
        .update({'url': url});
  }

  // History
  static Stream<List<HistoryEntry>> getHistoryStream(String itemId) {
    return FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_historySubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HistoryEntry(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          icon: null, // Icons are not stored in Firestore
        );
      }).toList();
    });
  }

  static Future<String> addHistoryEntry(String itemId, HistoryEntry entry) async {
    final docRef = await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_historySubcollection)
        .add({
      'title': entry.title,
      'description': entry.description,
      'timestamp': Timestamp.fromDate(entry.timestamp),
    });
    return docRef.id;
  }

  // Information
  static Stream<List<Information>> getInformationStream(String itemId) {
    return FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_informationSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Information.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<String> addInformation(String itemId, Information information) async {
    final docRef = await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_informationSubcollection)
        .add(information.toMap());
    return docRef.id;
  }

  // Issues
  static Stream<List<Issue>> getIssuesStream(String itemId) {
    return FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_issuesSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Issue(
          issueId: doc.id,
          description: data['description'] ?? '',
          priority: data['priority'] ?? '',
          status: data['status'] ?? '',
          reporter: data['reporter'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  static Future<String> addIssue(String itemId, Issue issue) async {
    final docRef = await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_issuesSubcollection)
        .add({
      'description': issue.description,
      'priority': issue.priority,
      'status': issue.status,
      'reporter': issue.reporter,
      'createdAt': Timestamp.fromDate(issue.createdAt),
    });
    return docRef.id;
  }

  // Checkout/Assignment
  static const String _checkoutsSubcollection = 'checkouts';

  static Future<String> addCheckout({
    required String itemId,
    required String assignedFrom,
    required String assignedTo,
    required String admin,
    required DateTime returnDate,
    String? attachmentUrl,
  }) async {
    final docRef = await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_checkoutsSubcollection)
        .add({
      'assignedFrom': assignedFrom,
      'assignedTo': assignedTo,
      'admin': admin,
      'returnDate': Timestamp.fromDate(returnDate),
      'checkoutDate': FieldValue.serverTimestamp(),
      'attachmentUrl': attachmentUrl,
      'status': 'Active', // Active, Returned, Overdue
    });
    return docRef.id;
  }

  static Stream<List<Map<String, dynamic>>> getCheckoutsStream(String itemId) {
    return FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_checkoutsSubcollection)
        .where('status', isEqualTo: 'Active')
        .orderBy('checkoutDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  static Future<void> returnCheckout(String itemId, String checkoutId) async {
    await FirebaseService.firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .collection(_checkoutsSubcollection)
        .doc(checkoutId)
        .update({
      'status': 'Returned',
      'returnedDate': FieldValue.serverTimestamp(),
    });
  }
}

