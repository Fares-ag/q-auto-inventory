import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for attachments on items.
class Attachment {
  final String id;
  final String name;
  final String? url;
  final DateTime timestamp;

  Attachment({
    required this.id,
    required this.name,
    this.url,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map, String id) {
    return Attachment(
      id: id,
      name: map['name'] ?? '',
      url: map['url'],
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


