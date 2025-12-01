import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';

/// Helper widget for building item icons based on type.
class ItemIconBuilder {
  static Widget build(ItemType type) {
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
        return const Icon(Icons.tablet_android,
            size: 40, color: Colors.blueGrey);
      case ItemType.webcam:
        return const Icon(Icons.videocam, size: 40, color: Colors.grey);
      default:
        return Icon(Icons.inventory, color: Colors.grey[600]);
    }
  }
}


