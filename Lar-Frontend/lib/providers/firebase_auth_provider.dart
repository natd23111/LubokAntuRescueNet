import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/hybrid_data_service.dart';

/// Firebase Auth Provider
/// Integrates Firebase authentication with your existing auth system
class FirebaseAuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final HybridDataService _hybridService = HybridDataService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  FirebaseAuthProvider() {
    // Listen to auth state changes
    _firebaseService.auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  /// Sign up with email and password
  /// Also syncs with MySQL backend
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create Firebase user
      final userCredential = await _firebaseService.signUp(
        email,
        password,
        displayName,
      );

      // Sync with MySQL backend
      await _hybridService.syncFirebaseUserToMySQL(userCredential.user!.uid, {
        'email': email,
        'displayName': displayName,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.signIn(email, password);

      // Update last login in Firebase
      if (_currentUser != null) {
        await _firebaseService.updateUserDocument(_currentUser!.uid, {
          'lastLogin': DateTime.now().toIso8601String(),
          'isOnline': true,
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update presence
      if (_currentUser != null) {
        await _firebaseService.updateUserDocument(_currentUser!.uid, {
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }

      await _firebaseService.signOut();

      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      if (_currentUser != null) {
        if (displayName != null) {
          await _currentUser!.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await _currentUser!.updatePhotoURL(photoUrl);
        }

        // Update Firebase document
        await _firebaseService.updateUserDocument(_currentUser!.uid, {
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoURL': photoUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        _currentUser = FirebaseAuth.instance.currentUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Link with MySQL user
  /// Call this if you have existing MySQL users
  Future<bool> linkWithMySQLUser({
    required String mysqlUserId,
    required String email,
  }) async {
    try {
      if (_currentUser != null) {
        await _firebaseService.updateUserDocument(_currentUser!.uid, {
          'mysqlUserId': mysqlUserId,
          'linkedAt': DateTime.now().toIso8601String(),
        });

        await _hybridService.syncFirebaseUserToMySQL(_currentUser!.uid, {
          'email': email,
          'displayName': _currentUser!.displayName,
          'mysqlUserId': mysqlUserId,
        });

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
