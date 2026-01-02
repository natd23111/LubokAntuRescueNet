import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initializePushNotifications() async {
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

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
