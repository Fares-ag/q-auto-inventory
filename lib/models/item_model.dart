import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum to represent the different filtering options.
enum ItemFilter {
  all,
  tagged,
  untagged,
  writtenOff,
  seenToday,
  unseen,
}

/// Enum to represent the type of item, used for the icon.
enum ItemType {
  laptop,
  keyboard,
  furniture,
  monitor,
  tablet,
  webcam,
  other,
}

/// Data model for an item with all properties for inventory management.
class ItemModel {
  final String id;
  final String name;
  final String category;
  final String variants;
  final String supplier;
  final String company;
  final String date;
  final ItemType itemType;
  final bool isTagged;
  final bool isSeenToday;
  final bool isWrittenOff;
  final String? qrCodeId;
  final String? condition; // e.g., "Good", "Fair", "Poor"
  final String? status; // e.g., "Operational", "Maintenance", "Offline"
  final String? location; // e.g., "Factory Floor 1"
  final int? utilization; // percentage, e.g., 87
  final String? nextEventDate; // e.g., "Jan 15, 2025"
  final String? imageUrl; // URL of the item's main image

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.variants,
    required this.supplier,
    required this.company,
    required this.date,
    required this.itemType,
    this.isTagged = false,
    this.isSeenToday = false,
    this.isWrittenOff = false,
    this.qrCodeId,
    this.condition,
    this.status,
    this.location,
    this.utilization,
    this.nextEventDate,
    this.imageUrl,
  });

  /// Convert ItemModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'variants': variants,
      'supplier': supplier,
      'company': company,
      'date': date,
      'itemType': itemType.name,
      'isTagged': isTagged,
      'isSeenToday': isSeenToday,
      'isWrittenOff': isWrittenOff,
      'qrCodeId': qrCodeId,
      'condition': condition,
      'status': status,
      'location': location,
      'utilization': utilization,
      'nextEventDate': nextEventDate,
      'imageUrl': imageUrl,
    };
  }

  /// Create ItemModel from Firestore document
  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle Timestamp conversion for date if needed
    String dateString = map['date'] ?? '';
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      final timestamp = map['createdAt'] as Timestamp;
      final dateTime = timestamp.toDate();
      dateString = _formatDate(dateTime);
    }

    return ItemModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      variants: map['variants'] ?? '',
      supplier: map['supplier'] ?? '',
      company: map['company'] ?? '',
      date: dateString,
      itemType: _parseItemType(map['itemType']),
      isTagged: map['isTagged'] ?? false,
      isSeenToday: map['isSeenToday'] ?? false,
      isWrittenOff: map['isWrittenOff'] ?? false,
      qrCodeId: map['qrCodeId'],
      condition: map['condition'],
      status: map['status'],
      location: map['location'],
      utilization: map['utilization'] != null
          ? (map['utilization'] as num).toInt()
          : null,
      nextEventDate: map['nextEventDate'],
      imageUrl: map['imageUrl'],
    );
  }

  /// Format DateTime to string
  static String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$weekday $day $month $year, $hour:$minute';
  }

  /// Parse ItemType from string
  static ItemType _parseItemType(String? typeString) {
    if (typeString == null) return ItemType.other;

    switch (typeString.toLowerCase()) {
      case 'laptop':
        return ItemType.laptop;
      case 'keyboard':
        return ItemType.keyboard;
      case 'furniture':
        return ItemType.furniture;
      case 'monitor':
        return ItemType.monitor;
      case 'tablet':
        return ItemType.tablet;
      case 'webcam':
        return ItemType.webcam;
      default:
        return ItemType.other;
    }
  }

  /// Create a new instance with updated properties
  ItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? variants,
    String? supplier,
    String? company,
    String? date,
    ItemType? itemType,
    bool? isTagged,
    bool? isSeenToday,
    bool? isWrittenOff,
    String? qrCodeId,
    String? condition,
    String? status,
    String? location,
    int? utilization,
    String? nextEventDate,
    String? imageUrl,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      variants: variants ?? this.variants,
      supplier: supplier ?? this.supplier,
      company: company ?? this.company,
      date: date ?? this.date,
      itemType: itemType ?? this.itemType,
      isTagged: isTagged ?? this.isTagged,
      isSeenToday: isSeenToday ?? this.isSeenToday,
      isWrittenOff: isWrittenOff ?? this.isWrittenOff,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      location: location ?? this.location,
      utilization: utilization ?? this.utilization,
      nextEventDate: nextEventDate ?? this.nextEventDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}


