import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class TelegramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get verification code for linking Telegram
  /// Returns a 6-digit code that user must send to the bot
  Future<String> getVerificationCode() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    // Generate a random 6-digit code
    final code = (Random().nextInt(900000) + 100000).toString();

    print('🔐 Generating Telegram verification code: $code');

    // Store in Firestore (expires in 15 minutes)
    await _firestore.collection('users').doc(userId).update({
      'telegramVerificationCode': code,
      'telegramVerificationExpiry': DateTime.now().add(Duration(minutes: 15)),
      'telegramVerificationAttempts': 0,
    });

    print('✅ Verification code stored in Firestore');
    return code;
  }

  /// Link Telegram account after user sends code to bot
  /// chatId: Telegram chat ID (can be individual or group)
  ///         Individual: positive number (e.g., 760723492)
  ///         Group: negative number (e.g., -1001234567890)
  /// verificationCode: Code that user sent to bot
  /// chatType: 'individual' or 'group' (defaults to 'individual')
  Future<void> linkTelegramAccount({
    required String chatId,
    required String verificationCode,
    String chatType = 'individual',
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    print('🔗 Attempting to link Telegram ($chatType) for user: $userId');

    // Get user document
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    final data = userDoc.data() ?? {};
    final storedCode = data['telegramVerificationCode'] as String?;
    final expiry = data['telegramVerificationExpiry'] as Timestamp?;

    // Validate code
    if (storedCode == null) {
      throw Exception('No verification code found. Request a new one.');
    }

    if (storedCode != verificationCode) {
      print('❌ Code mismatch. Stored: $storedCode, Provided: $verificationCode');
      throw Exception('Invalid verification code');
    }

    // Check expiry
    if (expiry != null && DateTime.now().isAfter(expiry.toDate())) {
      throw Exception('Verification code expired. Request a new one.');
    }

    // Link the account
    print('💾 Linking Telegram ($chatType) account: $chatId');
    await _firestore.collection('users').doc(userId).update({
      'telegramChatId': chatId,
      'telegramChatType': chatType, // 'individual' or 'group'
      'telegramLinked': true,
      'telegramNotificationsEnabled': true,
      'telegramLinkedAt': FieldValue.serverTimestamp(),
      'telegramVerificationCode': FieldValue.delete(),
      'telegramVerificationExpiry': FieldValue.delete(),
      'telegramVerificationAttempts': FieldValue.delete(),
    });

    print('✅ Telegram account linked successfully');
  }

  /// Unlink Telegram from user account
  Future<void> unlinkTelegram() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    print('🔓 Unlinking Telegram for user: $userId');

    await _firestore.collection('users').doc(userId).update({
      'telegramChatId': FieldValue.delete(),
      'telegramLinked': false,
      'telegramNotificationsEnabled': false,
    });

    print('✅ Telegram account unlinked');
  }

  /// Check if Telegram is linked
  Future<bool> isTelegramLinked() async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['telegramLinked'] ?? false;
    } catch (e) {
      print('❌ Error checking Telegram link status: $e');
      return false;
    }
  }

  /// Get Telegram link status
  Future<Map<String, dynamic>> getTelegramStatus() async {
    final userId = _userId;
    if (userId == null) {
      return {
        'linked': false,
        'enabled': false,
        'username': null,
      };
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() ?? {};

      return {
        'linked': data['telegramLinked'] ?? false,
        'enabled': data['telegramNotificationsEnabled'] ?? false,
        'username': data['telegramUsername'],
        'linkedAt': data['telegramLinkedAt'],
      };
    } catch (e) {
      print('❌ Error getting Telegram status: $e');
      return {
        'linked': false,
        'enabled': false,
        'username': null,
      };
    }
  }

  /// Toggle Telegram notifications on/off
  Future<void> toggleTelegramNotifications(bool enabled) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    print('🔔 ${enabled ? "Enabling" : "Disabling"} Telegram notifications');

    await _firestore.collection('users').doc(userId).update({
      'telegramNotificationsEnabled': enabled,
    });

    print('✅ Telegram notifications ${enabled ? "enabled" : "disabled"}');
  }

  /// Get Telegram chat ID for current user
  Future<String?> getTelegramChatId() async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['telegramChatId'] as String?;
    } catch (e) {
      print('❌ Error getting Telegram chat ID: $e');
      return null;
    }
  }

  /// Stream to listen for Telegram link status changes
  Stream<bool> telegramLinkStatusStream() {
    final userId = _userId;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['telegramLinked'] ?? false);
  }
}
