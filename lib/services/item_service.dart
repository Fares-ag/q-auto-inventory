import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/models/item_model.dart';

/// Service class to handle all Firestore operations for items
class ItemService {
  static const String _collection = 'items';

  /// Get a stream of all items
  static Stream<List<ItemModel>> getItemsStream() {
    final user = FirebaseService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseService.firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get a single item by ID
  static Future<ItemModel?> getItemById(String id) async {
    try {
      final doc = await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (doc.exists) {
        return ItemModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  /// Create a new item
  static Future<String> createItem(ItemModel item) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to create items');
    }

    try {
      final docRef = await FirebaseService.firestore
          .collection(_collection)
          .add({
        ...item.toMap(),
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Update an existing item
  static Future<void> updateItem(ItemModel item) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to update items');
    }

    try {
      await FirebaseService.firestore
          .collection(_collection)
          .doc(item.id)
          .update({
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Delete an item
  static Future<void> deleteItem(String id) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to delete items');
    }

    try {
      await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Get items by QR code ID
  static Future<ItemModel?> getItemByQrCode(String qrCodeId) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('qrCodeId', isEqualTo: qrCodeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ItemModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item by QR code: $e');
    }
  }

  /// Get all items (for admin use - no user filter)
  static Stream<List<ItemModel>> getAllItemsStream() {
    return FirebaseService.firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}

