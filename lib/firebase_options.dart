// File generated to support Firebase initialization on web
// This file should be updated with your Firebase web app configuration
// Get the config from: https://console.firebase.google.com/project/paeed-b35ef/settings/general

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration options
/// 
/// To get your web app config:
/// 1. Go to Firebase Console: https://console.firebase.google.com/project/paeed-b35ef/settings/general
/// 2. Scroll to "Your apps" section
/// 3. Click on the web app (or add one if it doesn't exist)
/// 4. Copy the firebaseConfig object
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration
      return const FirebaseOptions(
        apiKey: 'AIzaSyAwvT3op3cfjJrOc2K5WEgGWMlyIjHIzdU',
        appId: '1:228338593098:web:8c1dd4fb73548a48a025b3',
        messagingSenderId: '228338593098',
        projectId: 'paeed-b35ef',
        authDomain: 'paeed-b35ef.firebaseapp.com',
        storageBucket: 'paeed-b35ef.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        // Android and iOS use google-services.json / GoogleService-Info.plist automatically
        // These should not be called - Firebase.initializeApp() without options handles them
        throw UnsupportedError(
          'Mobile platforms use automatic configuration files. '
          'Do not call DefaultFirebaseOptions.currentPlatform on mobile.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}

