# 🧪 Firebase Quick Testing Checklist

**Start here for practical testing steps**

---

## ⚡ Before You Start

```bash
# 1. Start backend
cd Lar-Backend
php artisan serve
# Should say: Server running on [http://127.0.0.1:8000]

# 2. Run migration if not done yet
php artisan migrate

# 3. Keep this running in terminal
# Don't close it while testing
```

---

## 🔧 Test 1: Backend Health Check (2 minutes)

```bash
# Test if backend is working
curl http://localhost:8000/api/sync/stats
```

**Expected Response:**
```json
{
  "users": {
    "total": 0,
    "synced": 0,
    "unsynced": 0,
    "syncPercentage": 0
  }
}
```

✅ **PASS** if you get this response
❌ **FAIL** if you get error

---

## 👤 Test 2: Create & Sync Test User (5 minutes)

### Step 1: Create user via API
```bash
curl -X POST http://localhost:8000/api/users/sync-firebase \
  -H "Content-Type: application/json" \
  -d '{
    "firebase_uid": "test-user-123",
    "email": "testuser@gmail.com",
    "displayName": "Test User",
    "syncedAt": "2025-12-26T10:00:00+00:00"
  }'
```

**Expected Response:**
```json
{
  "message": "User synced from Firebase successfully",
  "user": {
    "id": 1,
    "email": "testuser@gmail.com",
    "firebase_uid": "test-user-123",
    "is_firebase_synced": true
  }
}
```

✅ **Check**: 
- [ ] You get status 201 (Created)
- [ ] User ID is in response
- [ ] is_firebase_synced is true

### Step 2: Verify in database
```bash
php artisan tinker
>>> User::where('email', 'testuser@gmail.com')->first()
```

✅ **Check**:
- [ ] User exists
- [ ] firebase_uid is "test-user-123"
- [ ] is_firebase_synced is 1 (true)

---

## 🔄 Test 3: Check Sync Status (2 minutes)

```bash
curl http://localhost:8000/api/sync/stats
```

**Expected Response:**
```json
{
  "users": {
    "total": 1,
    "synced": 1,
    "unsynced": 0,
    "syncPercentage": 100
  }
}
```

✅ **Check**:
- [ ] total is 1
- [ ] synced is 1
- [ ] syncPercentage is 100

---

## 🔍 Test 4: Retrieve User (2 minutes)

```bash
curl http://localhost:8000/api/users/firebase/test-user-123
```

**Expected Response:**
```json
{
  "user": {
    "id": 1,
    "email": "testuser@gmail.com",
    "firebase_uid": "test-user-123",
    "is_firebase_synced": true
  },
  "synced": true
}
```

✅ **Check**:
- [ ] Returns user with correct firebase_uid
- [ ] synced is true

---

## 📱 Test 5: Flutter App Testing (10 minutes)

### Open Flutter App
```bash
# In another terminal
cd Lar-Frontend
flutter run
```

### Test Sign-Up
```
1. Open the Flutter app
2. Click "Register" or "Sign Up"
3. Enter:
   - Email: flutter-test@gmail.com
   - Password: TestPass123!
   - Name: Flutter Test User
4. Click Sign Up
```

**What should happen:**
- App should NOT show error
- Registration should complete
- You should be logged in

**What to verify:**
```bash
# In tinker, check if user was created and synced
php artisan tinker
>>> User::where('email', 'flutter-test@gmail.com')->first()
```

✅ **Check**:
- [ ] User exists in MySQL
- [ ] firebase_uid is set
- [ ] is_firebase_synced is true

### Test Sign-In
```
1. Click Logout (if logged in)
2. Click "Login"
3. Enter:
   - Email: testuser@gmail.com
   - Password: (the password you set)
4. Click Login
```

✅ **Check**:
- [ ] No error shown
- [ ] Logged in successfully
- [ ] Can see dashboard

---

## 🔥 Test 6: Firebase Console Verification (5 minutes)

### Check Firebase Authentication
```
1. Go to: https://console.firebase.google.com
2. Select your project
3. Go to Authentication → Users
4. Look for your test users
```

✅ **Check**:
- [ ] flutter-test@gmail.com appears in list
- [ ] testuser@gmail.com appears in list
- [ ] Both are enabled

### Check Firestore
```
1. In Firebase Console
2. Go to Firestore Database
3. Look for "users" collection
4. Click on a user document (with matching firebase_uid)
```

✅ **Check**:
- [ ] users collection exists
- [ ] user documents present
- [ ] Fields include: email, displayName, createdAt

---

## ⏱️ Test 7: Real-Time Testing (Optional, but important)

### Create Test Data in Firestore
```
1. Firebase Console → Firestore Database
2. Click "+ Start collection"
3. Create collection: "aid_programs"
4. Add document with:
   - id: "test-program-1"
   - name: "Test Aid Program"
   - status: "active"
   - createdAt: (set automatically or manual)
```

### Test Real-Time Stream in Flutter
```dart
// In your app, add this test code
final realtimeService = RealtimeService();

realtimeService.streamAidPrograms(status: 'active')
  .listen((programs) {
    print('✅ Received ${programs.length} programs');
    programs.forEach((p) {
      print('Program: ${p['name']}');
    });
  });
```

✅ **Check**:
- [ ] Stream receives the test program
- [ ] Program name is "Test Aid Program"
- [ ] Updates appear without page refresh

---

## 🔄 Test 8: Sync Direction Testing (10 minutes)

### MySQL → Firebase Sync
```dart
// In your app or code
final hybrid = HybridDataService();

// Manually trigger sync
await hybrid.syncAidProgramToFirebase('test-program-1');
```

**Verify in Firebase Console:**
```
1. Go to Firestore Database
2. Check aid_programs collection
3. Should have the test program
4. Check lastSyncedFromMySQL timestamp
```

✅ **Check**:
- [ ] Program appears in Firestore
- [ ] Has all fields
- [ ] lastSyncedFromMySQL is recent

---

## 📊 Final Summary Check

Run this to verify everything:

```bash
# 1. API health
curl http://localhost:8000/api/sync/stats

# 2. Database check
php artisan tinker
>>> User::count()           # Should be ≥ 1
>>> DB::table('users')->get()

# 3. Firebase
# Visit Firebase Console → see users in Authentication
# Visit Firebase Console → see data in Firestore
```

---

## ✅ Testing Complete When:

- [x] Backend API responds to all endpoints
- [x] User syncs from API to MySQL
- [x] User appears in Firebase Authentication
- [x] User appears in Firestore
- [x] Flutter app can sign up and sign in
- [x] Sync status shows 100%
- [x] Real-time streams work (if tested)
- [x] No errors in console logs

---

## 🆘 Quick Fixes

| Error | Solution |
|-------|----------|
| **Backend not responding** | Run `php artisan serve` in Lar-Backend |
| **Migration error** | Run `php artisan migrate:refresh` |
| **User not syncing** | Check if API endpoint returns 201 |
| **Firestore empty** | Create collection manually in Firebase Console |
| **Flutter crash** | Check that `Firebase.initializeApp()` is in main.dart |
| **No data in real-time stream** | Verify collection name is exactly right |

---

## 📱 Testing Order

1. **Backend first** (Test 1-4)
2. **Database** (Check in tinker)
3. **Firebase Console** (Verify UI)
4. **Flutter app** (Sign up/in)
5. **Real-time** (Optional, but recommended)

---

**That's it! Run through these tests and you'll know your Firebase setup is working. 🎉**

See **FIREBASE_TESTING_GUIDE.md** for detailed information on each test.
