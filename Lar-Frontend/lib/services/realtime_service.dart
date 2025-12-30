import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Real-Time Service - Handles real-time updates from Firebase
/// Perfect for live dashboards, emergency alerts, and notifications
class RealtimeService {
  final FirebaseService _firebaseService = FirebaseService();

  // ============== LIVE AID PROGRAMS ==============

  /// Stream live aid program updates
  Stream<List<Map<String, dynamic>>> streamAidPrograms({
    String? status,
    String? category,
  }) {
    Query query = _firebaseService.firestore.collection('aid_programs');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Stream single aid program details in real-time
  Stream<Map<String, dynamic>?> streamAidProgramDetails(String programId) {
    return _firebaseService.firestore
        .collection('aid_programs')
        .doc(programId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return {
          'id': snapshot.id,
          ...snapshot.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  // ============== LIVE EMERGENCY ALERTS ==============

  /// Stream emergency alerts in real-time
  /// Use this for admin dashboard to see live emergencies
  Stream<List<Map<String, dynamic>>> streamEmergencyAlerts({
    String? status,
    String? severity,
    int limit = 100,
  }) {
    Query query = _firebaseService.firestore
        .collection('emergency_notifications')
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (severity != null) {
      query = query.where('severity', isEqualTo: severity);
    }

    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  // ============== LIVE USER NOTIFICATIONS ==============

  /// Stream notifications for current user
  Stream<List<Map<String, dynamic>>> streamUserNotifications(String userId) {
    return _firebaseService.firestore
        .collection('emergency_notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Count unread notifications for user
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _firebaseService.firestore
        .collection('emergency_notifications')
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============== LIVE BENEFICIARY UPDATES ==============

  /// Stream beneficiary list updates
  Stream<List<Map<String, dynamic>>> streamBeneficiaries({
    String? aidProgramId,
  }) {
    Query query = _firebaseService.firestore.collection('beneficiaries');

    if (aidProgramId != null) {
      query = query.where('aidProgramId', isEqualTo: aidProgramId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Stream beneficiary count for specific aid program
  Stream<int> streamBeneficiaryCount(String aidProgramId) {
    return _firebaseService.firestore
        .collection('beneficiaries')
        .where('aidProgramId', isEqualTo: aidProgramId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============== LIVE ADMIN DASHBOARD ==============

  /// Stream statistics for admin dashboard
  Stream<Map<String, dynamic>> streamAdminStats() {
    // Get multiple streams and combine them
    final programsStream = _firebaseService.firestore
        .collection('aid_programs')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    final emergenciesStream = _firebaseService.firestore
        .collection('emergency_notifications')
        .where('timestamp',
            isGreaterThan: DateTime.now()
                .subtract(Duration(hours: 24))
                .toIso8601String())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    return emergenciesStream.asyncExpand((emergencyCount) {
      return programsStream.map((programs) => {
            'activePrograms': programs,
            'emergenciesLast24h': emergencyCount,
          });
    });
  }

  // ============== LIVE DOCUMENT PRESENCE ==============

  /// Stream user presence (online/offline)
  Stream<bool> streamUserPresence(String userId) {
    return _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final isOnline = snapshot.data()?['isOnline'] ?? false;
      return isOnline;
    });
  }

  /// Update user presence status
  Future<void> updatePresence(String userId, bool isOnline) async {
    await _firebaseService.updateUserDocument(userId, {
      'isOnline': isOnline,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  // ============== LIVE COMMENTS/UPDATES ==============

  /// Stream comments on a document (e.g., aid program updates)
  Stream<List<Map<String, dynamic>>> streamComments(
    String collectionName,
    String documentId,
  ) {
    return _firebaseService.firestore
        .collection(collectionName)
        .doc(documentId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Add comment
  Future<void> addComment(
    String collectionName,
    String documentId,
    String userId,
    String text,
  ) async {
    await _firebaseService.firestore
        .collection(collectionName)
        .doc(documentId)
        .collection('comments')
        .add({
      'userId': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ============== BATCH UPDATES ==============

  /// Batch update multiple documents
  Future<void> batchUpdate(
    String collectionName,
    List<Map<String, dynamic>> updates,
  ) async {
    final batch = _firebaseService.firestore.batch();

    for (var update in updates) {
      final docId = update.remove('id');
      final docRef =
          _firebaseService.firestore.collection(collectionName).doc(docId);
      batch.update(docRef, update);
    }

    await batch.commit();
  }

  // ============== TRANSACTION SUPPORT ==============

  /// Execute transaction (atomic operation)
  Future<T> transaction<T>(
    Future<T> Function(Transaction) updateFunction,
  ) async {
    return await _firebaseService.firestore.runTransaction(updateFunction);
  }
}
