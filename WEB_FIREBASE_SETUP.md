# Firebase Web Configuration Guide

## Issue
When running the app on web (Chrome), you're getting this error:
```
FirebaseOptions cannot be null when creating the default app.
```

## Solution

Firebase web requires explicit configuration. You need to add a web app to your Firebase project and configure it.

### Step 1: Add Web App to Firebase

1. Go to Firebase Console: https://console.firebase.google.com/project/paeed-b35ef/settings/general
2. Scroll down to "Your apps" section
3. Click the **Web icon** (`</>`) to add a web app
4. Register your app:
   - App nickname: `Paeedal Web` (or any name)
   - **Don't check** "Also set up Firebase Hosting"
5. Click "Register app"

### Step 2: Copy Firebase Config

After registering, you'll see a code snippet like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "paeed-b35ef.firebaseapp.com",
  projectId: "paeed-b35ef",
  storageBucket: "paeed-b35ef.firebasestorage.app",
  messagingSenderId: "228338593098",
  appId: "1:228338593098:web:XXXXXXXXXX"
};
```

### Step 3: Update firebase_options.dart

Open `lib/firebase_options.dart` and update the web configuration:

```dart
if (kIsWeb) {
  return const FirebaseOptions(
    apiKey: 'YOUR_API_KEY',  // From firebaseConfig.apiKey
    appId: 'YOUR_APP_ID',    // From firebaseConfig.appId
    messagingSenderId: '228338593098',  // From firebaseConfig.messagingSenderId
    projectId: 'paeed-b35ef',
    authDomain: 'paeed-b35ef.firebaseapp.com',
    storageBucket: 'paeed-b35ef.firebasestorage.app',
  );
}
```

### Step 4: Test

After updating, restart the app:
```powershell
flutter run -d chrome
```

## Alternative: Skip Web for Now

If you don't need web support right now, you can:

1. **Run on Android/iOS instead:**
   ```powershell
   flutter run -d android
   # or
   flutter run -d ios
   ```

2. **Or disable web platform:**
   - The app works perfectly on mobile devices
   - Web support is optional

## Quick Fix (Temporary)

If you just want to test the mobile app, you can temporarily modify `lib/main.dart` to skip Firebase initialization on web:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Initialize Firebase (skip on web for now)
  if (!kIsWeb) {
    try {
      await FirebaseService.initialize();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }
  
  runApp(const MyApp());
}
```

But the proper solution is to add the web app configuration as described above.


