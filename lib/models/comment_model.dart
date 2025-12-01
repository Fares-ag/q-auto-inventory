import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for comments on items.
class Comment {
  final String id;
  final String text;
  final String author;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      text: map['text'] ?? '',
      author: map['author'] ?? '',
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


