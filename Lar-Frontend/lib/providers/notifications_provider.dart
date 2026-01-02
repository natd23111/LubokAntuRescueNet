import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

class NotificationsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<AppNotification> get recentNotifications => 
    _notifications.take(5).toList();

  NotificationsProvider() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    if (_auth.currentUser != null) {
      _listenToNotifications();
    }
  }

  void _listenToNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          data: _notifications[index].data,
          icon: _notifications[index].icon,
          actionUrl: _notifications[index].actionUrl,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      for (final notification in _notifications) {
        batch.delete(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(notification.id),
        );
      }
      await batch.commit();

      _notifications.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Method to send a notification to user
  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? icon,
    String? actionUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        data: data,
        icon: icon,
        actionUrl: actionUrl,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      // Local update
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      print('Error sending notification: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
}
