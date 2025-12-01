# Enable Firebase Services - Step by Step

## Required Services

Your app needs these 3 Firebase services enabled:

1. ✅ **Firestore Database** - Store items, issues, comments, history
2. ✅ **Firebase Authentication** - User login/signup
3. ✅ **Firebase Storage** - Upload images and attachments

---

## Step 1: Enable Firestore Database

1. **Open Firestore Console:**
   - Go to: https://console.firebase.google.com/project/saaed-track-15ced/firestore
   - Or click "Firestore Database" in the left sidebar

2. **Create Database:**
   - Click "Create database" button
   - Select "Start in test mode" (for development)
   - Choose location: **eur3** (Europe - matches your firebase.json)
   - Click "Enable"

3. **Verify:**
   - You should see an empty database with "Start collection" button

---

## Step 2: Enable Firebase Authentication

1. **Open Authentication Console:**
   - Go to: https://console.firebase.google.com/project/saaed-track-15ced/authentication
   - Or click "Authentication" in the left sidebar

2. **Get Started:**
   - Click "Get started" button

3. **Enable Email/Password:**
   - Click on "Email/Password" sign-in method
   - Toggle "Enable" to ON
   - Click "Save"

4. **Verify:**
   - You should see "Email/Password" listed as enabled

---

## Step 3: Enable Firebase Storage

1. **Open Storage Console:**
   - Go to: https://console.firebase.google.com/project/saaed-track-15ced/storage
   - Or click "Storage" in the left sidebar

2. **Get Started:**
   - Click "Get started" button

3. **Create Storage:**
   - Select "Start in test mode" (for development)
   - Choose location: **eur3** (Europe - matches your firebase.json)
   - Click "Done"

4. **Verify:**
   - You should see an empty storage bucket

---

## Step 4: Deploy Security Rules (After Enabling Services)

Once all services are enabled, deploy the security rules:

```powershell
firebase deploy --only "firestore,storage"
```

This will deploy:
- Firestore security rules (from `firestore.rules`)
- Storage security rules (from `storage.rules`)

---

## Quick Links

- **Project Overview:** https://console.firebase.google.com/project/saaed-track-15ced/overview
- **Firestore:** https://console.firebase.google.com/project/saaed-track-15ced/firestore
- **Authentication:** https://console.firebase.google.com/project/saaed-track-15ced/authentication
- **Storage:** https://console.firebase.google.com/project/saaed-track-15ced/storage

---

## After Enabling Services

1. ✅ Test the app: `flutter run`
2. ✅ Check Firebase initialization in console logs
3. ✅ Try creating a test item (if implemented)
4. ✅ Verify data appears in Firestore console

---

## Troubleshooting

**If services don't appear:**
- Make sure you're logged into the correct Firebase account
- Verify project ID: `saaed-track-15ced`
- Check that you have proper permissions

**If deployment fails:**
- Make sure all services are enabled first
- Check that `firebase.json` is configured correctly
- Verify you're using the correct project: `firebase use saaed-track-15ced`


