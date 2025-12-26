# Hybrid Firebase + MySQL Architecture Diagrams

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER INTERFACE (Flutter)                     │
│                    Citizen & Admin Dashboards                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
         ┌──────▼──────────┐      ┌──────▼──────────┐
         │  Firebase       │      │  HTTP/REST API  │
         │  Services       │      │  (Dio Client)   │
         │                 │      │                 │
         │ • Auth          │      │ • Sign Up/Login │
         │ • Firestore     │      │ • CRUD Ops      │
         │ • Storage       │      │ • Reports       │
         │ • Messaging     │      │ • Statistics    │
         └──────┬──────────┘      └──────┬──────────┘
                │                        │
                │ Real-Time       Persistent
                │ Updates         Data
                │                 Storage
         ┌──────▼──────────┐      ┌──────▼──────────┐
         │    Firebase     │      │  Laravel        │
         │    Backend      │      │  Backend        │
         │                 │      │                 │
         │ • Firestore     │      │ • Business      │
         │ • Auth          │      │   Logic         │
         │ • Storage       │      │ • Validation    │
         │ • Real-time DB  │      │ • Security      │
         └──────┬──────────┘      └──────┬──────────┘
                │                        │
                └────────────┬───────────┘
                             │
                        ┌────▼────────┐
                        │  MySQL DB   │
                        │  (Primary   │
                        │   Source    │
                        │   of Truth) │
                        └─────────────┘
```

## User Journey: Sign Up

```
┌──────────────────────────────────────────────────────────────────┐
│                    USER CLICKS "SIGN UP"                         │
└───────────────────┬──────────────────────────────────────────────┘
                    │
                    ▼
            ┌───────────────────┐
            │ Enter Email &     │
            │ Password in App   │
            └────────┬──────────┘
                     │
                     ▼
    ┌────────────────────────────────────┐
    │ FirebaseAuthProvider.signUpWithEmail
    └────────────┬───────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   ┌────────────┐  ┌──────────────────┐
   │  Firebase  │  │ Create Firestore │
   │   Auth     │  │ User Document    │
   │ Creates    │  │                  │
   │ User       │  │ uid, email,      │
   │            │  │ displayName,     │
   │            │  │ createdAt        │
   └────┬───────┘  └────────┬─────────┘
        │                   │
        └───────┬───────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │ HybridDataService.syncFirebase   │
   │ UserToMySQL()                    │
   └────────────┬─────────────────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │ POST /api/users/sync-firebase    │
   │ Send Firebase UID to Laravel     │
   └────────────┬─────────────────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │ FirebaseSyncController.php       │
   │ Creates user in MySQL            │
   └────────────┬─────────────────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │ ✅ User Created in Both Systems! │
   │                                  │
   │ • Firebase Auth - Ready          │
   │ • MySQL DB - Record              │
   │ • Firestore - Profile            │
   │ • App Session - Active           │
   └──────────────────────────────────┘
```

## Real-Time Aid Programs Flow

```
MYSQL (Source)                  FIREBASE (Cache)              UI (Display)
    │                               │                           │
    │                               │                           │
    ▼                               ▼                           ▼
┌─────────────┐             ┌──────────────┐          ┌──────────────────┐
│ Aid Program │  (Sync)     │ Firestore    │ (Stream) │ StreamBuilder    │
│ Created in  │──────────►  │ aid_programs │─────────►│ Displays Live    │
│ Admin Panel │             │ Collection   │          │ Updates          │
└─────────────┘             └──────────────┘          └──────────────────┘
     │                           │                          │
     │                           │                          │
     │ Backend API               │                    User Sees
     │ /api/aid-programs         │                    Updates
     │                           │                    In Real-Time
     │                           │
     │  Method 1: Manual Trigger │
     │  ┌─────────────────────────────┐
     │  │ Batch sync all programs     │
     │  │ POST /api/aid-programs/sync │
     │  └─────────────────────────────┘
     │
     │  Method 2: On Create
     │  ┌──────────────────────────┐
     │  │ Auto-sync new program    │
     │  │ Hook on model creation   │
     │  └──────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    SYNC STATUS MONITORING                        │
│                                                                  │
│  GET /api/sync/stats  ─►  {                                     │
│                            "totalPrograms": 45,                 │
│                            "syncedToFirebase": 45,              │
│                            "lastSync": "2025-12-26T10:30:00",   │
│                            "syncPercentage": 100%               │
│                          }                                      │
└──────────────────────────────────────────────────────────────────┘
```

## Emergency Alert Creation

```
ADMIN CREATES ALERT
        │
        ▼
    ┌────────────────────────────────┐
    │ HybridDataService.              │
    │ createEmergencyAlert()          │
    └────────┬───────────────────────┘
             │
     ┌───────┴────────┐
     │                │
     ▼                ▼
┌──────────────┐  ┌──────────────┐
│  MySQL DB    │  │  Firestore   │
│              │  │              │
│ • Persist    │  │ • Real-time  │
│   data       │  │ • Searchable │
│ • Records    │  │ • Cached     │
│ • Reports    │  │              │
└──────┬───────┘  └──────┬───────┘
       │                 │
       └────────┬────────┘
                │
     ┌──────────▼──────────┐
     │  All Connected Users│
     │  Stream Receives    │
     │  Alert Instantly    │
     └────────┬────────────┘
              │
     ┌────────▼──────────┐
     │  User Notifications│
     │  Display Alert    │
     │  Sound/Vibration  │
     │  In Real-Time     │
     └───────────────────┘
```

## Data Sync Conflict Resolution

```
CONFLICT SCENARIO:
    User offline, modifies data locally
    Server has updated version
    User comes online - versions differ

        ┌─────────────────────────────────┐
        │  Detect Conflict:               │
        │  Firebase version vs MySQL      │
        │  Compare timestamps             │
        └────────────┬────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
    Firebase Newer        MySQL Newer
    (timestamp             (timestamp
     comparison)          comparison)
         │                       │
         ▼                       ▼
    ┌────────────┐       ┌────────────┐
    │ Keep       │       │ Keep       │
    │ Firebase   │       │ MySQL      │
    │ Update     │       │ Update     │
    │ MySQL from │       │ Firebase   │
    │ Firebase   │       │ from MySQL │
    └────┬───────┘       └────┬───────┘
         │                    │
         └────────┬───────────┘
                  │
                  ▼
         ┌──────────────────┐
         │ ✅ Resolved      │
         │ Single Source of│
         │ Truth           │
         └──────────────────┘
```

## Offline Support Flow

```
ONLINE MODE
    │
    └──► Connected to Firebase
    └──► Connected to MySQL
    └──► Real-time updates
    └──► All features available

         Real-Time
         Streams
              │
              ▼
    ┌─────────────────┐
    │  Firestore Live │
    │  Listeners      │
    └─────────────────┘

OFFLINE MODE (Loss of Connection)
    │
    ├──► Firestore local cache continues
    ├──► No real-time updates (stale data)
    ├──► MySQL queries fail (local cache used)
    ├──► User can still view cached data
    ├──► Actions queued locally
    │
    └──► When connection returns...
         └──► All changes synced
         └──► Real-time resumed
         └──► Queue processed
```

## Service Layer Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                         UI LAYER                              │
│                  (Screens & Widgets)                          │
└────────────────────────────┬────────────────────────────────┘
                             │
                    ┌────────┴──────────┐
                    │                   │
        ┌───────────▼──────┐   ┌────────▼──────────┐
        │  PROVIDERS       │   │  VIEWS & LOGIC    │
        │                  │   │                   │
        │ • AuthProvider   │   │ • ListViews       │
        │ • AidProvider    │   │ • StreamBuilders  │
        │ • Emergency      │   │ • Forms           │
        │   Provider       │   │ • Dialogs         │
        └───────────┬──────┘   └───────────────────┘
                    │
       ┌────────────▼────────────┐
       │                         │
       ▼                         ▼
┌─────────────────┐     ┌──────────────────────┐
│ FIREBASE LAYER  │     │  HTTP API LAYER      │
├─────────────────┤     ├──────────────────────┤
│ FirebaseService │     │ ApiService (Dio)     │
│ └─ Auth          │     │ └─ GET/POST/PUT/DEL │
│ └─ Firestore     │     │ └─ Headers/Auth      │
│ └─ Storage       │     │ └─ Error handling    │
└────────┬────────┘     └─────────┬────────────┘
         │                        │
         ▼                        ▼
   ┌──────────────┐      ┌──────────────┐
   │ HybridService│      │ HybridService│
   │ └─ Sync Ops  │      │ └─ Sync Ops  │
   │ └─ Conflicts │      │ └─ Conflicts │
   │ └─ Offline   │      │ └─ Offline   │
   └──────────────┘      └──────────────┘
         │                        │
         └────────────┬───────────┘
                      │
       ┌──────────────▼──────────────┐
       │   REALTIME SERVICE          │
       │                             │
       │ RealtimeService             │
       │ └─ streamAidPrograms()      │
       │ └─ streamEmergencies()      │
       │ └─ streamNotifications()    │
       │ └─ streamAdminStats()       │
       └─────────────────────────────┘
```

## API Endpoint Flow

```
Flutter App
    │
    ├─ User Sign Up
    │  │
    │  └─► POST /api/users/sync-firebase
    │      ├─► Validate Firebase UID
    │      ├─► Create user in MySQL
    │      ├─► Update sync status
    │      └─► Return user data
    │
    ├─ Get Aid Programs
    │  │
    │  └─► RealtimeService.streamAidPrograms()
    │      ├─► Listen to Firestore changes
    │      ├─► Real-time updates
    │      └─► No API call needed
    │
    ├─ Create Emergency
    │  │
    │  └─► POST /api/emergencies/sync-firebase
    │      ├─► Verify admin role
    │      ├─► Save to MySQL
    │      ├─► Mirror to Firestore
    │      └─► Trigger notifications
    │
    └─ Check Sync Status
       │
       └─► GET /api/sync/stats
           ├─► Count synced users
           ├─► Check last sync time
           └─► Return statistics
```

## Data Model Relationships

```
MYSQL
├── users
│   ├── id (PK)
│   ├── email
│   ├── password
│   ├── firebase_uid (FK to Firebase)
│   └── is_firebase_synced
│
├── aid_programs
│   ├── id (PK)
│   ├── name
│   ├── description
│   └── status
│
├── emergency_alerts
│   ├── id (PK)
│   ├── firebase_id (FK to Firestore)
│   ├── title
│   ├── location
│   └── severity
│
└── notifications
    ├── id (PK)
    ├── firebase_id (FK to Firestore)
    ├── user_id (FK to users)
    ├── message
    └── is_read

FIRESTORE
├── users/{uid}
│   ├── email
│   ├── displayName
│   └── createdAt
│
├── aid_programs/{programId}
│   ├── id (FK to MySQL)
│   ├── name
│   └── lastSyncedFromMySQL
│
├── emergency_notifications/{notificationId}
│   ├── id (FK to MySQL)
│   ├── recipientId
│   ├── title
│   └── timestamp
│
└── beneficiaries/{beneficiaryId}
    ├── id (FK to MySQL)
    ├── aidProgramId
    └── status
```

---

**These diagrams illustrate how your hybrid Firebase + MySQL system works together seamlessly!**
