# Firebase Setup Guide

This guide will help you integrate your new Firebase account with this Flutter application.

## Prerequisites

1. A Firebase account (create one at https://firebase.google.com/)
2. Flutter SDK installed
3. Android Studio / Xcode (for platform-specific setup)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter your project name (e.g., "AssetFlow Pro")
4. Follow the setup wizard
5. Enable Google Analytics (optional but recommended)

## Step 2: Add Android App

1. In Firebase Console, click the Android icon (or "Add app")
2. Enter your Android package name (found in `android/app/build.gradle` as `applicationId`)
   - Default: `com.example.flutter_application_1`
3. Register the app
4. Download `google-services.json`
5. Place it in `android/app/` directory

## Step 3: Add iOS App

1. In Firebase Console, click the iOS icon (or "Add app")
2. Enter your iOS bundle ID (found in `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`)
3. Register the app
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/` directory
6. Open `ios/Runner.xcworkspace` in Xcode
7. Drag `GoogleService-Info.plist` into the Runner folder in Xcode

## Step 4: Enable Firebase Services

### Firestore Database
1. Go to Firestore Database in Firebase Console
2. Click "Create database"
3. Start in test mode (for development)
4. Choose your preferred location

### Firebase Authentication
1. Go to Authentication in Firebase Console
2. Click "Get started"
3. Enable "Email/Password" sign-in method

### Firebase Storage
1. Go to Storage in Firebase Console
2. Click "Get started"
3. Start in test mode (for development)
4. Choose your preferred location

## Step 5: Update Android Configuration

1. Open `android/build.gradle` (project level)
2. Add to `dependencies`:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.0'
   ```

3. Open `android/app/build.gradle`
4. Add at the bottom:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## Step 6: Update iOS Configuration

1. Open `ios/Podfile`
2. Ensure platform is set (e.g., `platform :ios, '12.0'`)
3. Run `cd ios && pod install`

## Step 7: Install Dependencies

Run in your project root:
```bash
flutter pub get
```

## Step 8: Test Firebase Connection

The app will automatically initialize Firebase when it starts. Check the console for any initialization errors.

## Troubleshooting

### Android Issues
- Ensure `google-services.json` is in `android/app/`
- Check that `apply plugin: 'com.google.gms.google-services'` is at the bottom of `android/app/build.gradle`
- Clean and rebuild: `flutter clean && flutter pub get && flutter run`

### iOS Issues
- Ensure `GoogleService-Info.plist` is added to Xcode project
- Run `cd ios && pod install`
- Clean build folder in Xcode

### General Issues
- Verify Firebase project settings match your app's package name/bundle ID
- Check that all required Firebase services are enabled
- Review Firebase Console for any error messages

## Security Rules

After setup, configure security rules in Firebase Console:

### Firestore Rules (Development)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules (Development)
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Important:** Update these rules for production to match your security requirements.

## Next Steps

1. Implement authentication screens (login/signup)
2. Connect data models to Firestore
3. Implement image upload to Firebase Storage
4. Set up proper error handling
5. Configure production security rules

For more information, visit:
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)


