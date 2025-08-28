// lib/models/history_entry_model.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';

class HistoryEntry {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData? icon;
  final String actorId;
  final String actorEmail;
  final String? targetId;

  // Fields to store signature images
  final Uint8List? assigneeSignature;
  final Uint8List? operatorSignature;

  HistoryEntry({
    required this.title,
    required this.description,
    required this.timestamp,
    this.icon,
    required this.actorId,
    required this.actorEmail,
    this.targetId,
    this.assigneeSignature,
    this.operatorSignature,
  });
}
