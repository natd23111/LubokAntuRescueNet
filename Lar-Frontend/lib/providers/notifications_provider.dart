import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import 'weather_provider.dart';
import '../services/push_notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  // Static variable to track last tapped notification
  static String? lastTappedNotificationId;
  static Function(String)? globalOnNotificationTapped;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final WeatherProvider _weatherProvider = WeatherProvider();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  DateTime?
  _loginTime; // Track when user logged in to avoid showing old notifications
  final Map<String, String> _reportStatusCache = {}; // Track last known status
  final Set<String> _displayedNotifications =
      {}; // Track which notifications were shown
  final Set<String> _notifiedPrograms =
      {}; // Track programs we've already notified about
  final Map<String, String> _programStatusCache = {}; // Track program status changes
  final Map<String, bool> _weatherAlertCache =
      {}; // Track weather alerts to avoid duplicates
  final Set<String> _notifiedOtherReports =
      {}; // Track reports from other citizens we've notified about

  // User alert preferences
  bool _floodAlertsEnabled = true;
  bool _fireAlertsEnabled = true;
  bool _landslideAlertsEnabled = true;
  bool _weatherWarningsEnabled = true;

  // Callback for status bar notification taps
  Function(String)? onNotificationTapped;

  List<AppNotification> get notifications => _notifications;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> get recentNotifications =>
      _notifications.take(5).toList();

  NotificationsProvider() {
    _loadAlertPreferences();
    // Set up callback for status bar notification taps
    PushNotificationService.onNotificationTapped = (notificationId) {
      print('📲 Notification tap callback triggered for: $notificationId');
      lastTappedNotificationId = notificationId;
      onNotificationTapped?.call(notificationId);
      globalOnNotificationTapped?.call(notificationId);
    };
    // Listen to auth state changes and initialize when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('👤 User logged in, initializing notifications listener...');
        _initializeNotifications();
      } else {
        print('👤 User logged out, stopping notifications listener...');
        _clearListeners();
      }
    });
  }

  Future<void> _loadAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _floodAlertsEnabled = prefs.getBool('flood_alerts') ?? true;
    _fireAlertsEnabled = prefs.getBool('fire_alerts') ?? true;
    _landslideAlertsEnabled = prefs.getBool('landslide_alerts') ?? true;
    _weatherWarningsEnabled = prefs.getBool('weather_warnings') ?? true;
    notifyListeners();
  }

  void setAlertPreferences({
    required bool floodAlerts,
    required bool fireAlerts,
    required bool landslideAlerts,
    required bool weatherWarnings,
  }) {
    _floodAlertsEnabled = floodAlerts;
    _fireAlertsEnabled = fireAlerts;
    _landslideAlertsEnabled = landslideAlerts;
    _weatherWarningsEnabled = weatherWarnings;
    notifyListeners();
  }

  void _initializeNotifications() {
    if (_auth.currentUser != null) {
      _loginTime = DateTime.now(); // Record login time to filter notifications
      print('👤 Login time recorded: $_loginTime');
      _listenToNotifications();
      _listenToReportStatusChanges();
      _listenToNewReportsFromOthers();
      _listenToNewPrograms();
      _startWeatherMonitoring();
      print('✅ Notification listeners initialized');
    }
  }

  /// Get weather alert details from weather provider
  Map<String, dynamic>? getWeatherAlertDetails() {
    return _weatherProvider.getAlertDetails();
  }

  void _clearListeners() {
    print('🗑️ Clearing all notification caches and listeners');
    _notifications = [];
    _reportStatusCache.clear();
    _displayedNotifications.clear();
    _notifiedPrograms.clear();
    _programStatusCache.clear();
    _weatherAlertCache.clear();
    _notifiedOtherReports.clear();
    _loginTime = null;
    notifyListeners();
  }

  void _listenToNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    print('🔔 Starting notification listener for user: $userId');

    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(5) // Only load the 5 most recent notifications
        .snapshots()
        .listen(
          (snapshot) {
            List<AppNotification> newNotifications = snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
                .toList();

            print(
              '📋 Received ${newNotifications.length} notifications from Firestore',
            );

            // Check for new notifications and display them
            for (var notif in newNotifications) {
              // Only show notifications created AFTER user logged in
              // This prevents spam of old notifications on login
              final isNewNotification =
                  _loginTime != null && notif.timestamp.isAfter(_loginTime!);
              final isRecentNotification = notif.timestamp.isAfter(
                DateTime.now().subtract(Duration(seconds: 10)),
              );

              if (!_displayedNotifications.contains(notif.id) &&
                  (isNewNotification || isRecentNotification)) {
                print('✅ Displaying notification: ${notif.title}');
                // This is a new notification - display it
                _displayNotification(notif);
                _displayedNotifications.add(notif.id);
              } else {
                print(
                  '⏭️ Skipping notification: ${notif.title} (not new/recent)',
                );
              }
            }

            _notifications = newNotifications;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  /// Display local notification
  void _displayNotification(AppNotification notification) {
    try {
      print('🔔 Attempting to display notification: ${notification.title}');

      // If user just logged in, avoid showing historical notifications
      if (_loginTime != null) {
        // small buffer to account for clock skew
        final buffer = Duration(seconds: 2);
        if (notification.timestamp.isBefore(_loginTime!.subtract(buffer))) {
          print(
            '⏭️ Skipping display of old notification ${notification.id} created at ${notification.timestamp} before login ($_loginTime)',
          );
          return;
        }
      }

      // Use PushNotificationService wrapper to ensure local notifications
      // are initialized and displayed consistently across the app.
      // Build a JSON payload containing the notification id, type and any relevant data
      final payloadMap = {
        'notificationId': notification.id,
        'type': notification.type,
        'data': notification.data ?? {},
      };

      PushNotificationService.showLocalNotification(
            title: notification.title,
            body: notification.body,
            payload: jsonEncode(payloadMap),
          )
          .then((_) {
            print(
              '✅ Notification displayed successfully via PushNotificationService',
            );
          })
          .catchError((error) {
            print(
              '❌ Error displaying notification via PushNotificationService: $error',
            );
          });
    } catch (e) {
      print('❌ Exception in _displayNotification: $e');
      print('Stack: $e');
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

  /// Listen to new reports from other citizens and create notifications
  void _listenToNewReportsFromOthers() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    print('🔔 Starting listener for reports from other citizens');

    // Listen to ALL emergency reports (not just current user's)
    _firestore.collection('emergency_reports').snapshots().listen((snapshot) {
      print(
        '📋 Received emergency_reports snapshot with ${snapshot.docs.length} documents',
      );

      for (var doc in snapshot.docs) {
        try {
          final reportId = doc.id;
          final reportUserId = doc['user_id'];
          final data = doc.data();

          print(
            '🔍 Processing report $reportId from user $reportUserId (currentUser: $userId)',
          );

          // Skip if it's the current user's report
          if (reportUserId == userId) {
            print('⏭️ Skipping own report: $reportId');
            continue;
          }

          // Check if we've already notified about this report
          if (_notifiedOtherReports.contains(reportId)) {
            print('⏭️ Already notified about report: $reportId');
            continue;
          }

          // Only notify about reports submitted after login
          final docTimestamp = _getDocumentTimestamp(data);
          if (_loginTime != null) {
            if (docTimestamp == null) {
              print(
                '⚠️ Report $reportId has no timestamp; skipping to avoid old notifications',
              );
              continue;
            }
            if (!docTimestamp.isAfter(_loginTime!)) {
              print(
                '⏭️ Report $reportId created at $docTimestamp before login ($_loginTime); skipping',
              );
              continue;
            }
          }

          // Check alert type preferences
          final reportType = data['type'] ?? 'flood';
          bool shouldNotify = _shouldNotifyForReportType(reportType);

          print(
            '📢 Should notify for $reportId (type: $reportType, shouldNotify: $shouldNotify)',
          );

          if (shouldNotify) {
            print('✅ Creating notification for report: $reportId');
            _createNewReportNotification(
              reportId: reportId,
              reportType: 'emergency',
              userId: userId,
              data: data,
            );
            _notifiedOtherReports.add(reportId);
          }
        } catch (e) {
          print('⚠️ Error processing report: $e');
        }
      }
    });
  }

  /// Determine if should notify based on report type and user preferences
  bool _shouldNotifyForReportType(String reportType) {
    final type = reportType.toLowerCase();

    if (type.contains('flood')) {
      return _floodAlertsEnabled;
    } else if (type.contains('fire')) {
      return _fireAlertsEnabled;
    } else if (type.contains('landslide')) {
      return _landslideAlertsEnabled;
    }

    return true; // Default: notify for unknown types
  }

  /// Extract a DateTime from common timestamp fields in a document
  DateTime? _getDocumentTimestamp(Map<String, dynamic> data) {
    final dynamic t =
        data['timestamp'] ?? data['created_at'] ?? data['createdAt'];
    if (t == null) return null;
    try {
      if (t is Timestamp) return t.toDate();
      if (t is int) return DateTime.fromMillisecondsSinceEpoch(t);
      if (t is String) return DateTime.parse(t);
    } catch (e) {
      print('⚠️ Could not parse timestamp field: $e');
    }
    return null;
  }

  /// Create notification for new report from another citizen
  Future<void> _createNewReportNotification({
    required String reportId,
    required String reportType,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final reportData = data['type'] ?? reportType;
      final location = data['location'] ?? 'Near you';
      final description = data['description'] ?? '';

      // Determine title based on type
      String title = '📍 New Report';
      if (reportData.toLowerCase().contains('flood')) {
        title = '🌧️ Flood Report';
      } else if (reportData.toLowerCase().contains('fire')) {
        title = '🔥 Fire Report';
      } else if (reportData.toLowerCase().contains('landslide')) {
        title = '⛰️ Landslide Report';
      }

      final notification = AppNotification(
        id: '$reportId-public-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: 'New $reportData reported $location',
        type: 'public_report',
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'reportId': reportId,
          'reportType': reportType,
          'location': location,
          'description': description,
          'detailedInfo':
              '$reportData reported\nLocation: $location\n\n$description',
        },
        icon: reportData.toLowerCase().contains('flood')
            ? '🌧️'
            : reportData.toLowerCase().contains('fire')
            ? '🔥'
            : '⛰️',
        actionUrl: '/view-public-reports',
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      // Display local notification
      _displayNotification(notification);

      print('✅ New report notification created: $reportId');
    } catch (e) {
      print('❌ Error creating new report notification: $e');
    }
  }

  /// Listen to new aid programs and notify users
  void _listenToNewPrograms() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ No user logged in, cannot listen to programs');
      return;
    }

    print('👂 Starting to listen for new programs for user: $userId');

    _firestore
        .collection('aid_programs')
        .snapshots()
        .listen(
          (snapshot) {
            print(
              '📦 Programs snapshot received with ${snapshot.docs.length} programs',
            );

            for (var doc in snapshot.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final programId = doc.id;
                final programName =
                    data['name'] ?? data['title'] ?? 'New Aid Program';
                final description = data['description'] ?? '';
                final status = data['status'] ?? 'draft';

                // Handle created_at as either Timestamp or String
                DateTime? createdAt;
                final createdAtField = data['created_at'];
                if (createdAtField is Timestamp) {
                  createdAt = createdAtField.toDate();
                } else if (createdAtField is String) {
                  try {
                    createdAt = DateTime.parse(createdAtField);
                  } catch (e) {
                    print(
                      '⚠️ Could not parse created_at string: $createdAtField',
                    );
                  }
                }

                final oldStatus = _programStatusCache[programId];
                print(
                  '📋 Program: $programName, Status: $status (was: $oldStatus), ID: $programId',
                );

                // Check if status changed TO active
                if (status.toLowerCase() == 'active' &&
                    (oldStatus == null ||
                        oldStatus.toLowerCase() != 'active')) {
                  print(
                    '✅ Program activated: $programName (was $oldStatus, now $status)',
                  );
                  _notifiedPrograms.add(programId);

                  // Notify about program activation regardless of login time (programs are rare)
                  _createNewProgramNotification(
                    programId: programId,
                    programName: programName,
                    description: description,
                    userId: userId,
                  );
                }

                // Update cache
                _programStatusCache[programId] = status;
              } catch (e) {
                print('⚠️ Error processing program ${doc.id}: $e');
              }
            }
          },
          onError: (error) {
            print('❌ Error listening to programs: $error');
          },
        );
  }

  /// Create a notification for new aid program
  Future<void> _createNewProgramNotification({
    required String programId,
    required String programName,
    required String description,
    required String userId,
  }) async {
    try {
      print('🔔 Creating notification for program: $programName');

      final notificationId =
          'PROG_${programId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create a more detailed body with description preview
      final descriptionPreview = description.length > 100
          ? '${description.substring(0, 100)}...'
          : description;

      final notification = AppNotification(
        id: notificationId,
        title: '🤝 New Aid Program Available',
        body: programName,
        type: 'aid_program',
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'programId': programId,
          'programName': programName,
          'description': description,
          'detailedInfo': '$programName\n\n$descriptionPreview',
        },
        actionUrl: '/aid-programs/$programId',
      );

      // Save to user's notifications subcollection
      print('💾 Saving notification to Firestore...');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toFirestore());
      print('✅ Notification saved to Firestore');

      // Display local notification
      print('📲 Displaying local notification...');
      _displayNotification(notification);
      print('✅ Local notification displayed');

      print('📢 New program notification created: $programName');
    } catch (e) {
      print('❌ Error creating new program notification: $e');
      print('Stack trace: $e');
    }
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
      // Determine if this report type should be notified based on user preferences
      bool shouldNotify = false;
      if (reportId.toLowerCase().contains('flood') ||
          reportType.toLowerCase().contains('flood')) {
        shouldNotify = _floodAlertsEnabled;
      } else if (reportId.toLowerCase().contains('fire') ||
          reportType.toLowerCase().contains('fire')) {
        shouldNotify = _fireAlertsEnabled;
      } else if (reportId.toLowerCase().contains('landslide') ||
          reportType.toLowerCase().contains('landslide')) {
        shouldNotify = _landslideAlertsEnabled;
      } else {
        // For regular emergency reports, always notify (not tied to specific alert type)
        shouldNotify = true;
      }

      // Skip notification if user has disabled this alert type
      if (!shouldNotify) {
        print(
          '⏭️ Skipping notification for $reportType report - user has disabled this alert type',
        );
        return;
      }

      final statusMessages = {
        'pending': 'being reviewed',
        'in_progress': 'now being processed',
        'in-progress': 'now being processed',
        'completed': 'has been resolved',
        'resolved': 'has been resolved',
        'unresolved': 'remains unresolved',
        'Submitted': 'has been received',
        'In Process': 'is being processed',
        'Completed': 'has been completed',
        'Rejected': 'has been rejected',
      };

      final title = reportType == 'emergency'
          ? '📋 Report Update'
          : '🤝 Aid Request Update';

      final statusMessage =
          statusMessages[newStatus] ?? 'Status changed to $newStatus';

      // Create more detailed body with report ID and status
      final body = 'Your $reportType report $reportId $statusMessage';

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
          'detailedInfo': 'Report ID: $reportId\nStatus: $newStatus',
        },
        icon: reportType == 'emergency' ? '📋' : '🤝',
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

      print('🗑️ Clearing all notifications for user: $userId');

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

      // Clear all local caches
      _notifications.clear();
      _displayedNotifications.clear();
      _reportStatusCache.clear();
      _notifiedPrograms.clear();
      _programStatusCache.clear();
      _weatherAlertCache.clear();
      _notifiedOtherReports.clear();

      print('✅ All notifications cleared successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error clearing notifications: $e');
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

      // Mark as displayed before saving to prevent duplicate display from listener
      _displayedNotifications.add(notification.id);

      // Display immediately
      _displayNotification(notification);

      // Save to Firestore (listener will pick it up but won't display due to _displayedNotifications check)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      // Don't manually insert - let the Firestore listener handle list updates
    } catch (e) {
      print('Error sending notification: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Monitor weather conditions and create alerts based on Open-Meteo API
  void _startWeatherMonitoring() {
    // Initial check
    _checkWeatherAlerts();

    // Refresh weather every 30 minutes
    Future.delayed(Duration(minutes: 30), () {
      _weatherProvider.refreshWeather();
      _checkWeatherAlerts();
      _startWeatherMonitoring(); // Schedule next check
    });
  }

  /// Check for weather alerts and create notifications if needed
  Future<void> _checkWeatherAlerts() async {
    try {
      // Check if there's a flood alert condition
      if (_weatherProvider.shouldShowFloodAlert()) {
        final alertDetails = _weatherProvider.getAlertDetails();
        if (alertDetails != null) {
          final alertType = alertDetails['type'] as String;

          // Check if user has enabled this alert type
          bool shouldNotify = false;
          if (alertType == 'flood' && _floodAlertsEnabled) {
            shouldNotify = true;
          } else if (alertType == 'thunderstorm' && _weatherWarningsEnabled) {
            shouldNotify = true;
          }

          // Only notify once per alert type per session if enabled
          if (shouldNotify && _weatherAlertCache[alertType] != true) {
            await _createWeatherAlert(alertDetails);
            _weatherAlertCache[alertType] = true;
          }
        }
      }
    } catch (e) {
      print('❌ Error checking weather alerts: $e');
    }
  }

  /// Create weather alert notification based on Open-Meteo data
  Future<void> _createWeatherAlert(Map<String, dynamic> alertDetails) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final notification = AppNotification(
        id: '${alertDetails['type']}-${DateTime.now().millisecondsSinceEpoch}',
        title: '${alertDetails['icon']} ${alertDetails['title']}',
        body: alertDetails['body'],
        type: 'weather_alert',
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'alertType': alertDetails['type'],
          'temperature': alertDetails['temperature'],
          'windSpeed': alertDetails['windSpeed'],
          'weatherCode': alertDetails['weatherCode'],
          'description': alertDetails['description'],
          'location': alertDetails['location'],
          'detailedInfo':
              '${alertDetails['description']}\n\nTemperature: ${alertDetails['temperature']}°C\nWind Speed: ${alertDetails['windSpeed']} km/h',
        },
        icon: alertDetails['icon'],
        actionUrl: '/alerts/weather',
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      // Display local notification
      _displayNotification(notification);

      print('✅ Weather alert created: ${alertDetails['title']}');
    } catch (e) {
      print('❌ Error creating weather alert: $e');
    }
  }
}
