import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Service - Handles all Firebase operations for the hybrid approach
/// This service works alongside MySQL/Laravel backend
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // ============== AUTHENTICATION ==============

  /// Sign up with email and password
  /// Note: Also sync with Laravel backend
  Future<UserCredential> signUp(String email, String password, String displayName) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    await userCredential.user?.updateDisplayName(displayName);
    
    // Create corresponding Firestore document
    await _createUserDocument(userCredential.user!.uid, email, displayName);
    
    return userCredential;
  }

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ============== USER DOCUMENT ==============

  /// Create user document in Firestore
  /// This complements your MySQL users table
  Future<void> _createUserDocument(String uid, String email, String displayName) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isSyncedWithMySQL': false, // Track sync status with backend
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  /// Get user document
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Update user document
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ============== REAL-TIME FEATURES ==============

  /// Listen to real-time updates for a specific collection
  Stream<QuerySnapshot> listenToCollection(String collectionName, {
    String? whereField,
    dynamic whereValue,
  }) {
    Query query = _firestore.collection(collectionName);
    
    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    
    return query.snapshots();
  }

  /// Listen to specific document changes
  Stream<DocumentSnapshot> listenToDocument(String collectionName, String documentId) {
    return _firestore.collection(collectionName).doc(documentId).snapshots();
  }

  // ============== FIRESTORE OPERATIONS ==============

  /// Add document to collection
  Future<DocumentReference> addDocument(String collectionName, Map<String, dynamic> data) async {
    return await _firestore.collection(collectionName).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Set document with ID
  Future<void> setDocument(String collectionName, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(documentId).set(data);
  }

  /// Update document
  Future<void> updateDocument(String collectionName, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(documentId).update(data);
  }

  /// Delete document
  Future<void> deleteDocument(String collectionName, String documentId) async {
    await _firestore.collection(collectionName).doc(documentId).delete();
  }

  /// Get single document
  Future<DocumentSnapshot> getDocument(String collectionName, String documentId) async {
    return await _firestore.collection(collectionName).doc(documentId).get();
  }

  /// Query collection
  Future<QuerySnapshot> queryCollection(
    String collectionName, {
    String? whereField,
    dynamic whereValue,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _firestore.collection(collectionName);
    
    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return await query.get();
  }

  // ============== STORAGE OPERATIONS ==============

  /// Upload file to Firebase Storage
  Future<String> uploadFile(String path, dynamic file) async {
    try {
      TaskSnapshot snapshot;
      
      if (file is String) {
        // File path
        snapshot = await _storage.ref(path).putFile(File(file));
      } else {
        // Assuming it's already a File or bytes
        snapshot = await _storage.ref(path).putData(file);
      }
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }

  /// Get download URL
  Future<String> getDownloadUrl(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }

  // ============== HYBRID APPROACH HELPERS ==============

  /// Sync user data from Firebase to MySQL backend
  /// Call this after Firebase operations if you want to mirror data
  Future<void> syncUserToBackend(String uid, Map<String, dynamic> data) async {
    // This will be called from your API service
    // Example: await apiService.post('/api/users/sync', {...data});
    print('Ready to sync user $uid to backend');
  }

  /// Sync aid program data from MySQL to Firestore for real-time features
  Future<void> syncAidProgramToFirebase(String aidId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('aid_programs').doc(aidId).set({
        ...data,
        'lastSyncedFromMySQL': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing aid program to Firebase: $e');
    }
  }

  /// Get aid programs from Firestore (real-time)
  Stream<QuerySnapshot> getAidProgramsRealTime({String? status}) {
    Query query = _firestore.collection('aid_programs');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  /// Create emergency notification in Firestore
  Future<void> createEmergencyNotification(Map<String, dynamic> data) async {
    await _firestore.collection('emergency_notifications').add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Listen to emergency notifications for specific user
  Stream<QuerySnapshot> listenToEmergencyNotifications(String userId) {
    return _firestore
        .collection('emergency_notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('emergency_notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}

// Required import
import 'dart:io';
