import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';

class NotificationsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _reportStatusCache = {}; // Track last known status
  Set<String> _displayedNotifications = {}; // Track which notifications were shown

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
      _listenToReportStatusChanges();
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
      List<AppNotification> newNotifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Check for new notifications and display them
      for (var notif in newNotifications) {
        if (!_displayedNotifications.contains(notif.id) && 
            notif.timestamp.isAfter(DateTime.now().subtract(Duration(seconds: 5)))) {
          // This is a new notification - display it
          _displayNotification(notif);
          _displayedNotifications.add(notif.id);
        }
      }
      
      _notifications = newNotifications;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  /// Display local notification
  void _displayNotification(AppNotification notification) {
    try {
      _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notification.type,
            'Rescue Net Notifications',
            channelDescription: 'Updates from Lubok Antu RescueNet',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.id,
      );
      print('🔔 Notification displayed: ${notification.title}');
    } catch (e) {
      print('Error displaying notification: $e');
    }
  }

  /// Listen to report status changes and create notifications
  void _listenToReportStatusChanges() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen to emergency reports
    _firestore
        .collection('emergency_reports')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final reportId = doc.id;
        final newStatus = doc['status'] ?? 'unresolved';
        final oldStatus = _reportStatusCache[reportId];

        // Status changed - create notification
        if (oldStatus != null && oldStatus != newStatus) {
          _createReportStatusNotification(
            reportId: reportId,
            reportType: 'emergency',
            newStatus: newStatus,
            oldStatus: oldStatus,
            userId: userId,
          );
        }

        // Update cache
        _reportStatusCache[reportId] = newStatus;
      }
    });

    // Listen to aid requests
    _firestore
        .collection('aid_requests')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final requestId = doc.id;
        final newStatus = doc['status'] ?? 'Submitted';
        final oldStatus = _reportStatusCache[requestId];

        // Status changed - create notification
        if (oldStatus != null && oldStatus != newStatus) {
          _createReportStatusNotification(
            reportId: requestId,
            reportType: 'aid',
            newStatus: newStatus,
            oldStatus: oldStatus,
            userId: userId,
          );
        }

        // Update cache
        _reportStatusCache[requestId] = newStatus;
      }
    });
  }

  /// Create a notification for report status change
  Future<void> _createReportStatusNotification({
    required String reportId,
    required String reportType,
    required String newStatus,
    required String oldStatus,
    required String userId,
  }) async {
    try {
      final statusMessages = {
        'pending': 'Your report is being reviewed',
        'in_progress': 'Your report is now being processed',
        'in-progress': 'Your report is now being processed',
        'completed': 'Your report has been resolved',
        'resolved': 'Your report has been resolved',
        'unresolved': 'Your report remains unresolved',
        'Submitted': 'Your aid request has been received',
        'In Process': 'Your aid request is being processed',
        'Completed': 'Your aid request has been completed',
        'Rejected': 'Your aid request has been rejected',
      };

      final title = reportType == 'emergency'
          ? '🚨 Emergency Report Update'
          : '🆘 Aid Request Update';

      final body = statusMessages[newStatus] ??
          'Status changed from $oldStatus to $newStatus';

      final notification = AppNotification(
        id: '$reportId-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        type: 'report_status',
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'reportId': reportId,
          'reportType': reportType,
          'newStatus': newStatus,
          'oldStatus': oldStatus,
        },
        icon: reportType == 'emergency' ? '🚨' : '🆘',
        actionUrl: reportType == 'emergency'
            ? '/reports/emergency/$reportId'
            : '/reports/aid/$reportId',
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      print('✅ Notification created for report status change: $reportId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
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
