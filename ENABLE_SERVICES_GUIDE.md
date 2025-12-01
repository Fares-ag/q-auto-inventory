# Enable Firebase Services - Step by Step Guide

## 🔥 Step 1: Enable Firebase Storage

1. **The Storage page should be open in your browser**
   - If not, go to: https://console.firebase.google.com/project/saaed-track/storage

2. **Click the "Get started" button** (big blue button)

3. **Choose security rules:**
   - Select **"Start in test mode"** (for development)
   - This allows read/write access for 30 days

4. **Select a location:**
   - Choose **"europe-west1"** (to match your Realtime Database location)
   - Or choose the location closest to your users

5. **Click "Done"**

6. **Wait for setup to complete** (usually takes 10-30 seconds)

---

## 🔐 Step 2: Enable Firebase Authentication

1. **The Authentication page should be open in your browser**
   - If not, go to: https://console.firebase.google.com/project/saaed-track/authentication

2. **Click the "Get started" button** (big blue button)

3. **Go to the "Sign-in method" tab** (at the top)

4. **Enable Email/Password:**
   - Find "Email/Password" in the list
   - Click on it
   - Toggle **"Enable"** to ON
   - Click **"Save"**

5. **Optional: Enable other sign-in methods if needed:**
   - Google Sign-In
   - Phone Authentication
   - etc.

---

## ✅ Step 3: Verify Services Are Enabled

After enabling both services, come back here and I'll:
1. Deploy the Storage security rules
2. Test the Firebase connection
3. Verify everything is working

---

## 📋 Quick Checklist

- [ ] Storage: Clicked "Get started" → Selected test mode → Chose location → Clicked "Done"
- [ ] Authentication: Clicked "Get started" → Went to "Sign-in method" → Enabled "Email/Password" → Saved

Once both are done, let me know and I'll deploy the rules and test everything!


