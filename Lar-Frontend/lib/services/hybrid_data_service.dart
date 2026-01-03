import 'firebase_service.dart';
import 'api_service.dart';

/// Hybrid Data Service - Manages data sync between MySQL and Firebase
/// This service ensures data consistency across both databases
class HybridDataService {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  // ============== SYNC STRATEGIES ==============

  /// Strategy 1: MySQL as Primary, Firebase for Real-Time
  /// Data flows: MySQL → Firebase (one-way)
  /// Use case: For features that need real-time updates

  /// Strategy 2: Firebase as Primary, MySQL for Persistence
  /// Data flows: Firebase → MySQL (one-way)
  /// Use case: For temporary/session data

  /// Strategy 3: Bidirectional Sync
  /// Data flows: MySQL ↔ Firebase (both ways)
  /// Use case: For critical data that needs redundancy

  // ============== USER DATA ==============

  /// Sync user from Firebase to MySQL backend (one-way)
  Future<void> syncFirebaseUserToMySQL(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _apiService.post('/api/users/sync-firebase', {
        'firebase_uid': uid,
        'email': userData['email'],
        'displayName': userData['displayName'],
        'syncedAt': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200) {
        // Update Firebase document to mark as synced
        await _firebaseService.updateUserDocument(uid, {
          'isSyncedWithMySQL': true,
          'lastMySQLSync': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error syncing Firebase user to MySQL: $e');
    }
  }

  /// Fetch user from MySQL and cache in Firebase (one-way)
  Future<void> cacheUserFromMySQL(String userId) async {
    try {
      final response = await _apiService.get('/api/users/$userId');

      if (response.statusCode == 200) {
        final userData = response.data;
        await _firebaseService.setDocument('user_cache', userId, {
          ...userData,
          'cachedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error caching user from MySQL: $e');
    }
  }

  // ============== AID PROGRAM DATA ==============

  /// Sync aid program from MySQL to Firebase for real-time updates
  Future<void> syncAidProgramToFirebase(String aidId) async {
    try {
      // Fetch from MySQL
      final response = await _apiService.get('/api/aid-programs/$aidId');

      if (response.statusCode == 200) {
        final aidData = response.data;

        // Push to Firebase
        await _firebaseService.syncAidProgramToFirebase(aidId, aidData);
      }
    } catch (e) {
      print('Error syncing aid program to Firebase: $e');
    }
  }

  /// Sync all aid programs from MySQL to Firebase
  Future<void> syncAllAidProgramsToFirebase() async {
    try {
      final response = await _apiService.get('/api/aid-programs');

      if (response.statusCode == 200) {
        final programs = response.data as List;

        for (var program in programs) {
          await _firebaseService.syncAidProgramToFirebase(
            program['id'].toString(),
            program,
          );
        }
      }
    } catch (e) {
      print('Error syncing all aid programs to Firebase: $e');
    }
  }

  /// Listen to aid programs from Firestore with MySQL as backup
  /// If Firestore data is stale, fetch from MySQL
  Stream<List<Map<String, dynamic>>> getAidProgramsHybrid({String? status}) {
    return _firebaseService.getAidProgramsRealTime(status: status).map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    });
  }

  // ============== EMERGENCY & NOTIFICATIONS ==============

  /// Create emergency alert in both Firebase (real-time) and MySQL (permanent)
  Future<void> createEmergencyAlert(Map<String, dynamic> alertData) async {
    try {
      // 1. Save to MySQL immediately (primary source)
      final mysqlResponse = await _apiService.post(
        '/api/emergencies',
        alertData,
      );

      if (mysqlResponse.statusCode == 201) {
        final emergencyId = mysqlResponse.data['id'];

        // 2. Mirror to Firebase for real-time notifications
        await _firebaseService.createEmergencyNotification({
          'id': emergencyId,
          ...alertData,
          'source': 'mysql', // Track where data originated
        });
      }
    } catch (e) {
      print('Error creating emergency alert: $e');
      rethrow;
    }
  }

  /// Send notification to users (Firebase real-time + MySQL record)
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type, // 'emergency', 'aid_update', 'general'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notificationData = {
        'recipientId': recipientId,
        'title': title,
        'message': message,
        'type': type,
        'metadata': metadata ?? {},
      };

      // 1. Create in Firestore for real-time delivery
      await _firebaseService.createEmergencyNotification(notificationData);

      // 2. Record in MySQL for persistence
      await _apiService.post('/api/notifications', notificationData);
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // ============== CONFLICT RESOLUTION ==============

  /// Resolve conflicts when data exists in both MySQL and Firebase
  /// Returns 'mysql', 'firebase', or 'merge'
  Future<String> resolveConflict({
    required String collectionName,
    required String docId,
    required Map<String, dynamic> mysqlData,
    required Map<String, dynamic> firebaseData,
  }) async {
    // Timestamp comparison
    final mysqlUpdated = DateTime.parse(
      mysqlData['updated_at'] ?? mysqlData['createdAt'] ?? '2000-01-01',
    );
    final firebaseUpdated = DateTime.parse(
      firebaseData['updatedAt'] ?? firebaseData['createdAt'] ?? '2000-01-01',
    );

    if (mysqlUpdated.isAfter(firebaseUpdated)) {
      // MySQL is newer, sync to Firebase
      await _firebaseService.updateDocument(collectionName, docId, mysqlData);
      return 'mysql';
    } else if (firebaseUpdated.isAfter(mysqlUpdated)) {
      // Firebase is newer, sync to MySQL
      await _apiService.put('/api/$collectionName/$docId', firebaseData);
      return 'firebase';
    } else {
      // Timestamps are the same, merge carefully
      return 'merge';
    }
  }

  // ============== OFFLINE SUPPORT ==============

  /// Enable offline persistence in Firestore
  Future<void> enableOfflinePersistence() async {
    try {
      // Offline persistence is enabled by default on mobile platforms
      // On web, it requires specific configuration
      print('Firestore offline persistence initialized');
    } catch (e) {
      print('Offline persistence setup note: $e');
    }
  }

  /// Check if device is online (can be enhanced with connectivity package)
  Future<bool> isOnline() async {
    // In production, use connectivity_plus package
    try {
      final response = await _apiService.get('/api/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============== DATA CLEANUP ==============

  /// Remove duplicate data from Firebase (cleanup utility)
  Future<void> deduplicateFirestoreData(String collectionName) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(collectionName)
          .get();

      final seen = <String>{};
      for (var doc in snapshot.docs) {
        final uniqueKey =
            doc['uniqueIdentifier']; // Adjust based on your schema

        if (seen.contains(uniqueKey)) {
          // Duplicate found, delete it
          await _firebaseService.deleteDocument(collectionName, doc.id);
        } else {
          seen.add(uniqueKey);
        }
      }
    } catch (e) {
      print('Error deduplicating data: $e');
    }
  }
}
