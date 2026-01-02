import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'report_status', 'aid_update', 'alert', 'system'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? icon;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.icon,
    this.actionUrl,
  });

  /// Create notification from Firestore document
  factory AppNotification.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AppNotification(
      id: docId,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'] as Map<String, dynamic>?,
      icon: data['icon'] as String?,
      actionUrl: data['actionUrl'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
      'icon': icon,
      'actionUrl': actionUrl,
    };
  }

  /// Get formatted timestamp (e.g., "5m ago")
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  /// Get icon based on notification type
  String get typeIcon {
    switch (type) {
      case 'report_status':
        return '📋';
      case 'aid_update':
        return '🆘';
      case 'alert':
        return '⚠️';
      case 'system':
        return 'ℹ️';
      default:
        return '📢';
    }
  }

  /// Get color code based on notification type
  String get typeColor {
    switch (type) {
      case 'report_status':
        return '#2196F3'; // Blue
      case 'aid_update':
        return '#FF9800'; // Orange
      case 'alert':
        return '#F44336'; // Red
      case 'system':
        return '#4CAF50'; // Green
      default:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Create a copy with modified fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? icon,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      icon: icon ?? this.icon,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}
