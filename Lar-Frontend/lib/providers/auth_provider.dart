import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/storage_util.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? userName;
  String? userIc;
  String? userEmail;
  String? userPhone;
  String? userAddress;
  String? userRole;
  String? memberSince;
  String? userId;
  String? accountStatus;
  User? currentUser;
  String? errorMessage;

  // Listen to Firebase auth changes
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      currentUser = user;
      if (user != null) {
        userId = user.uid;
        userEmail = user.email;
        _loadUserProfile();
      }
      notifyListeners();
    });
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      if (currentUser == null) return;
      
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      
      if (doc.exists) {
        final data = doc.data() ?? {};
        userName = data['full_name'] ?? currentUser!.email ?? 'User';
        userIc = data['ic_no'] ?? '';
        userPhone = data['phone_no'] ?? '';
        userAddress = data['address'] ?? '';
        userRole = data['role'] ?? 'citizen';
        memberSince = data['created_at'] ?? DateTime.now().toString();
        accountStatus = data['status'] ?? 'active';
      } else {
        // Profile doesn't exist yet - this is OK for new users
        userName = currentUser!.email ?? 'User';
        userRole = 'citizen';
      }
      notifyListeners();
    } catch (e) {
      // Silently fail - don't crash the app if Firestore is unreachable
      // User can still use the app with basic Firebase auth
      print('Note: Could not load full profile from Firestore: $e');
      // Set minimal user data from Firebase auth itself
      userName = currentUser?.email ?? 'User';
      userRole = 'citizen';
      notifyListeners();
    }
  }

  // Login with Firebase
  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _loadUserProfile();
        await StorageUtil.saveToken(userCredential.user!.uid);
        isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      errorMessage = _getErrorMessage(e.code);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Login failed: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with Firebase
  Future<bool> register(Map<String, dynamic> data) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(data['full_name'] ?? 'User');

        // Save user profile to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'full_name': data['full_name'] ?? 'User',
          'email': data['email'],
          'ic_no': data['ic_no'] ?? '',
          'phone_no': data['phone_no'] ?? '',
          'address': data['address'] ?? '',
          'role': data['role'] ?? 'citizen',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      errorMessage = _getErrorMessage(e.code);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Registration failed: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch account info from Firestore
  Future<void> fetchAccountInfo() async {
    try {
      if (currentUser == null) return;

      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        memberSince = data['created_at'];
        userId = currentUser!.uid;
        accountStatus = data['status'];
        notifyListeners();
      }
    } catch (e) {
      // Don't crash if offline - just use defaults
      print('Note: Could not fetch account info: $e');
      // Use defaults instead
      userId = currentUser?.uid;
      accountStatus = 'active';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await StorageUtil.clearToken();
      
      userName = null;
      userIc = null;
      userEmail = null;
      userPhone = null;
      userAddress = null;
      userRole = null;
      memberSince = null;
      userId = null;
      accountStatus = null;
      currentUser = null;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Helper: Convert Firebase error codes to user-friendly messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'User not found. Please check your email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'Email already in use. Please login or use another email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication error: $code';
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
}
