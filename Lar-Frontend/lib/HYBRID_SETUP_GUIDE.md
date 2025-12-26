# Hybrid Firebase + MySQL Setup Guide

This guide explains how to use Firebase alongside your existing MySQL backend for the Lubok Antu RescueNet application.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Frontend)                    │
└─────────────────────────────────────────────────────────────┘
                    ↙                         ↘
        ┌──────────────────────┐    ┌──────────────────────┐
        │ Firebase Services    │    │  API Service (Dio)   │
        │  - Real-time data    │    │  - HTTP Requests     │
        │  - Notifications     │    │  - Data Persistence  │
        │  - Authentication    │    │  - User Management   │
        └──────────────────────┘    └──────────────────────┘
                    ↓                         ↓
        ┌──────────────────────┐    ┌──────────────────────┐
        │     Firebase DB      │    │   Laravel Backend    │
        │ (Real-time cache)    │    │   (MySQL Database)   │
        │  - Aid Programs      │    │   - Primary Source   │
        │  - Notifications     │    │   - Business Logic   │
        │  - Emergency Alerts  │    │   - Validation       │
        └──────────────────────┘    └──────────────────────┘
```

## Services Created

### 1. **firebase_service.dart**
Core Firebase operations wrapper
- Authentication (sign up, sign in, reset password)
- Firestore CRUD operations
- Real-time listeners
- File uploads to Storage
- User document management

### 2. **hybrid_data_service.dart**
Data synchronization between MySQL and Firebase
- One-way and two-way sync strategies
- Conflict resolution
- Offline persistence
- Data deduplication

### 3. **realtime_service.dart**
Real-time data streaming from Firestore
- Live aid program updates
- Emergency alert streams
- User notifications
- Admin dashboard statistics
- Presence detection

## Usage Examples

### Authentication

```dart
final firebase = FirebaseService();

// Sign up
final userCredential = await firebase.signUp(
  'user@example.com',
  'password123',
  'John Doe',
);

// Sign in
await firebase.signIn('user@example.com', 'password123');

// Sign out
await firebase.signOut();
```

### Sync Strategy 1: MySQL Primary (Recommended for Your Project)

Data flows: **MySQL → Firebase**

```dart
final hybrid = HybridDataService();

// After fetching aid programs from MySQL, sync to Firebase
await hybrid.syncAidProgramToFirebase('program-id');

// Or sync all programs
await hybrid.syncAllAidProgramsToFirebase();

// Listen to real-time updates in UI
Stream<List<Map<String, dynamic>>> programs = 
  hybrid.getAidProgramsHybrid(status: 'active');
```

### Real-Time Updates

```dart
final realtime = RealtimeService();

// Stream aid programs in real-time
Stream<List<Map<String, dynamic>>> programsStream = 
  realtime.streamAidPrograms(status: 'active');

// Stream emergency alerts
Stream<List<Map<String, dynamic>>> emergenciesStream = 
  realtime.streamEmergencyAlerts(severity: 'high');

// Stream user notifications
Stream<List<Map<String, dynamic>>> notificationsStream = 
  realtime.streamUserNotifications(userId);
```

### Emergency Alerts (Dual Storage)

```dart
final hybrid = HybridDataService();

// Create alert in both MySQL and Firebase
await hybrid.createEmergencyAlert({
  'title': 'Flash Flood Alert',
  'location': 'Lubok Antu',
  'severity': 'high',
  'description': 'Heavy rainfall expected',
});
```

### Notifications

```dart
final hybrid = HybridDataService();

// Send notification to user (stored in both systems)
await hybrid.sendNotification(
  recipientId: 'user-123',
  title: 'New Aid Program',
  message: 'Food aid program is now available',
  type: 'aid_update',
  metadata: {'programId': 'program-456'},
);
```

## Firestore Collections Structure

### users
```
users/{uid}
  - uid: string
  - email: string
  - displayName: string
  - createdAt: timestamp
  - lastLogin: timestamp
  - isSyncedWithMySQL: boolean
  - isOnline: boolean
  - lastSeen: timestamp
```

### aid_programs
```
aid_programs/{programId}
  - id: string (MySQL ID)
  - name: string
  - description: string
  - status: string (active/inactive/closed)
  - category: string
  - createdAt: timestamp
  - lastSyncedFromMySQL: timestamp
```

### emergency_notifications
```
emergency_notifications/{notificationId}
  - id: string (MySQL ID)
  - recipientId: string
  - title: string
  - message: string
  - type: string (emergency/aid_update/general)
  - timestamp: timestamp
  - read: boolean
  - severity: string (high/medium/low)
```

### beneficiaries
```
beneficiaries/{beneficiaryId}
  - id: string (MySQL ID)
  - aidProgramId: string
  - name: string
  - status: string
  - timestamp: timestamp
```

## Integration with Your Existing Code

### In Your Providers

```dart
// aid_program_provider.dart
import 'package:lar/services/firebase_service.dart';
import 'package:lar/services/realtime_service.dart';

class AidProgramProvider extends ChangeNotifier {
  final RealtimeService _realtimeService = RealtimeService();
  
  StreamSubscription? _subscription;
  
  void initializeRealTime() {
    _subscription = _realtimeService.streamAidPrograms().listen((programs) {
      _programs = programs;
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### In Your Screens

```dart
// Replace static lists with real-time streams
StreamBuilder<List<Map<String, dynamic>>>(
  stream: RealtimeService().streamAidPrograms(status: 'active'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final program = snapshot.data![index];
          return AidProgramCard(program: program);
        },
      );
    }
    return LoadingWidget();
  },
)
```

## Firebase Security Rules

Create appropriate rules in Firebase Console:

```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Anyone can read aid programs
    match /aid_programs/{document=**} {
      allow read: if true;
      allow write: if request.auth.token.isAdmin == true;
    }
    
    // Users can only read their own notifications
    match /emergency_notifications/{document=**} {
      allow read, write: if resource.data.recipientId == request.auth.uid 
                           || request.auth.token.isAdmin == true;
    }
  }
}
```

## Best Practices

1. **MySQL as Source of Truth**: Keep MySQL as your primary data source
2. **Firebase for Real-Time**: Use Firebase for features needing real-time updates
3. **Sync Strategically**: Only sync data that benefits from real-time updates
4. **Error Handling**: Always wrap Firebase calls in try-catch
5. **Offline Support**: Enable offline persistence for critical features
6. **Performance**: Use pagination and limits to reduce data transfer
7. **Security**: Always implement proper authentication checks

## Troubleshooting

### Firebase not initializing
- Check if `Firebase.initializeApp()` is called in main.dart before runApp()
- Verify firebase_options.dart has correct credentials

### Data not syncing
- Check Firestore security rules
- Ensure backend API endpoints are correct
- Verify network connectivity

### Real-time updates not showing
- Check if Stream is properly connected in StreamBuilder
- Verify Firestore collection names match exactly

## Next Steps

1. Set up Firestore security rules in Firebase Console
2. Create backend API endpoints for syncing if using one-way sync
3. Implement error handling and logging
4. Test with actual data
5. Monitor Firestore usage and optimize queries

For more details, check the service files:
- `firebase_service.dart`
- `hybrid_data_service.dart`
- `realtime_service.dart`
