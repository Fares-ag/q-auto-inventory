# Admin Setup Guide

This guide explains how to set up admin users for the Super Admin panel.

## How Admin Authentication Works

The app uses Firestore to store admin credentials. Admin users must:
1. Have a Firebase Auth account (email/password)
2. Be registered in the `admins` collection in Firestore

## Setting Up Your First Admin

### Option 1: Using the App (Easiest)

1. **Open the app and go to Menu tab**
2. **Tap "Create Admin Account"** (shown if you're not already an admin)
3. **Fill in the form:**
   - Admin Name (e.g., "John Doe")
   - Admin Email (e.g., "admin@example.com")
   - Password (at least 6 characters)
4. **Tap "Create Admin Account"**
5. The app will:
   - Create the user in Firebase Authentication
   - Add them to the `admins` collection in Firestore
   - Show a success message

**Note:** If the email already exists in Firebase Auth, it will use that account and just add admin privileges.

### Option 2: Using Firebase Console (Manual)

1. **Create the admin user in Firebase Auth:**
   - Go to Firebase Console → Authentication
   - Click "Add user"
   - Enter admin email and password
   - Click "Add user"

2. **Add admin to Firestore:**
   - Go to Firebase Console → Firestore Database
   - Create a collection named `admins`
   - Add a document with:
     - Document ID: Use the user's UID from Firebase Auth (or email-based ID)
     - Fields:
       ```json
       {
         "email": "admin@example.com",
         "name": "Admin Name",
         "isAdmin": true,
         "createdAt": [timestamp]
       }
       ```

### Option 2: Using the App (If you have another admin)

If you already have an admin user, they can add new admins through the Super Admin panel (once implemented).

## Admin Login Process

1. User taps "Admin Login" in the Menu screen
2. Enters admin email and password
3. System checks:
   - Email exists in Firebase Auth
   - Email is in `admins` collection with `isAdmin: true`
4. If verified, user gains access to Super Admin panel

## Firestore Structure

### `admins` Collection

```
admins/
  {userId}/
    email: "admin@example.com"
    name: "Admin Name"
    isAdmin: true
    createdAt: [timestamp]
```

### Alternative: Check by Email

The system also checks for admins by email:
```
admins/
  {email-based-id}/
    email: "admin@example.com"
    isAdmin: true
```

## Security Notes

⚠️ **Important:** 
- Admin credentials are stored in Firestore
- Make sure to set up proper Firestore security rules
- Only authorized users should be able to read/write the `admins` collection

### Recommended Firestore Rules for `admins` Collection

```javascript
match /admins/{adminId} {
  // Only authenticated users can read
  allow read: if request.auth != null;
  
  // Only existing admins can write (to add new admins)
  allow write: if request.auth != null 
    && exists(/databases/$(database)/documents/admins/$(request.auth.uid))
    && get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
}
```

## Testing Admin Access

1. Create an admin user following the steps above
2. Log out of the app (if logged in)
3. Go to Menu → "Admin Login"
4. Enter admin email and password
5. You should be redirected to Super Admin panel

## Troubleshooting

**"Access denied" error:**
- Verify the email exists in Firebase Auth
- Check that the email is in the `admins` collection
- Ensure `isAdmin` field is set to `true`

**"Login failed" error:**
- Check Firebase Auth credentials
- Verify email/password are correct
- Check Firebase Console for authentication errors

