import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  ImageUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadItemImage(String itemId, File imageFile) async {
    try {
      final fileName = 'items/$itemId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteItemImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors when deleting
    }
  }
}

