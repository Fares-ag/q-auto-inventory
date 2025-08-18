// Import the 'dart:io' library to use the File class, which represents a file on the device's file system.
import 'dart:io';
// Import the Firebase Storage package to interact with the Firebase Storage service.
import 'package:firebase_storage/firebase_storage.dart';

/// A service class to handle file operations with Firebase Storage.
class StorageService {
  /// An instance of FirebaseStorage, which is the main entry point for the plugin.
  /// We create a single instance to be reused throughout the class.
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a [File] to a specified [path] in Firebase Storage.
  ///
  /// Returns the public download URL as a [String] on success,
  /// or `null` if an error occurs.
  /// This method is asynchronous, so it returns a [Future].
  Future<String?> uploadFile(File file, String path) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage.
      // The 'path' could be something like 'images/profile_pics/user_id.jpg'.
      final ref = _storage.ref().child(path);

      // Start the upload task by providing the file to the reference.
      UploadTask uploadTask = ref.putFile(file);

      // Await for the upload to complete. The 'snapshot' contains information
      // about the completed upload, such as bytes transferred.
      TaskSnapshot snapshot = await uploadTask;

      // Once the upload is complete, get the public download URL for the file.
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // If any error occurs during the upload process, print it to the console.
      print(e);
      // Return null to indicate that the upload failed.
      return null;
    }
  }
}
