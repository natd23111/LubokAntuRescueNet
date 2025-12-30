# Firebase Testing Guide - Complete

**Project**: Lubok Antu RescueNet
**Date**: December 26, 2025

---

## 🧪 Firebase Testing Overview

Testing your Firebase + MySQL hybrid setup involves:
1. **Backend API Testing** - Verify endpoints work
2. **Firebase Operations** - Test auth, Firestore, Storage
3. **Frontend Integration** - Test UI with real Firebase
4. **Real-Time Features** - Verify live updates
5. **Sync Verification** - Confirm MySQL ↔ Firebase sync
6. **Offline Testing** - Test cache and reconnect

---

## ✅ Pre-Testing Setup

### Requirements
- [ ] Backend running: `php artisan serve` (port 8000)
- [ ] Flutter app ready: `flutter run`
- [ ] Firebase project created
- [ ] Firestore database created
- [ ] Database migrated: `php artisan migrate`
- [ ] Postman or similar API testing tool (optional)
- [ ] Browser dev tools open (for web testing)

---

## 🔧 Phase 1: Backend API Testing

### Test 1.1: Health Check
```bash
# Quick verification backend is running
curl http://localhost:8000/api/sync/stats

# Expected response:
# {
#   "users": {
#     "total": 0,
#     "synced": 0,
#     "unsynced": 0,
#     "syncPercentage": 0
#   }
# }
```

### Test 1.2: User Sync Endpoint
```bash
# Test POST /api/users/sync-firebase
curl -X POST http://localhost:8000/api/users/sync-firebase \
  -H "Content-Type: application/json" \
  -d '{
    "firebase_uid": "test-uid-123",
    "email": "testuser@example.com",
    "displayName": "Test User",
    "syncedAt": "2025-12-26T10:00:00+00:00"
  }'

# Expected response: 201 Created
# {
#   "message": "User synced from Firebase successfully",
#   "user": {
#     "id": 1,
#     "email": "testuser@example.com",
#     "firebase_uid": "test-uid-123",
#     "is_firebase_synced": true
#   }
# }
```

**What to check:**
- [ ] Response code is 201 (Created)
- [ ] User created in MySQL
- [ ] Firebase UID stored correctly
- [ ] is_firebase_synced is true

### Test 1.3: Get User by Firebase UID
```bash
# Test GET /api/users/firebase/{firebaseUid}
curl http://localhost:8000/api/users/firebase/test-uid-123

# Expected response: 200 OK
# {
#   "user": {
#     "id": 1,
#     "email": "testuser@example.com",
#     "firebase_uid": "test-uid-123",
#     "is_firebase_synced": true
#   },
#   "synced": true
# }
```

**What to check:**
- [ ] Returns correct user
- [ ] Firebase UID matches
- [ ] Sync status accurate

### Test 1.4: Check Unsynced Users
```bash
# Test GET /api/users/unsynced
curl http://localhost:8000/api/users/unsynced

# Expected response: 200 OK
# {
#   "count": 0,
#   "users": []
# }
```

**What to check:**
- [ ] Returns empty list (all synced)
- [ ] Count is 0

### Test 1.5: Sync Statistics
```bash
# Test GET /api/sync/stats
curl http://localhost:8000/api/sync/stats

# Expected response: 200 OK
# {
#   "users": {
#     "total": 1,
#     "synced": 1,
#     "unsynced": 0,
#     "syncPercentage": 100
#   }
# }
```

**What to check:**
- [ ] Total count increased
- [ ] Synced count matches
- [ ] Percentage is 100%

### Test 1.6: Database Verification
```bash
# Check MySQL directly
php artisan tinker

# In tinker console:
>>> User::all()
>>> User::where('firebase_uid', 'test-uid-123')->first()
>>> DB::table('users')->get()
```

**What to check:**
- [ ] User exists in users table
- [ ] firebase_uid column exists
- [ ] is_firebase_synced is true
- [ ] firebase_synced_at is set

---

## 🔐 Phase 2: Firebase Authentication Testing

### Test 2.1: Sign Up Flow
```dart
// In your Flutter app
final firebaseAuth = Provider.of<FirebaseAuthProvider>(context, listen: false);

await firebaseAuth.signUpWithEmail(
  email: 'newuser@example.com',
  password: 'TestPassword123!',
  displayName: 'John Doe',
);
```

**What to check (Flutter):**
- [ ] No error shown
- [ ] User can sign up
- [ ] App doesn't crash

**What to check (Firebase Console):**
- [ ] Go to Firebase Console → Authentication
- [ ] User appears in users list
- [ ] Email verified

**What to check (MySQL):**
```bash
php artisan tinker
>>> User::where('email', 'newuser@example.com')->first()
```
- [ ] User exists
- [ ] firebase_uid is set
- [ ] is_firebase_synced is true

### Test 2.2: Sign In Flow
```dart
final firebaseAuth = Provider.of<FirebaseAuthProvider>(context, listen: false);

final success = await firebaseAuth.signInWithEmail(
  email: 'newuser@example.com',
  password: 'TestPassword123!',
);

if (success) {
  print('✅ Sign in successful');
} else {
  print('❌ Sign in failed');
}
```

**What to check:**
- [ ] Success message shown
- [ ] User logged in
- [ ] Can access app features

### Test 2.3: Presence Tracking
```bash
# Check Firestore after signing in/out
# Go to Firebase Console → Firestore → users collection
# Click on user document with matching firebase_uid

# Expected fields:
# {
#   "email": "newuser@example.com",
#   "displayName": "John Doe",
#   "createdAt": <timestamp>,
#   "lastLogin": <recent timestamp>,
#   "isOnline": true
# }
```

**What to check:**
- [ ] Firestore user document created
- [ ] isOnline is true when logged in
- [ ] lastLogin updated
- [ ] lastSeen updated on logout

---

## 🔄 Phase 3: Real-Time Streaming Testing

### Test 3.1: Aid Programs Stream
```dart
// In your provider or screen
final realtimeService = RealtimeService();

// Listen to stream
realtimeService.streamAidPrograms(status: 'active').listen((programs) {
  print('Received ${programs.length} programs');
  programs.forEach((p) {
    print('Program: ${p['name']} - Status: ${p['status']}');
  });
});
```

**What to test:**
1. Add program to MySQL backend
2. Manually sync to Firebase:
```bash
# Add to Firestore manually via Console, or
# Implement sync endpoint
POST /api/aid-programs/sync
```
3. Verify it appears in real-time stream

**What to check:**
- [ ] Stream receives data
- [ ] Updates appear in real-time
- [ ] Correct program count
- [ ] Program details accurate

### Test 3.2: Emergency Alerts Stream
```dart
RealtimeService().streamEmergencyAlerts(severity: 'high')
  .listen((alerts) {
    print('Emergency alerts: ${alerts.length}');
  });
```

**Manual test:**
1. Create emergency alert via backend:
```bash
POST /api/emergencies/sync-firebase
{
  "firebase_id": "alert-123",
  "title": "Test Alert",
  "location": "Test Location",
  "severity": "high",
  "status": "active"
}
```

2. Check Firestore collection: `emergency_notifications`
3. Verify stream receives it

### Test 3.3: User Notifications Stream
```dart
RealtimeService().streamUserNotifications(currentUserId)
  .listen((notifications) {
    print('New notifications: ${notifications.length}');
  });
```

**Manual test:**
1. Send notification via API or code:
```bash
# Via Firestore Console or code
HybridDataService().sendNotification(
  recipientId: userId,
  title: 'Test Notification',
  message: 'This is a test',
  type: 'aid_update',
);
```

2. Verify stream receives notification
3. Check notification appears in UI

---

## 🔄 Phase 4: Data Sync Testing

### Test 4.1: Firebase to MySQL Sync
```bash
# Create data in Firestore Console manually
# Go to: aid_programs collection → Add document → Set fields:
# {
#   "id": "prog-123",
#   "name": "Test Program",
#   "status": "active"
# }

# Now test API sync endpoint (if implemented)
POST /api/aid-programs/sync-from-firebase
{
  "firebase_id": "prog-123"
}

# Verify in MySQL
php artisan tinker
>>> DB::table('aid_programs')->where('firebase_id', 'prog-123')->first()
```

**What to check:**
- [ ] Data appears in MySQL
- [ ] All fields synced correctly
- [ ] No data loss
- [ ] Timestamp updated

### Test 4.2: MySQL to Firebase Sync
```bash
# Create program in MySQL
php artisan tinker
>>> App\Models\AidProgram::create([
  'name' => 'Sync Test Program',
  'description' => 'Testing sync',
  'status' => 'active',
  'category' => 'food'
])

# Now sync to Firebase
HybridDataService().syncAidProgramToFirebase('program-id');

# Verify in Firestore Console
# Go to: aid_programs collection → Find the document
```

**What to check:**
- [ ] Program appears in Firestore
- [ ] All fields present
- [ ] No duplicates
- [ ] Timestamp correct

### Test 4.3: Conflict Resolution
```bash
# Scenario: Update same record in both systems

# 1. Update in MySQL
php artisan tinker
>>> $program = App\Models\AidProgram::find(1);
>>> $program->update(['name' => 'Updated in MySQL'])

# 2. Update in Firestore (via Console)
# Set name to 'Updated in Firestore'

# 3. Trigger conflict resolution
HybridDataService().resolveConflict(
  collectionName: 'aid_programs',
  docId: 'program-1',
  mysqlData: {...},
  firebaseData: {...}
);

# 4. Verify only one version kept (latest by timestamp)
```

**What to check:**
- [ ] Conflict detected
- [ ] Latest version kept
- [ ] No data corruption
- [ ] Correct resolution

---

## 📱 Phase 5: Frontend UI Testing

### Test 5.1: Sign Up Screen
```dart
// Manual Flutter app test
1. Open app
2. Click Register
3. Enter email: test2@example.com
4. Enter password: SecurePass123!
5. Enter name: Test User 2
6. Click Sign Up
```

**What to check:**
- [ ] No errors shown
- [ ] User created in Firebase Auth
- [ ] User created in MySQL
- [ ] User created in Firestore
- [ ] Can log in with new account

**Verify in three places:**
```bash
# Firebase Console → Authentication
# MySQL
php artisan tinker
>>> User::where('email', 'test2@example.com')->first()

# Firestore
# users collection → find document with matching firebase_uid
```

### Test 5.2: Login Screen
```dart
1. Open app (logged out)
2. Click Login
3. Enter email: test2@example.com
4. Enter password: SecurePass123!
5. Click Login
```

**What to check:**
- [ ] Login successful
- [ ] Redirected to dashboard
- [ ] User data loaded
- [ ] isOnline = true in Firestore

### Test 5.3: Real-Time Dashboard
```dart
1. Log in as admin
2. Go to dashboard
3. (In another window) Add/update an aid program in MySQL
4. Watch dashboard - should update in real-time
```

**What to check:**
- [ ] Program list updates without page refresh
- [ ] New programs appear instantly
- [ ] Program counts accurate
- [ ] No page lag or freezing

---

## 🌐 Phase 6: Offline Testing

### Test 6.1: Offline Data Access
```dart
1. Turn off device Wi-Fi/mobile data
2. Keep app open
3. Navigate to different screens
4. Observe what data is visible
```

**What to check:**
- [ ] Previously loaded data still visible
- [ ] Offline message shown (if implemented)
- [ ] App doesn't crash
- [ ] Can still interact with cached data

### Test 6.2: Offline Queue
```dart
1. Turn off connection
2. Try to create a new item
3. Observe local queuing behavior
4. Turn connection back on
5. Verify queued items sync
```

**What to check:**
- [ ] Action queued locally
- [ ] Once online, syncs automatically
- [ ] No data loss
- [ ] Proper sync order maintained

### Test 6.3: Offline to Online Transition
```dart
1. Start with connection off
2. View offline data
3. Turn connection back on
4. Observe sync behavior
```

**What to check:**
- [ ] Synced without errors
- [ ] Latest data updated
- [ ] Real-time listeners resumed
- [ ] Notifications received

---

## 🚨 Phase 7: Error Handling Testing

### Test 7.1: Network Error
```dart
// Turn off internet connection
await firebaseAuth.signInWithEmail(
  email: 'user@example.com',
  password: 'password',
);
// Observe error handling
```

**What to check:**
- [ ] User-friendly error message
- [ ] No crashes
- [ ] Can retry
- [ ] Proper error logging

### Test 7.2: Invalid Credentials
```dart
await firebaseAuth.signInWithEmail(
  email: 'user@example.com',
  password: 'wrongpassword',
);
```

**What to check:**
- [ ] Error message shown
- [ ] User not authenticated
- [ ] Can try again
- [ ] No security info leaked

### Test 7.3: Duplicate Email
```dart
// Try to sign up with existing email
await firebaseAuth.signUpWithEmail(
  email: 'existing@example.com',
  password: 'password123',
  displayName: 'New User',
);
```

**What to check:**
- [ ] Error shown
- [ ] User not created
- [ ] Can choose different email
- [ ] Database not corrupted

### Test 7.4: API Errors
```bash
# Send invalid data to API
curl -X POST http://localhost:8000/api/users/sync-firebase \
  -H "Content-Type: application/json" \
  -d '{
    "firebase_uid": "test",
    "email": "invalid"
  }'

# Expected: 422 Unprocessable Entity
```

**What to check:**
- [ ] Proper error code returned
- [ ] Error message clear
- [ ] Validation errors listed
- [ ] Database not modified

---

## ✅ Comprehensive Testing Checklist

### Backend
- [ ] `/api/sync/stats` returns 200
- [ ] POST `/api/users/sync-firebase` creates user
- [ ] GET `/api/users/firebase/{uid}` retrieves user
- [ ] GET `/api/users/unsynced` works
- [ ] Database migration runs successfully
- [ ] All new tables created
- [ ] New columns added to users table

### Firebase Console
- [ ] Authentication enabled
- [ ] User appears after signup
- [ ] Firestore database exists
- [ ] Collections accessible
- [ ] Security rules set
- [ ] Storage bucket ready (if using files)

### Flutter App
- [ ] App builds successfully
- [ ] Firebase initializes
- [ ] Sign up works
- [ ] Sign in works
- [ ] Real-time streams work
- [ ] Offline caching works
- [ ] Error messages clear

### Data Sync
- [ ] Firebase → MySQL syncs
- [ ] MySQL → Firebase syncs
- [ ] Conflicts resolved correctly
- [ ] No duplicates created
- [ ] Timestamps accurate
- [ ] All fields transferred

### User Experience
- [ ] Sign up/login smooth
- [ ] Real-time updates visible
- [ ] No loading delays
- [ ] Offline works gracefully
- [ ] Error recovery possible
- [ ] Notifications delivered

---

## 🐛 Troubleshooting During Testing

### Issue: Firebase not initializing
```
Check:
1. main.dart has Firebase.initializeApp()
2. firebase_options.dart has correct projectId
3. Google Services JSON correct (Android)
4. Firebase pods installed (iOS)
```

### Issue: Firestore data not appearing
```
Check:
1. Firestore database created in Firebase Console
2. Collection names match exactly
3. Security rules allow read/write
4. Device has internet connection
5. Firestore is in test mode (if starting)
```

### Issue: API endpoints not working
```
Check:
1. Backend running on port 8000
2. Routes defined in api.php
3. Controller methods exist
4. Database columns exist (after migration)
5. No PHP syntax errors
```

### Issue: User not syncing to MySQL
```
Check:
1. Migration ran successfully
2. API endpoint called with correct data
3. Validation rules pass
4. Database connection working
5. API response shows 201 Created
```

### Issue: Real-time updates not working
```
Check:
1. Stream being listened to correctly
2. Firestore permissions allow read
3. Data actually exists in Firestore
4. Collection name spelled correctly
5. No duplicate listeners (memory leak)
```

---

## 📊 Testing Report Template

Use this template to document your testing:

```
Firebase + MySQL Hybrid Testing Report
Date: December 26, 2025
Tester: _______________

BACKEND TESTS
[ ] Health check /api/sync/stats - PASS/FAIL
[ ] User sync endpoint - PASS/FAIL
[ ] Get user by UID - PASS/FAIL
[ ] Unsynced users endpoint - PASS/FAIL
[ ] Statistics endpoint - PASS/FAIL

DATABASE TESTS
[ ] Migration executed - PASS/FAIL
[ ] Firebase columns added - PASS/FAIL
[ ] Emergency alerts table created - PASS/FAIL
[ ] Notifications table created - PASS/FAIL

FIREBASE AUTH TESTS
[ ] Sign up works - PASS/FAIL
[ ] User appears in Firebase Auth - PASS/FAIL
[ ] User appears in MySQL - PASS/FAIL
[ ] User appears in Firestore - PASS/FAIL
[ ] Sign in works - PASS/FAIL

REAL-TIME TESTS
[ ] Aid programs stream works - PASS/FAIL
[ ] Emergency alerts stream works - PASS/FAIL
[ ] Notifications stream works - PASS/FAIL
[ ] Updates appear in real-time - PASS/FAIL

SYNC TESTS
[ ] Firebase to MySQL sync - PASS/FAIL
[ ] MySQL to Firebase sync - PASS/FAIL
[ ] Conflict resolution works - PASS/FAIL
[ ] No duplicates created - PASS/FAIL

OFFLINE TESTS
[ ] Cached data visible offline - PASS/FAIL
[ ] Syncs after reconnect - PASS/FAIL
[ ] No data loss - PASS/FAIL

ERROR HANDLING
[ ] Invalid credentials handled - PASS/FAIL
[ ] Network errors handled - PASS/FAIL
[ ] Duplicate emails rejected - PASS/FAIL
[ ] API errors return proper codes - PASS/FAIL

NOTES:
_________________________________________________________________

Issues Found:
_________________________________________________________________

Recommendations:
_________________________________________________________________
```

---

## 🎯 Success Criteria

You'll know testing is successful when:

✅ All backend endpoints return 200/201 responses
✅ User successfully signs up and appears in all three systems
✅ Real-time streams update without page refresh
✅ Data syncs correctly between Firebase and MySQL
✅ Offline mode works smoothly
✅ No database errors
✅ No Firebase permission errors
✅ App doesn't crash during testing
✅ Timestamps are accurate
✅ No duplicate records created

---

## 📞 Quick Testing Commands

```bash
# Backend tests
php artisan serve                          # Start server
php artisan tinker                         # Interactive shell
php artisan migrate                        # Run migrations
curl http://localhost:8000/api/sync/stats  # Test endpoint

# Flutter tests
flutter run                                # Run app
flutter test                               # Unit tests
flutter run -v                             # Verbose mode

# Database checks
php artisan tinker
>>> User::all()
>>> DB::table('emergency_alerts')->get()
>>> DB::table('notifications')->get()
```

---

**Happy Testing! 🧪**

Start with Phase 1 (Backend) and work through each phase systematically. Document any issues and use the troubleshooting section for solutions.
