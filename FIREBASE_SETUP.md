# Firebase Setup Instructions

## Quick Setup

1. **Install FlutterFire CLI** (if not already installed):
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configure Firebase**:
   ```bash
   cd q-auto-inventory-aaron-migrate
   flutterfire configure
   ```
   
   This will:
   - Detect your Firebase projects
   - Let you select your project
   - Generate `lib/firebase_options.dart` with your actual credentials

## Manual Setup (Alternative)

If you prefer to configure manually:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Scroll down to "Your apps" section
5. For each platform (Web, Android, iOS), copy the config values
6. Update `lib/firebase_options.dart` with your actual values:
   - `apiKey`
   - `appId`
   - `messagingSenderId`
   - `projectId`
   - `authDomain` (for web)
   - `storageBucket`
   - `iosBundleId` (for iOS/macOS)

## Current Status

The app now has a template `firebase_options.dart` file with placeholder values. 
**You must replace these with your actual Firebase project credentials** for the app to work.

The placeholder values (starting with `YOUR_`) will cause Firebase initialization to fail until replaced.

