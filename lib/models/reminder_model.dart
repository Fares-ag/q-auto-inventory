// lib/models/reminder_model.dart

import 'package:flutter/material.dart';

enum RepeatFrequency {
  none,
  daily,
  weekly,
  fortnightly,
  monthly,
  halfYearly,
  yearly
}

class Reminder {
  final String id;
  final String itemId;
  final String name;
  final DateTime dateTime;
  final RepeatFrequency repeat;

  Reminder({
    required this.id,
    required this.itemId,
    required this.name,
    required this.dateTime,
    this.repeat = RepeatFrequency.none,
  });
}

class Comment {
  final String id;
  final String itemId;
  final String description;
  final String authorEmail;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.itemId,
    required this.description,
    required this.authorEmail,
    required this.timestamp,
  });
}
