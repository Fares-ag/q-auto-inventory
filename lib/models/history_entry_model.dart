// lib/widgets/history_entry_model.dart

import 'package:flutter/material.dart';

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
