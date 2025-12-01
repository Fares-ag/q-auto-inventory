import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for information entries on items.
class Information {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  Information({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Information.fromMap(Map<String, dynamic> map, String id) {
    return Information(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


