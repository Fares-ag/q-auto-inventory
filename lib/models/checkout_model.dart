import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for checkout/assignment records.
class Checkout {
  final String id;
  final String assignedFrom;
  final String assignedTo;
  final String admin;
  final DateTime returnDate;
  final DateTime timestamp;
  final String? attachmentUrl;

  Checkout({
    required this.id,
    required this.assignedFrom,
    required this.assignedTo,
    required this.admin,
    required this.returnDate,
    required this.timestamp,
    this.attachmentUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignedFrom': assignedFrom,
      'assignedTo': assignedTo,
      'admin': admin,
      'returnDate': Timestamp.fromDate(returnDate),
      'timestamp': Timestamp.fromDate(timestamp),
      'attachmentUrl': attachmentUrl,
    };
  }

  factory Checkout.fromMap(Map<String, dynamic> map, String id) {
    return Checkout(
      id: id,
      assignedFrom: map['assignedFrom'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      admin: map['admin'] ?? '',
      returnDate:
          (map['returnDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrl: map['attachmentUrl'],
    );
  }
}


