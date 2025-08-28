// lib/models/item_model.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'warranty_model.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
enum ItemType {
  @HiveField(0)
  laptop,
  @HiveField(1)
  keyboard,
  @HiveField(2)
  monitor,
  @HiveField(3)
  tablet,
  @HiveField(4)
  webcam,
  @HiveField(5)
  furniture,
  @HiveField(6)
  other,
}

@HiveType(typeId: 1)
class ItemModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final ItemType itemType;
  @HiveField(4)
  final DateTime purchaseDate;
  @HiveField(5)
  final String variants;
  @HiveField(6)
  final String supplier;
  @HiveField(7)
  final String company;
  @HiveField(8)
  final String? qrCodeId;
  @HiveField(9)
  final String? qrCodeUrl;
  @HiveField(10)
  final String status;
  @HiveField(11)
  final bool isTagged;
  @HiveField(12)
  final bool isWrittenOff;
  @HiveField(13)
  final bool isAvailable;
  @HiveField(14)
  final String? department;
  @HiveField(15)
  final String? assignedStaff;
  @HiveField(16)
  final double? purchasePrice;
  @HiveField(17)
  final DateTime? lastMaintenanceDate;
  @HiveField(18)
  final String? maintenanceSchedule;
  @HiveField(19)
  final double? currentValue;
  @HiveField(20)
  final DateTime? nextMaintenanceDate;
  @HiveField(21)
  final String? coCd;
  @HiveField(22)
  final String? sapClass;
  @HiveField(23)
  final String? assetClassDesc;
  @HiveField(24)
  final String? apcAcct;
  @HiveField(25)
  final String? licPlate;
  @HiveField(26)
  final String? vendor;
  @HiveField(27)
  final String? plnt;
  @HiveField(28)
  final String? modelCode;
  @HiveField(29)
  final String? modelDesc;
  @HiveField(30)
  final String? modelYear;
  @HiveField(31)
  final String? assetType;
  @HiveField(32)
  final String? owner;
  @HiveField(33)
  final String? vehicleIdNo;
  @HiveField(34)
  final String? vehicleModel;
  @HiveField(35)
  final String? location;
  @HiveField(36)
  final String? imageUrl;
  @HiveField(37)
  final Map<String, dynamic> customFields;
  @HiveField(38)
  Warranty? warranty;

  bool get isPending => status == 'pending';

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.itemType,
    required this.purchaseDate,
    required this.variants,
    required this.supplier,
    required this.company,
    this.qrCodeId,
    this.qrCodeUrl,
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
    this.isTagged = false,
    this.isWrittenOff = false,
    this.isAvailable = true,
    this.status = 'approved',
    this.imageUrl,
    this.customFields = const {},
    this.warranty,
  });

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
    String? qrCodeUrl,
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
    String? imageUrl,
    Map<String, dynamic>? customFields,
    Warranty? warranty,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      variants: variants ?? this.variants,
      supplier: supplier ?? this.supplier,
      company: company ?? this.company,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
      customFields: customFields ?? this.customFields,
      warranty: warranty ?? this.warranty,
    );
  }

  /// Helper method for the dynamic details screen.
  String getAttributeValue(String attribute) {
    switch (attribute) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'category':
        return category;
      case 'department':
        return department ?? 'N/A';
      case 'assignedStaff':
        return assignedStaff ?? 'N/A';
      case 'status':
        return isWrittenOff ? "Written Off" : "Active";
      case 'isAvailable':
        return isAvailable ? "Yes" : "No";
      case 'purchaseDate':
        return "${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}";
      case 'purchasePrice':
        return 'QR ${purchasePrice?.toStringAsFixed(2) ?? 'N/A'}';
      case 'currentValue':
        return 'QR ${currentValue?.toStringAsFixed(2) ?? 'N/A'}';
      case 'supplier':
        return supplier;
      case 'coCd':
        return coCd ?? 'N/A';
      case 'sapClass':
        return sapClass ?? 'N/A';
      case 'assetClassDesc':
        return assetClassDesc ?? 'N/A';
      case 'apcAcct':
        return apcAcct ?? 'N/A';
      case 'licPlate':
        return licPlate ?? 'N/A';
      case 'vehicleIdNo':
        return vehicleIdNo ?? 'N/A';
      case 'vehicleModel':
        return vehicleModel ?? 'N/A';
      case 'modelCode':
        return modelCode ?? 'N/A';
      case 'modelDesc':
        return modelDesc ?? 'N/A';
      case 'modelYear':
        return modelYear ?? 'N/A';
      default:
        if (customFields.containsKey(attribute)) {
          return customFields[attribute]?.toString() ?? 'N/A';
        }
        return 'N/A';
    }
  }

  @override
  String toString() {
    return 'ItemModel('
        'id: $id, '
        'name: $name, '
        'category: $category, '
        'itemType: $itemType, '
        'purchaseDate: $purchaseDate, '
        'variants: $variants, '
        'supplier: $supplier, '
        'company: $company, '
        'qrCodeId: $qrCodeId, '
        'qrCodeUrl: $qrCodeUrl, '
        'status: $status, '
        'isTagged: $isTagged, '
        'isWrittenOff: $isWrittenOff, '
        'isAvailable: $isAvailable, '
        'department: $department, '
        'assignedStaff: $assignedStaff, '
        'purchasePrice: $purchasePrice, '
        'lastMaintenanceDate: $lastMaintenanceDate, '
        'maintenanceSchedule: $maintenanceSchedule, '
        'currentValue: $currentValue, '
        'nextMaintenanceDate: $nextMaintenanceDate, '
        'coCd: $coCd, '
        'sapClass: $sapClass, '
        'assetClassDesc: $assetClassDesc, '
        'apcAcct: $apcAcct, '
        'licPlate: $licPlate, '
        'vendor: $vendor, '
        'plnt: $plnt, '
        'modelCode: $modelCode, '
        'modelDesc: $modelDesc, '
        'modelYear: $modelYear, '
        'assetType: $assetType, '
        'owner: $owner, '
        'vehicleIdNo: $vehicleIdNo, '
        'vehicleModel: $vehicleModel, '
        'location: $location, '
        'imageUrl: $imageUrl, '
        'customFields: $customFields'
        ')';
  }
}
