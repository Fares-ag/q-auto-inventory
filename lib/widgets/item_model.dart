import 'package:flutter/material.dart';

// Enum to represent the different filtering options.
enum ItemFilter {
  all,
  tagged,
  untagged,
  writtenOff,
  seenToday,
  unseen,
}

// Data model for an item, now with more properties for filtering.
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
  });

  // A factory constructor to create a new instance with updated properties.
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
    );
  }
}

// Enum to represent the type of item, used for the icon.
// Added the missing enum members to fix the errors.
enum ItemType { laptop, keyboard, furniture, monitor, tablet, webcam, other }

// A helper widget for building the item icon.
Widget buildItemIcon(ItemType type) {
  switch (type) {
    case ItemType.laptop:
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 35,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    case ItemType.keyboard:
      return Container(
        width: 35,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(4),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: 12,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    case ItemType.furniture:
      return const Icon(Icons.chair, size: 40, color: Colors.brown);
    case ItemType.monitor:
      return const Icon(Icons.monitor, size: 40, color: Colors.black);
    case ItemType.tablet:
      return const Icon(Icons.tablet_android, size: 40, color: Colors.blueGrey);
    case ItemType.webcam:
      return const Icon(Icons.videocam, size: 40, color: Colors.grey);
    default:
      return Icon(Icons.inventory, color: Colors.grey[600]);
  }
}
