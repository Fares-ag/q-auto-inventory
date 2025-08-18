// lib/models/item_model.dart

// Import the Flutter Material library. While not strictly necessary for this data model,
// it's a common import in Flutter apps and might be needed if you add UI-related
// logic (like icons for item types) to this model in the future.
import 'package:flutter/material.dart';

/// Defines a set of predefined types for an item.
/// Using an enum prevents typos and ensures that the item type is always one of these valid options.
enum ItemType {
  laptop,
  keyboard,
  monitor,
  tablet,
  webcam,
  furniture,
  other,
}

/// A data model class that represents a single inventory item or asset.
/// This class is immutable, meaning its properties cannot be changed after creation.
/// To "update" an item, you create a new instance using the `copyWith` method.
class ItemModel {
  // --- Core Item Properties ---
  final String id; // Unique identifier for the item.
  final String name; // The display name of the item (e.g., "Dell XPS 15").
  final String category; // The general category (e.g., "Electronics").
  final ItemType itemType; // The specific type, using the ItemType enum.
  final DateTime purchaseDate; // When the item was purchased.
  final String variants; // Describes variations like color or size.
  final String supplier; // The supplier or vendor who provided the item.
  final String company; // The company that owns the asset.
  final String? qrCodeId; // Optional ID associated with a QR code.
  final String
      status; // The approval status of the item (e.g., 'approved', 'pending').

  // --- Status Flags ---
  final bool isTagged; // True if a physical asset tag has been applied.
  final bool
      isWrittenOff; // True if the item has been decommissioned or written off.
  final bool isAvailable; // True if the item is available for assignment.

  // --- Assignment and Maintenance Properties (Optional) ---
  final String? department; // Department the item is assigned to.
  final String? assignedStaff; // Staff member the item is assigned to.
  final double? purchasePrice; // The original cost of the item.
  final DateTime? lastMaintenanceDate; // Date of the last maintenance check.
  final String?
      maintenanceSchedule; // Describes the maintenance frequency (e.g., "Yearly").
  final double? currentValue; // The current depreciated value of the item.
  final DateTime?
      nextMaintenanceDate; // Date for the next scheduled maintenance.

  // --- SAP / ERP System Specific Properties (Optional) ---
  final String? coCd; // Company Code
  final String? sapClass; // SAP classification
  final String? assetClassDesc; // Description of the asset class
  final String? apcAcct; // APC Account
  final String? licPlate; // License Plate (for vehicles)
  final String? vendor; // Vendor information
  final String? plnt; // Plant code
  final String? modelCode; // Specific model code
  final String? modelDesc; // Description of the model
  final String? modelYear; // Manufacturing year of the model

  // --- Vehicle Specific Properties (Optional) ---
  final String? assetType; // Type of asset (e.g., "Vehicle").
  final String? owner; // Legal owner of the asset.
  final String? vehicleIdNo; // Vehicle Identification Number (VIN).
  final String? vehicleModel; // Specific vehicle model.
  final String? location; // The physical location of the asset.

  // --- Computed Properties (Getters) ---

  /// A computed property that returns `true` if the item's status is 'pending'.
  /// This provides a clean way to check for this specific status.
  bool get isPending => status == 'pending';

  // --- Constructor ---

  /// Creates an instance of [ItemModel].
  ItemModel({
    // Required parameters that must be provided when creating an item.
    required this.id,
    required this.name,
    required this.category,
    required this.itemType,
    required this.purchaseDate,
    required this.variants,
    required this.supplier,
    required this.company,

    // Optional parameters that can be null.
    this.qrCodeId,
    this.department,
    this.assignedStaff,
    this.purchasePrice,
    this.lastMaintenanceDate,
    this.maintenanceSchedule,
    this.currentValue,
    this.nextMaintenanceDate,
    this.coCd,
    this.sapClass,
    this.assetClassDesc,
    this.apcAcct,
    this.licPlate,
    this.vendor,
    this.plnt,
    this.modelCode,
    this.modelDesc,
    this.modelYear,
    this.assetType,
    this.owner,
    this.vehicleIdNo,
    this.vehicleModel,
    this.location,

    // Parameters with default values if not provided.
    this.isTagged = false,
    this.isWrittenOff = false,
    this.isAvailable = true,
    this.status = 'approved',
  });

  // --- Methods ---

  /// Creates a new [ItemModel] instance with updated values.
  /// This is useful for updating the state of an item without modifying the original object (immutability).
  /// Any parameter not provided will default to the value of the current instance.
  ItemModel copyWith({
    String? id,
    String? name,
    String? category,
    ItemType? itemType,
    DateTime? purchaseDate,
    String? variants,
    String? supplier,
    String? company,
    String? qrCodeId,
    bool? isTagged,
    bool? isWrittenOff,
    bool? isAvailable,
    String? department,
    String? assignedStaff,
    double? purchasePrice,
    DateTime? lastMaintenanceDate,
    String? maintenanceSchedule,
    double? currentValue,
    DateTime? nextMaintenanceDate,
    String? status,
    String? coCd,
    String? sapClass,
    String? assetClassDesc,
    String? apcAcct,
    String? licPlate,
    String? vendor,
    String? plnt,
    String? modelCode,
    String? modelDesc,
    String? modelYear,
    String? assetType,
    String? owner,
    String? vehicleIdNo,
    String? vehicleModel,
    String? location,
  }) {
    return ItemModel(
      // The null-aware operator '??' is used here. If the new value (e.g., 'id') is null,
      // it uses the existing value from the current object ('this.id').
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      variants: variants ?? this.variants,
      supplier: supplier ?? this.supplier,
      company: company ?? this.company,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      isTagged: isTagged ?? this.isTagged,
      isWrittenOff: isWrittenOff ?? this.isWrittenOff,
      isAvailable: isAvailable ?? this.isAvailable,
      department: department ?? this.department,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      maintenanceSchedule: maintenanceSchedule ?? this.maintenanceSchedule,
      currentValue: currentValue ?? this.currentValue,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      status: status ?? this.status,
      coCd: coCd ?? this.coCd,
      sapClass: sapClass ?? this.sapClass,
      assetClassDesc: assetClassDesc ?? this.assetClassDesc,
      apcAcct: apcAcct ?? this.apcAcct,
      licPlate: licPlate ?? this.licPlate,
      vendor: vendor ?? this.vendor,
      plnt: plnt ?? this.plnt,
      modelCode: modelCode ?? this.modelCode,
      modelDesc: modelDesc ?? this.modelDesc,
      modelYear: modelYear ?? this.modelYear,
      assetType: assetType ?? this.assetType,
      owner: owner ?? this.owner,
      vehicleIdNo: vehicleIdNo ?? this.vehicleIdNo,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      location: location ?? this.location,
    );
  }
}
