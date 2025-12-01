import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_application_1/firebase_options.dart';

/// Firebase Service class to handle all Firebase operations
class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Initialize Firebase
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // For web, use FirebaseOptions
        // Check if appId is still a placeholder
        final options = DefaultFirebaseOptions.currentPlatform;
        if (options.appId.contains('YOUR_WEB_APP_ID')) {
          throw Exception(
            'Web Firebase configuration incomplete. '
            'Please add a web app in Firebase Console and update lib/firebase_options.dart with the appId. '
            'See WEB_FIREBASE_SETUP.md for instructions.',
          );
        }
        await Firebase.initializeApp(options: options);
      } else {
        // For mobile (Android/iOS), use default initialization
        // which reads from google-services.json or GoogleService-Info.plist
        await Firebase.initializeApp();
      }
    } catch (e) {
      // If Firebase is already initialized, that's okay
      if (e.toString().contains('already been initialized') ||
          e.toString().contains('already exists')) {
        return;
      }
      // Log the error but don't crash the app - Firebase might still work
      // The JS module loading errors are often non-fatal
      debugPrint('Firebase initialization warning: $e');
      // Only rethrow if it's a critical configuration error
      if (e.toString().contains('configuration incomplete') ||
          e.toString().contains('FirebaseOptions cannot be null')) {
        rethrow;
      }
      // For other errors (like network issues), continue - Firebase might still work
    }
  }

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Update or create user document with last login timestamp
    try {
      final user = credential.user;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).set(
          {
            'email': user.email?.toLowerCase() ?? email.toLowerCase(),
            'displayName': user.displayName ?? '',
            'role': 'user',
            'isActive': true,
            'lastLoginAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      // Non‑fatal: logging failure should not block sign in
      debugPrint('Failed to update user document on sign in: $e');
    }
    return credential;
  }

  /// Sign out
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Create initial user document in Firestore
    try {
      final user = credential.user;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase() ?? email.toLowerCase(),
          'displayName': user.displayName ?? '',
          'role': 'user',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to create user document on signup: $e');
    }
    return credential;
  }
}

