// Data models reconstructed from Firebase collection names.
// The actual field lists may need adjustment once we inspect live documents.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper mixin for Firestore models that are backed by a document reference.
abstract class FirestoreModel {
  const FirestoreModel({required this.id});

  final String id;

  Map<String, dynamic> toJson();
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

List<String> _stringListFromUnknown(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }
  if (value is Map) {
    // Accept either {perm: true} maps or arbitrary maps; collect keys with truthy value, or all keys if non-bool values
    final Map<dynamic, dynamic> m = value;
    final List<String> keys = <String>[];
    m.forEach((k, v) {
      final key = k?.toString() ?? '';
      if (key.isEmpty) return;
      if (v is bool) {
        if (v) keys.add(key);
      } else {
        keys.add(key);
      }
    });
    return keys;
  }
  if (value is String) return value.isEmpty ? const <String>[] : <String>[value];
  return const <String>[];
}

class AssetCounter extends FirestoreModel {
  const AssetCounter({
    required super.id,
    required this.prefix,
    required this.currentValue,
    this.updatedAt,
    this.updatedBy,
  });

  final String prefix;
  final int currentValue;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory AssetCounter.fromJson(String id, Map<String, dynamic> json) {
    return AssetCounter(
      id: id,
      prefix: json['prefix'] as String? ?? 'ASSET',
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      updatedAt: _parseTimestamp(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'currentValue': currentValue,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }
}

class Category extends FirestoreModel {
  const Category({
    required super.id,
    required this.name,
    this.description,
    this.parentId,
    this.sortOrder,
    this.isActive = true,
  });

  final String name;
  final String? description;
  final String? parentId;
  final int? sortOrder;
  final bool isActive;

  factory Category.fromJson(String id, Map<String, dynamic> json) {
    return Category(
      id: id,
      name: json['name'] as String? ?? id,
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

class Comment extends FirestoreModel {
  const Comment({
    required super.id,
    required this.entityId,
    required this.entityType,
    required this.authorId,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  final String entityId;
  final String entityType;
  final String authorId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Comment.fromJson(String id, Map<String, dynamic> json) {
    return Comment(
      id: id,
      entityId: json['entityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'item',
      authorId: json['authorId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'authorId': authorId,
      'content': content,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class Department extends FirestoreModel {
  const Department({
    required super.id,
    required this.name,
    this.code,
    this.description,
    this.managerId,
    this.parentDepartmentId,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  final String name;
  final String? code;
  final String? description;
  final String? managerId;
  final String? parentDepartmentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  factory Department.fromJson(String id, Map<String, dynamic> json) {
    return Department(
      id: id,
      name: json['name'] as String? ?? id,
      code: json['code'] as String?,
      description: json['description'] as String?,
      managerId: json['managerId'] as String?,
      parentDepartmentId: json['parentDepartmentId'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (managerId != null) 'managerId': managerId,
      if (parentDepartmentId != null)
        'parentDepartmentId': parentDepartmentId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'isActive': isActive,
    };
  }
}

class HistoryEntry extends FirestoreModel {
  const HistoryEntry({
    required super.id,
    required this.itemId,
    required this.action,
    required this.actorId,
    this.notes,
    this.metadata,
    this.timestamp,
  });

  final String itemId;
  final String action;
  final String actorId;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;

  factory HistoryEntry.fromJson(String id, Map<String, dynamic> json) {
    return HistoryEntry(
      id: id,
      itemId: json['itemId'] as String? ?? '',
      action: json['action'] as String? ?? 'update',
      actorId: json['actorId'] as String? ?? '',
      notes: json['notes'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?),
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'action': action,
      'actorId': actorId,
      if (notes != null) 'notes': notes,
      if (metadata != null) 'metadata': metadata,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
    };
  }
}

class Issue extends FirestoreModel {
  const Issue({
    required super.id,
    required this.itemId,
    required this.title,
    required this.status,
    this.description,
    this.priority,
    this.reportedBy,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  final String itemId;
  final String title;
  final String status;
  final String? description;
  final String? priority;
  final String? reportedBy;
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  factory Issue.fromJson(String id, Map<String, dynamic> json) {
    return Issue(
      id: id,
      itemId: json['itemId'] as String? ?? '',
      title: json['title'] as String? ?? 'Issue',
      status: json['status'] as String? ?? 'open',
      description: json['description'] as String?,
      priority: json['priority'] as String?,
      reportedBy: json['reportedBy'] as String?,
      assignedTo: json['assignedTo'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      closedAt: _parseTimestamp(json['closedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'status': status,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (reportedBy != null) 'reportedBy': reportedBy,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
    };
  }
}

class InventoryItem extends FirestoreModel {
  const InventoryItem({
    required super.id,
    required this.assetId,
    required this.name,
    required this.categoryId,
    required this.departmentId,
    this.description,
    this.quantity,
    this.status,
    this.locationId,
    this.assignedTo,
    this.purchaseDate,
    this.warrantyExpiry,
    this.lastServicedAt,
    this.tags = const [],
    this.thumbnailUrl,
    this.qrCodeUrl,
    this.customFields,
    this.supplier,
    this.variants,
    this.purchasePrice,
    this.shelfLifeYears,
    this.coCd,
    this.sapClass,
    this.assetClassDesc,
    this.apcAccount,
    this.licensePlate,
    this.vendor,
    this.plant,
    this.owner,
    this.vehicleId,
  });

  final String assetId;
  final String name;
  final String categoryId;
  final String departmentId;
  final String? description;
  final int? quantity;
  final String? status;
  final String? locationId;
  final String? assignedTo;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final DateTime? lastServicedAt;
  final List<String> tags;
  final String? thumbnailUrl;
  final String? qrCodeUrl;
  final Map<String, dynamic>? customFields;
  final String? supplier;
  final String? variants;
  final double? purchasePrice;
  final int? shelfLifeYears;
  final String? coCd;
  final String? sapClass;
  final String? assetClassDesc;
  final String? apcAccount;
  final String? licensePlate;
  final String? vendor;
  final String? plant;
  final String? owner;
  final String? vehicleId;

  factory InventoryItem.fromJson(String id, Map<String, dynamic> json) {
    return InventoryItem(
      id: id,
      assetId: json['assetId'] as String? ?? id,
      name: json['name'] as String? ?? id,
      categoryId: json['categoryId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      status: json['status'] as String?,
      locationId: json['locationId'] as String?,
      assignedTo: json['assignedTo'] as String?,
      purchaseDate: _parseTimestamp(json['purchaseDate']),
      warrantyExpiry: _parseTimestamp(json['warrantyExpiry']),
      lastServicedAt: _parseTimestamp(json['lastServicedAt']),
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      thumbnailUrl: json['thumbnailUrl'] as String?,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      customFields: (json['customFields'] as Map<String, dynamic>?),
      supplier: json['supplier'] as String? ?? json['vendor'] as String?,
      variants: json['variants'] as String?,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      shelfLifeYears: (json['shelfLifeYears'] as num?)?.toInt(),
      coCd: json['coCd'] as String? ?? json['cocd'] as String?,
      sapClass: json['sapClass'] as String?,
      assetClassDesc: json['assetClassDesc'] as String?,
      apcAccount: json['apcAcct'] as String? ?? json['apcAccount'] as String?,
      licensePlate: json['licPlate'] as String? ?? json['licensePlate'] as String?,
      vendor: json['vendor'] as String?,
      plant: json['plnt'] as String? ?? json['plant'] as String?,
      owner: json['owner'] as String?,
      vehicleId: json['vehicleIdNumber'] as String? ??
          json['vehicleIdNo'] as String? ??
          json['vehicleId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'name': name,
      'categoryId': categoryId,
      'departmentId': departmentId,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (status != null) 'status': status,
      if (locationId != null) 'locationId': locationId,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (purchaseDate != null)
        'purchaseDate': Timestamp.fromDate(purchaseDate!),
      if (warrantyExpiry != null)
        'warrantyExpiry': Timestamp.fromDate(warrantyExpiry!),
      if (lastServicedAt != null)
        'lastServicedAt': Timestamp.fromDate(lastServicedAt!),
      if (tags.isNotEmpty) 'tags': tags,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (customFields != null) 'customFields': customFields,
      if (supplier != null) 'supplier': supplier,
      if (variants != null) 'variants': variants,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (shelfLifeYears != null) 'shelfLifeYears': shelfLifeYears,
      if (coCd != null) 'coCd': coCd,
      if (sapClass != null) 'sapClass': sapClass,
      if (assetClassDesc != null) 'assetClassDesc': assetClassDesc,
      if (apcAccount != null) 'apcAcct': apcAccount,
      if (licensePlate != null) 'licPlate': licensePlate,
      if (vendor != null) 'vendor': vendor,
      if (plant != null) 'plnt': plant,
      if (owner != null) 'owner': owner,
      if (vehicleId != null) 'vehicleIdNumber': vehicleId,
    };
  }
}

class Location extends FirestoreModel {
  const Location({
    required super.id,
    required this.name,
    this.address,
    this.notes,
    this.parentLocationId,
    this.isPrimary = false,
  });

  final String name;
  final String? address;
  final String? notes;
  final String? parentLocationId;
  final bool isPrimary;

  factory Location.fromJson(String id, Map<String, dynamic> json) {
    return Location(
      id: id,
      name: json['name'] as String? ?? id,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      parentLocationId: json['parentLocationId'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (parentLocationId != null) 'parentLocationId': parentLocationId,
      'isPrimary': isPrimary,
    };
  }
}

class PermissionSet extends FirestoreModel {
  const PermissionSet({
    required super.id,
    required this.name,
    this.description,
    this.permissions = const [],
  });

  final String name;
  final String? description;
  final List<String> permissions;

  factory PermissionSet.fromJson(String id, Map<String, dynamic> json) {
    return PermissionSet(
      id: id,
      name: json['name'] as String? ?? id,
      description: json['description'] as String?,
      permissions: _stringListFromUnknown(json['permissions']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (permissions.isNotEmpty) 'permissions': permissions,
    };
  }
}

class StaffMember extends FirestoreModel {
  const StaffMember({
    required super.id,
    required this.displayName,
    required this.email,
    this.role,
    this.phoneNumber,
    this.departmentId,
    this.permissionSetId,
    this.isActive = true,
    this.photoUrl,
    this.createdAt,
    this.lastSignIn,
  });

  final String displayName;
  final String email;
  final String? role;
  final String? phoneNumber;
  final String? departmentId;
  final String? permissionSetId;
  final bool isActive;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastSignIn;

  factory StaffMember.fromJson(String id, Map<String, dynamic> json) {
    return StaffMember(
      id: id,
      displayName: json['displayName'] as String? ?? id,
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      departmentId: json['departmentId'] as String?,
      permissionSetId: json['permissionSetId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      lastSignIn: _parseTimestamp(json['lastSignIn']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      if (role != null) 'role': role,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (departmentId != null) 'departmentId': departmentId,
      if (permissionSetId != null) 'permissionSetId': permissionSetId,
      'isActive': isActive,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastSignIn != null) 'lastSignIn': Timestamp.fromDate(lastSignIn!),
    };
  }
}

class SubDepartment extends FirestoreModel {
  const SubDepartment({
    required super.id,
    required this.departmentId,
    required this.name,
    this.code,
    this.description,
    this.managerId,
    this.isActive = true,
  });

  final String departmentId;
  final String name;
  final String? code;
  final String? description;
  final String? managerId;
  final bool isActive;

  factory SubDepartment.fromJson(String id, Map<String, dynamic> json) {
    return SubDepartment(
      id: id,
      departmentId: json['departmentId'] as String? ?? '',
      name: json['name'] as String? ?? id,
      code: json['code'] as String?,
      description: json['description'] as String?,
      managerId: json['managerId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (managerId != null) 'managerId': managerId,
      'isActive': isActive,
    };
  }
}

class SystemSettings extends FirestoreModel {
  const SystemSettings({
    required super.id,
    this.companyName,
    this.logoUrl,
    this.defaultTimezone,
    this.supportEmail,
    this.qrPrefix,
    this.assetIdFormat,
    this.additional,
  });

  final String? companyName;
  final String? logoUrl;
  final String? defaultTimezone;
  final String? supportEmail;
  final String? qrPrefix;
  final String? assetIdFormat;
  final Map<String, dynamic>? additional;

  factory SystemSettings.fromJson(String id, Map<String, dynamic> json) {
    return SystemSettings(
      id: id,
      companyName: json['companyName'] as String?,
      logoUrl: json['logoUrl'] as String?,
      defaultTimezone: json['defaultTimezone'] as String?,
      supportEmail: json['supportEmail'] as String?,
      qrPrefix: json['qrPrefix'] as String?,
      assetIdFormat: json['assetIdFormat'] as String?,
      additional: (json['additional'] as Map<String, dynamic>?),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (companyName != null) 'companyName': companyName,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (defaultTimezone != null) 'defaultTimezone': defaultTimezone,
      if (supportEmail != null) 'supportEmail': supportEmail,
      if (qrPrefix != null) 'qrPrefix': qrPrefix,
      if (assetIdFormat != null) 'assetIdFormat': assetIdFormat,
      if (additional != null) 'additional': additional,
    };
  }
}

class AppUser extends FirestoreModel {
  const AppUser({
    required super.id,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.departmentId,
    this.subDepartmentId,
    this.permissionSetId,
    this.isDisabled = false,
    this.photoUrl,
    this.lastSignIn,
    this.createdAt,
  });

  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? departmentId;
  final String? subDepartmentId;
  final String? permissionSetId;
  final bool isDisabled;
  final String? photoUrl;
  final DateTime? lastSignIn;
  final DateTime? createdAt;

  factory AppUser.fromJson(String id, Map<String, dynamic> json) {
    return AppUser(
      id: id,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? id,
      phoneNumber: json['phoneNumber'] as String?,
      departmentId: json['departmentId'] as String?,
      subDepartmentId: json['subDepartmentId'] as String?,
      permissionSetId: json['permissionSetId'] as String?,
      isDisabled: json['isDisabled'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
      lastSignIn: _parseTimestamp(json['lastSignIn']),
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (departmentId != null) 'departmentId': departmentId,
      if (subDepartmentId != null) 'subDepartmentId': subDepartmentId,
      if (permissionSetId != null) 'permissionSetId': permissionSetId,
      'isDisabled': isDisabled,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (lastSignIn != null) 'lastSignIn': Timestamp.fromDate(lastSignIn!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

class VehicleCheckInOut extends FirestoreModel {
  const VehicleCheckInOut({
    required super.id,
    required this.vehicleId,
    required this.userId,
    required this.action, // checkin or checkout
    this.odometer,
    this.notes,
    this.timestamp,
    this.expectedReturn,
    this.completed = false,
  });

  final String vehicleId;
  final String userId;
  final String action;
  final double? odometer;
  final String? notes;
  final DateTime? timestamp;
  final DateTime? expectedReturn;
  final bool completed;

  factory VehicleCheckInOut.fromJson(String id, Map<String, dynamic> json) {
    return VehicleCheckInOut(
      id: id,
      vehicleId: json['vehicleId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      action: json['action'] as String? ?? 'checkout',
      odometer: (json['odometer'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      timestamp: _parseTimestamp(json['timestamp']),
      expectedReturn: _parseTimestamp(json['expectedReturn']),
      completed: json['completed'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'userId': userId,
      'action': action,
      if (odometer != null) 'odometer': odometer,
      if (notes != null) 'notes': notes,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
      if (expectedReturn != null)
        'expectedReturn': Timestamp.fromDate(expectedReturn!),
      'completed': completed,
    };
  }
}

class VehicleMaintenance extends FirestoreModel {
  const VehicleMaintenance({
    required super.id,
    required this.vehicleId,
    required this.type,
    required this.scheduledDate,
    this.completedDate,
    this.vendor,
    this.cost,
    this.notes,
    this.mileage,
  });

  final String vehicleId;
  final String type;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String? vendor;
  final double? cost;
  final String? notes;
  final double? mileage;

  factory VehicleMaintenance.fromJson(String id, Map<String, dynamic> json) {
    return VehicleMaintenance(
      id: id,
      vehicleId: json['vehicleId'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      scheduledDate:
          _parseTimestamp(json['scheduledDate']) ?? DateTime.now(),
      completedDate: _parseTimestamp(json['completedDate']),
      vendor: json['vendor'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      mileage: (json['mileage'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'type': type,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      if (completedDate != null)
        'completedDate': Timestamp.fromDate(completedDate!),
      if (vendor != null) 'vendor': vendor,
      if (cost != null) 'cost': cost,
      if (notes != null) 'notes': notes,
      if (mileage != null) 'mileage': mileage,
    };
  }
}
