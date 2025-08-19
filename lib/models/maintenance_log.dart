// lib/models/maintenance_log.dart

// Import the Flutter Material library. Although not used directly in this model,
// it's a standard import for most Flutter files.
import 'package:flutter/material.dart';

/// A data model class that represents a single maintenance log entry for an item.
/// This class holds all the information related to one maintenance event.
class MaintenanceLog {
  // --- Properties ---

  /// The unique identifier for this specific log entry.
  final String id;

  /// The ID of the item that was serviced. This links the log back to an [ItemModel].
  final String itemId;

  /// A description of the maintenance work that was performed.
  final String description;

  /// The name of the vendor or technician who performed the maintenance.
  final String vendor;

  /// The cost of the maintenance service.
  final double cost;

  /// The date when the maintenance was performed.
  final DateTime maintenanceDate;

  // --- Constructor ---

  /// Creates an instance of the [MaintenanceLog] class.
  /// All parameters are marked as 'required', meaning they must be provided
  /// when creating a new maintenance log.
  MaintenanceLog({
    required this.id,
    required this.itemId,
    required this.description,
    required this.vendor,
    required this.cost,
    required this.maintenanceDate,
  });
}
