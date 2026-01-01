# Understanding the Firestore Offline Error

## What the Error Means

```
Error loading user profile: [cloud_firestore/unavailable] 
Failed to get document because the client is offline.
```

This error says **Firestore can't connect to the database**.

## Common Causes (in order of likelihood)

### 1. **Firestore Not Initialized** ❌
   - Firebase may not be properly connected
   - Check if Firebase is returning "offline" mode

### 2. **Web Security Rules Block Access** 🔒
   - Firestore security rules might be too strict
   - Default rules require authentication + custom rules

### 3. **Browser/Network Issue** 🌐
   - Your browser might be blocking Firebase requests
   - Network connectivity issues
   - CORS issues

### 4. **Firebase Project Issues** ⚙️
   - Database might be disabled
   - Region issues
   - API not enabled

---

## Solutions to Try (in order)

### **Solution 1: Check Firestore Security Rules** 
Go to Firebase Console → Firestore → Rules and set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow anyone to read/write for now (TEST ONLY!)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **WARNING:** This is open access - only for testing! Change it later.

---

### **Solution 2: Check if Firestore is Enabled**

In Firebase Console:
1. Go to **Firestore Database**
2. Click **Create Database**
3. Choose **Start in test mode**
4. Select **us-central1** region
5. Click **Create**

---

### **Solution 3: Verify Firebase Config**

Check `lib/firebase_options.dart` has correct web credentials:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyBJHR59qKN9jSNI6tRxV_LOt_RG1t3dytA',
  appId: '1:156255050730:web:38456607a648d528ea3093',
  messagingSenderId: '156255050730',
  projectId: 'lubok-antu-rescuenet',
  authDomain: 'lubok-antu-rescuenet.firebaseapp.com',
  storageBucket: 'lubok-antu-rescuenet.firebasestorage.app',
  measurementId: 'G-JXEP6XED9E',
);
```

✅ If this looks correct, Firebase is configured right.

---

### **Solution 4: Enable Offline Persistence** (Optional)

The error is **not fatal** - your app can still work offline. The system will:
- Use cached data when available
- Sync when connection restored
- Work with just Firebase Auth (email/password login)

---

## What Actually Happens Now

1. ✅ **Login/Register works** - Uses Firebase Auth (works offline)
2. ⚠️ **Profile loads from Firestore** - Shows error if offline, but doesn't crash
3. ✅ **App still works** - Falls back to basic user info from Firebase Auth
4. 📦 **When online again** - Firestore syncs automatically

---

## Quick Checklist

- [ ] Check Firebase console - Firestore DB exists?
- [ ] Check security rules - Are they allowing access?
- [ ] Check firebase_options.dart - Is projectId correct?
- [ ] Try opening in incognito/private mode
- [ ] Check browser console for CORS errors (F12)
- [ ] Try refreshing the page

---

## The Bottom Line

**This error is expected** if:
- Firestore database not created yet
- Security rules too restrictive  
- Network is actually offline
- This is your first test run

**The app will still work** - it just can't load extended profile data. Authentication still works fine!
