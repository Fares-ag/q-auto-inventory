import 'package:flutter/material.dart';

/// Data model for a single history entry.
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


