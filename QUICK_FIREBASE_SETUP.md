# Quick Firebase Setup - Connect to Your Existing Database

Since you already have a Firestore database with 1600+ assets, you just need to connect the app to your existing Firebase project.

## Method 1: Automatic (Easiest) ⭐

1. **Install FlutterFire CLI**:

   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Navigate to project**:

   ```bash
   cd q-auto-inventory-aaron-migrate
   ```

3. **Run configuration**:

   ```bash
   flutterfire configure
   ```

   - It will show you a list of your Firebase projects
   - Select the project that contains your 1600+ assets
   - It will automatically generate `lib/firebase_options.dart` with your credentials
   - Select the platforms you want to support (web, android, ios, etc.)

## Method 2: Manual (If Method 1 doesn't work)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project** (the one with your 1600+ assets)
3. **Click the gear icon** ⚙️ → **Project Settings**
4. **Scroll down to "Your apps"** section
5. **For each platform** (Web, Android, iOS):

   **For Web:**

   - Click on the web app (or add one if needed)
   - Copy these values:
     - `apiKey`
     - `appId` (or `messagingSenderId`)
     - `projectId`
     - `authDomain`
     - `storageBucket`

   **For Android/iOS:**

   - Similar process, get the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) config values

6. **Update `lib/firebase_options.dart`**:
   - Replace all `YOUR_*` placeholders with your actual values
   - Make sure `projectId` matches across all platforms

## Verify Your Collections Match

The app is already configured to use these collections (which should match your database):

- ✅ `items` - Your 1600+ assets
- ✅ `assetCounter`
- ✅ `categories`
- ✅ `comments`
- ✅ `departments`
- ✅ `history`
- ✅ `issues`
- ✅ `locations`
- ✅ `permissionSets`
- ✅ `staff`
- ✅ `sub_departments`
- ✅ `system`
- ✅ `users`
- ✅ `vehicle_checkinout`
- ✅ `vehicle_maintenance`

## After Configuration

Once you've added your Firebase credentials:

1. The app will connect to your existing database
2. All 1600+ assets should be accessible
3. The app will use your existing data structure

## Testing

After configuration, run:

```bash
flutter run -d chrome
```

The app should now connect to your Firebase project and display your existing assets!
