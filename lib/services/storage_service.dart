import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

/// Service class to handle all Firebase Storage operations
class StorageService {
  /// Upload an image file to Firebase Storage
  /// Returns the download URL of the uploaded image
  static Future<String> uploadImage({
    required File imageFile,
    required String itemId,
    String? fileName,
  }) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to upload images');
    }

    try {
      // Generate a unique file name if not provided
      final String uniqueFileName = fileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      // Create reference to the file location
      final Reference ref = FirebaseService.storage
          .ref()
          .child('items')
          .child(user.uid)
          .child(itemId)
          .child(uniqueFileName);

      // Upload the file
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload an attachment file to Firebase Storage
  /// Returns the download URL of the uploaded file
  static Future<String> uploadAttachment({
    required File file,
    required String itemId,
    String? fileName,
  }) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to upload attachments');
    }

    try {
      // Generate a unique file name if not provided
      final String uniqueFileName = fileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      // Create reference to the file location
      final Reference ref = FirebaseService.storage
          .ref()
          .child('items')
          .child(user.uid)
          .child(itemId)
          .child('attachments')
          .child(uniqueFileName);

      // Upload the file
      final UploadTask uploadTask = ref.putFile(file);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  /// Delete an image from Firebase Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final Reference ref = FirebaseService.storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get download URL from storage path
  static Future<String> getDownloadUrl(String path) async {
    try {
      final Reference ref = FirebaseService.storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}


