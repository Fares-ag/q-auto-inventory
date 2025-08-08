import 'package:flutter/material.dart';

// This data model class defines the structure for a single history entry.
class HistoryEntry {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData? icon;

  HistoryEntry({
    required this.title,
    required this.description,
    required this.timestamp,
    this.icon,
  });
}
