# Firebase Hybrid Setup - Quick Reference

## Files Created

### Frontend (Lar-Frontend/lib)
```
services/
├── firebase_service.dart       # Core Firebase operations
├── hybrid_data_service.dart    # MySQL ↔ Firebase sync
└── realtime_service.dart       # Real-time data streams

providers/
└── firebase_auth_provider.dart # Authentication with sync

HYBRID_SETUP_GUIDE.md           # Detailed setup guide
```

### Backend (Lar-Backend)
```
app/Http/Controllers/
└── FirebaseSyncController.php  # API endpoints for syncing

database/migrations/
└── 2025_12_26_000001_add_firebase_columns.php
```

## Essential Commands

### Run Database Migration
```bash
cd Lar-Backend
php artisan migrate
```

### Fetch Flutter Dependencies
```bash
cd Lar-Frontend
flutter pub get
```

## Key Code Snippets

### Initialize Firebase in main.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/firebase_auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
        ChangeNotifierProvider(create: (_) => AidProgramProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

### Sign Up with Firebase
```dart
final firebaseAuth = Provider.of<FirebaseAuthProvider>(context, listen: false);
await firebaseAuth.signUpWithEmail(
  email: email,
  password: password,
  displayName: displayName,
);
// User automatically synced to MySQL ✓
```

### Real-Time Aid Programs
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: RealtimeService().streamAidPrograms(status: 'active'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          return AidProgramCard(program: snapshot.data![index]);
        },
      );
    }
    return LoadingWidget();
  },
)
```

### Send Emergency Alert
```dart
final hybrid = HybridDataService();
await hybrid.createEmergencyAlert({
  'title': 'Flood Alert',
  'location': 'Lubok Antu',
  'severity': 'high',
  'description': 'Heavy rainfall expected',
});
// Saved to MySQL and Firebase simultaneously ✓
```

### Send Notification to User
```dart
final hybrid = HybridDataService();
await hybrid.sendNotification(
  recipientId: userId,
  title: 'Aid Available',
  message: 'Food aid program available',
  type: 'aid_update',
);
// User notified in real-time via Firebase ✓
```

### Listen to User Notifications
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: RealtimeService().streamUserNotifications(currentUserId),
  builder: (context, snapshot) {
    return NotificationCenter(notifications: snapshot.data ?? []);
  },
)
```

## API Endpoints (Backend)

```
POST   /api/users/sync-firebase              # Sync Firebase user to MySQL
GET    /api/users/firebase/{firebaseUid}     # Check if user exists
GET    /api/users/unsynced                   # Get unsynced users
POST   /api/emergencies/sync-firebase        # Sync alert from Firebase
POST   /api/notifications/sync-firebase      # Sync notification from Firebase
GET    /api/sync/stats                       # View sync statistics
POST   /api/sync/resolve-conflict            # Handle data conflicts
```

## Architecture at a Glance

```
User Action
    ↓
┌─────────────────────┐
│  Flutter Frontend   │
└─────┬───────────────┘
      │
  ┌───┴────┐
  ↓        ↓
Firebase  API (Dio)
  ↓        ↓
┌─────────────────┐
│ Real-Time Data  │ MySQL DB
│ (Firestore)     │ (Persistent)
└─────────────────┘
```

**MySQL** = Primary source, persistent storage
**Firebase** = Real-time cache, instant updates

## Firestore Collections

| Collection | Purpose | Sync From |
|-----------|---------|-----------|
| users | User profiles | Firebase + MySQL |
| aid_programs | Available programs | MySQL → Firebase |
| emergency_notifications | Real-time alerts | Firebase → MySQL |
| beneficiaries | Aid recipients | MySQL → Firebase |

## Security Rules (Copy to Firebase Console)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /aid_programs/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.isAdmin == true;
    }
    match /emergency_notifications/{document=**} {
      allow read: if resource.data.recipientId == request.auth.uid 
                     || request.auth.token.isAdmin == true;
    }
  }
}
```

## Testing Checklist

- [ ] `php artisan migrate` runs successfully
- [ ] Flutter app builds without errors
- [ ] Firebase initializes on app launch
- [ ] User can sign up via Firebase
- [ ] User appears in MySQL users table
- [ ] Real-time streams show data correctly
- [ ] Emergency alerts sync both ways
- [ ] Notifications work in real-time
- [ ] Firestore security rules allow proper access

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Firebase not initializing | Check Firebase.initializeApp() in main.dart |
| Firestore rules rejecting | Review security rules in Firebase Console |
| API sync fails | Verify endpoint URLs and authentication headers |
| Real-time data empty | Check Firestore collection names and user permissions |
| Migration errors | Run `php artisan migrate:refresh` |

## What's Synced

| Data | From | To | When |
|------|------|----|----|
| User signup | Firebase | MySQL | Immediately after signup |
| Aid programs | MySQL | Firebase | Manual trigger via API |
| Emergency alerts | Both | Both | Immediately created |
| Notifications | Firebase | MySQL | Async for backup |
| User presence | Firebase | — | Real-time status |

## Service Classes Reference

### FirebaseService
- `signUp()`, `signIn()`, `signOut()`
- `addDocument()`, `getDocument()`, `updateDocument()`
- `listenToCollection()`, `listenToDocument()`
- `uploadFile()`, `getDownloadUrl()`

### HybridDataService
- `syncFirebaseUserToMySQL()`
- `syncAidProgramToFirebase()`
- `createEmergencyAlert()`
- `sendNotification()`
- `resolveConflict()`

### RealtimeService
- `streamAidPrograms()`
- `streamEmergencyAlerts()`
- `streamUserNotifications()`
- `streamAdminStats()`

## Performance Tips

1. Use pagination: `.limit(20).snapshots()`
2. Add Firestore indexes for complex queries
3. Enable offline persistence (automatic)
4. Use `where` clauses to filter early
5. Avoid listening to full collections

## Next Actions

1. ✅ Run migration
2. ✅ Update main.dart
3. ✅ Set Firestore rules
4. ✅ Update authentication screens
5. ✅ Convert lists to streams
6. ✅ Test thoroughly
7. ✅ Monitor /api/sync/stats

---

**For detailed information, see: HYBRID_FIREBASE_IMPLEMENTATION.md**
