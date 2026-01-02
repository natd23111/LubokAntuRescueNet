import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation_service.dart';
 

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Local notification plugin for displaying notifications
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializePushNotifications() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Push notifications authorized');
      
      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground notification: ${message.notification?.title}');
        _handleNotification(message);
      });

      // Handle messages when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification opened: ${message.notification?.title}');
        _handleNotification(message);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Push notifications provisional');
    } else {
      print('❌ Push notifications denied');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  /// Initialize local notifications for displaying popups
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Handle when user taps a notification
  static Future<void> _handleNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    print('📳 Notification tapped!');
    print('   Payload: $payload');
    print('   ID: ${response.id}');
    print('   Action ID: ${response.actionId}');
    
    if (payload != null && payload.isNotEmpty) {
      // Try to parse JSON payload (used for FCM/local map payloads)
      try {
        final dynamic parsed = jsonDecode(payload);
        if (parsed is Map<String, dynamic>) {
          final map = parsed;
          // Aid request
          final reportId = map['reportId'] ?? map['requestId'];
          final reportType = map['reportType'] ?? map['type'];
          final programId = map['programId'];

          if (reportId != null && reportType != null) {
            if (reportType.toString().toLowerCase() == 'aid') {
              print('➡️ Navigating (global) to aid request: $reportId');
              navigationKey.currentState?.pushNamed('/view-aid-requests', arguments: {'requestId': reportId});
              return;
            } else if (reportType.toString().toLowerCase() == 'emergency') {
              print('➡️ Navigating (global) to emergency report: $reportId');
              navigationKey.currentState?.pushNamed('/view-reports', arguments: {'reportType': 'emergency', 'reportId': reportId});
              return;
            } else {
              print('➡️ Navigating (global) to public report: $reportId');
              navigationKey.currentState?.pushNamed('/view-public-reports', arguments: {'reportType': reportType, 'reportId': reportId});
              return;
            }
          }

          if (programId != null) {
            print('➡️ Navigating (global) to program details: $programId');
            navigationKey.currentState?.pushNamed('/program-details', arguments: {'programId': programId});
            return;
          }
        }
      } catch (e) {
        print('⚠️ Payload not JSON or parse failed: $e');

        // If payload is a simple notification id, attempt to resolve it from Firestore
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null && payload != null && payload.isNotEmpty) {
            print('🔎 Attempting to resolve notification id from Firestore: $payload');
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('notifications')
                .doc(payload)
                .get();
            if (doc.exists && doc.data() != null) {
              final Map<String, dynamic> map = Map<String, dynamic>.from(doc.data()!);
              final type = map['type'] as String? ?? '';
              final data = map['data'] as Map<String, dynamic>? ?? {};
              final reportId = data['reportId'] ?? data['requestId'];
              final reportType = data['reportType'] ?? data['report_type'] ?? data['type'];
              final programId = data['programId'] ?? data['program_id'];

              if (reportId != null && reportType != null) {
                if (reportType.toString().toLowerCase() == 'aid') {
                  print('➡️ Navigating (resolved) to aid request: $reportId');
                  navigationKey.currentState?.pushNamed('/view-aid-requests', arguments: {'requestId': reportId});
                  return;
                } else if (reportType.toString().toLowerCase() == 'emergency') {
                  print('➡️ Navigating (resolved) to emergency report: $reportId');
                  navigationKey.currentState?.pushNamed('/view-reports', arguments: {'reportType': 'emergency', 'reportId': reportId});
                  return;
                } else {
                  print('➡️ Navigating (resolved) to public report: $reportId');
                  navigationKey.currentState?.pushNamed('/view-public-reports', arguments: {'reportType': reportType, 'reportId': reportId});
                  return;
                }
              }

              if (programId != null) {
                print('➡️ Navigating (resolved) to program details: $programId');
                navigationKey.currentState?.pushNamed('/program-details', arguments: {'programId': programId});
                return;
              }
            }
          }
        } catch (resolveErr) {
          print('❌ Error resolving notification id from Firestore: $resolveErr');
        }

        // Fallback: pass to any registered callback (e.g., provider instance)
        print('✅ Calling onNotificationTapped callback with payload: $payload');
        PushNotificationService.onNotificationTapped?.call(payload);
      }
    } else {
      print('⚠️ Payload is empty, cannot trigger navigation');
    }
  }

  /// Callback to handle notification taps
  static Function(String)? onNotificationTapped;

  /// Create notification channels for different notification types
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel reportChannel =
        AndroidNotificationChannel(
      'report_status',
      'Report Status Updates',
      description: 'Notifications about your report status changes',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      'alerts',
      'Emergency Alerts',
      description: 'Emergency and critical alerts',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const AndroidNotificationChannel aidProgramChannel =
        AndroidNotificationChannel(
      'aid_program',
      'New Aid Programs',
      description: 'Notifications about new aid programs',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reportChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(aidProgramChannel);

    print('✅ Notification channels created');
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Background notification: ${message.notification?.title}');
    _handleNotification(message);
  }

  static void _handleNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      print('''
      Title: ${notification.title}
      Body: ${notification.body}
      Data: $data
      ''');
      
      // Display local notification
      _displayLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: data,
      );
    }
  }

  /// Display a local notification
  static Future<void> _displayLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'report_status',
        'Report Status Updates',
        channelDescription: 'Notifications about your report status changes',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );


      // Encode payload as JSON string so tap handlers can parse it reliably
      final String payloadJson = jsonEncode(payload);
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: payloadJson,
      );

      print('✅ Local notification displayed: $title');
    } catch (e) {
      print('❌ Error displaying notification: $e');
    }
  }

  /// Public wrapper to show a local notification with a simple string payload.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: const AndroidNotificationDetails(
          'report_status',
          'Report Status Updates',
          channelDescription: 'Notifications about your report status changes',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: payload ?? '',
      );
      print('✅ Local notification displayed via wrapper: $title');
    } catch (e) {
      print('❌ Error in showLocalNotification wrapper: $e');
    }
  }

 

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
