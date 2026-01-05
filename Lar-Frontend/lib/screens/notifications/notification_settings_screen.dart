import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/notifications_provider.dart';
import '../../services/telegram_service.dart';
import 'telegram_linking_dialog.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _telegramEnabled = true;
  bool _floodAlerts = true;
  bool _fireAlerts = true;
  bool _landslideAlerts = true;
  bool _weatherWarnings = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _setupNotificationTapHandler();
  }

  /// Setup handler for when user taps notification in status bar
  void _setupNotificationTapHandler() {
    final notificationsProvider = Provider.of<NotificationsProvider>(
      context,
      listen: false,
    );
    notificationsProvider.onNotificationTapped =
        _handleStatusBarNotificationTap;
  }

  /// Handle tap from status bar notification
  void _handleStatusBarNotificationTap(String notificationId) {
    print('👆 Status bar notification tapped: $notificationId');
    // Find the notification in the provider and handle its tap
    final notificationsProvider = Provider.of<NotificationsProvider>(
      context,
      listen: false,
    );

    print(
      '📋 Current notifications count: ${notificationsProvider.notifications.length}',
    );
    for (var n in notificationsProvider.notifications) {
      print('  - ${n.id} | ${n.title}');
    }

    try {
      final notification = notificationsProvider.notifications.firstWhere(
        (n) => n.id == notificationId,
      );
      print('✅ Found notification: ${notification.title}');
      _handleNotificationTap(notification);
    } catch (e) {
      print('⚠️ Notification not found in list, attempting to parse payload');
      // Try to parse the payload if it's JSON coming from FCM/local message
      try {
        final Map<String, dynamic> payloadMap =
            jsonDecode(notificationId) as Map<String, dynamic>;
        print('📦 Parsed payload: $payloadMap');
        final String? reportId =
            payloadMap['reportId'] ?? payloadMap['requestId'];
        final String? reportType =
            payloadMap['reportType'] ?? payloadMap['type'];

        if (reportId != null && reportType != null) {
          print(
            '➡️ Navigating based on payload: reportId=$reportId, reportType=$reportType',
          );
          if (reportType == 'aid' || reportType.toLowerCase() == 'aid') {
            _navigateToAidRequest(reportId);
            return;
          } else if (reportType == 'emergency' ||
              reportType.toLowerCase() == 'emergency') {
            _navigateToEmergencyReport(reportId);
            return;
          } else {
            _navigateToPublicReport(reportId, reportType);
            return;
          }
        }

        // Fallback: navigate to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (parseErr) {
        print('❌ Could not parse payload: $parseErr');
        try {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } catch (navError) {
          print('❌ Navigation error: $navError');
        }
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final telegramService = TelegramService();

    // Load Telegram notification preference from Firestore
    final telegramStatus = await telegramService.getTelegramStatus();

    setState(() {
      _telegramEnabled = telegramStatus['enabled'] as bool? ?? true;
      _floodAlerts = prefs.getBool('flood_alerts') ?? true;
      _fireAlerts = prefs.getBool('fire_alerts') ?? true;
      _landslideAlerts = prefs.getBool('landslide_alerts') ?? true;
      _weatherWarnings = prefs.getBool('weather_warnings') ?? true;
    });

    print('✅ Loaded preferences from Firestore and SharedPreferences');
    print('   Telegram enabled: $_telegramEnabled');

    // Fetch notifications when screen loads
    if (mounted) {
      Provider.of<NotificationsProvider>(
        context,
        listen: false,
      ).fetchNotifications();
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flood_alerts', _floodAlerts);
    await prefs.setBool('fire_alerts', _fireAlerts);
    await prefs.setBool('landslide_alerts', _landslideAlerts);
    await prefs.setBool('weather_warnings', _weatherWarnings);

    // Update the provider with new preferences
    Provider.of<NotificationsProvider>(
      context,
      listen: false,
    ).setAlertPreferences(
      floodAlerts: _floodAlerts,
      fireAlerts: _fireAlerts,
      landslideAlerts: _landslideAlerts,
      weatherWarnings: _weatherWarnings,
    );
  }

  /// Save Telegram notification preference to Firestore
  Future<void> _saveTelegramPreference(bool enabled) async {
    try {
      final telegramService = TelegramService();
      await telegramService.toggleTelegramNotifications(enabled);
      print('✅ Saved Telegram preference to Firestore: $enabled');

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? '✅ Telegram notifications enabled'
                : '✅ Telegram notifications disabled',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error saving Telegram preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text(
          l10n.notificationSettings,
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Telegram Integration Section
              _buildTelegramSection(primaryGreen),

              SizedBox(height: 24),

              // Alert Types Section
              Text(
                'Alert Types',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 12),

              // Flood Alerts
              _buildAlertToggle(
                'Flood Warnings',
                'Heavy rainfall & flood alerts',
                _floodAlerts,
                (value) {
                  setState(() => _floodAlerts = value);
                  _savePreferences();
                },
              ),

              SizedBox(height: 8),

              // Fire Alerts
              _buildAlertToggle(
                'Fire Alerts',
                'Fire incidents in your area',
                _fireAlerts,
                (value) {
                  setState(() => _fireAlerts = value);
                  _savePreferences();
                },
              ),

              SizedBox(height: 8),

              // Landslide Alerts
              _buildAlertToggle(
                'Landslide Warnings',
                'Landslide risk notifications',
                _landslideAlerts,
                (value) {
                  setState(() => _landslideAlerts = value);
                  _savePreferences();
                },
              ),

              SizedBox(height: 8),

              // Weather Warnings
              _buildAlertToggle(
                'Weather Warnings',
                'Severe weather updates',
                _weatherWarnings,
                (value) {
                  setState(() => _weatherWarnings = value);
                  _savePreferences();
                },
              ),

              SizedBox(height: 24),

              // Test Weather Notification (Debug Section)
              _buildTestNotificationSection(primaryGreen),

              SizedBox(height: 24),

              // Recent Notifications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Consumer<NotificationsProvider>(
                    builder: (context, provider, _) {
                      if (provider.unreadCount > 0) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${provider.unreadCount} new',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Dynamic Notifications List
              Consumer<NotificationsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    );
                  }

                  if (provider.recentNotifications.isEmpty) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: provider.recentNotifications.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final notification = entry.value;
                      return Column(
                        children: [
                          _buildDynamicNotificationCard(
                            notification: notification,
                            onDismiss: () {
                              Provider.of<NotificationsProvider>(
                                context,
                                listen: false,
                              ).deleteNotification(notification.id);
                            },
                            onRead: () {
                              Provider.of<NotificationsProvider>(
                                context,
                                listen: false,
                              ).markAsRead(notification.id);
                            },
                          ),
                          if (index < provider.recentNotifications.length - 1)
                            SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: 24),

              // Clear All Button
              Consumer<NotificationsProvider>(
                builder: (context, provider, _) {
                  if (provider.notifications.isNotEmpty) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Clear All Notifications?'),
                              content: Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Provider.of<NotificationsProvider>(
                                      context,
                                      listen: false,
                                    ).clearAllNotifications();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Clear All',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Clear All Notifications',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),

              SizedBox(height: 16),

              // Back Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramSection(Color primaryGreen) {
    final telegramService = TelegramService();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          StreamBuilder<bool>(
            stream: telegramService.telegramLinkStatusStream(),
            builder: (context, snapshot) {
              final isLinked = snapshot.data ?? false;

              return Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isLinked
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: isLinked ? primaryGreen : Colors.grey.shade400,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telegram Alerts',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              isLinked
                                  ? 'Connected to @rescuenet_bot'
                                  : 'Receive alerts via Telegram',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      _buildToggleSwitch(_telegramEnabled, (value) {
                        setState(() => _telegramEnabled = value);
                        _saveTelegramPreference(value);
                      }, primaryGreen),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (isLinked && _telegramEnabled)
                    _buildTelegramConnectedUI(telegramService, primaryGreen)
                  else if (_telegramEnabled)
                    _buildTelegramConnectUI(telegramService, primaryGreen),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// UI when Telegram is connected
  Widget _buildTelegramConnectedUI(
    TelegramService telegramService,
    Color primaryGreen,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Connected to Telegram',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '@rescuenet_bot',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUnlinkDialog(telegramService),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Disconnect Telegram',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// UI to connect Telegram
  Widget _buildTelegramConnectUI(
    TelegramService telegramService,
    Color primaryGreen,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your Telegram account to receive instant alerts',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showTelegramLinkingFlow(telegramService),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0E9D63),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text('Connect Telegram', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog for Telegram linking flow
  void _showTelegramLinkingFlow(TelegramService telegramService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          TelegramLinkingDialog(telegramService: telegramService),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Telegram account linked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    });
  }

  /// Show confirmation dialog before unlinking
  void _showUnlinkDialog(TelegramService telegramService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect Telegram'),
        content: Text(
          'Are you sure you want to disconnect your Telegram account? You will stop receiving Telegram alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await telegramService.unlinkTelegram();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Telegram account disconnected'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() {});
            },
            child: Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          _buildToggleSwitch(value, onChanged, Color(0xFF0E9D63)),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(
    bool value,
    Function(bool) onChanged,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? activeColor : Colors.grey.shade300,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              left: value ? 28 : 4,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicNotificationCard({
    required dynamic notification,
    required VoidCallback onDismiss,
    required VoidCallback onRead,
  }) {
    final bgColor = notification.isRead ? Colors.white : Color(0xFFF0F9FF);

    final borderColor = notification.isRead
        ? Colors.grey.shade200
        : Color(0xFF0E9D63).withOpacity(0.2);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and close button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        notification.formattedTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!notification.isRead)
                      Container(
                        width: 6,
                        height: 6,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF0E9D63),
                          shape: BoxShape.circle,
                        ),
                      ),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 8),

            // Body text only
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 8),

            // Simple mark as read action
            if (!notification.isRead)
              GestureDetector(
                onTap: onRead,
                child: Text(
                  'Mark as read',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF0E9D63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getNotificationType(String type) {
    switch (type) {
      case 'report_status':
        return 'Report Update';
      case 'aid_program':
        return 'Aid Program';
      case 'alert':
        return 'Alert';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Handle notification tap - navigate to the relevant report/program
  void _handleNotificationTap(dynamic notification) {
    if (notification.data == null) {
      return;
    }

    final data = notification.data as Map<String, dynamic>;

    // Mark as read if not already
    if (!notification.isRead) {
      Provider.of<NotificationsProvider>(
        context,
        listen: false,
      ).markAsRead(notification.id);
    }

    // Route based on notification type
    switch (notification.type) {
      case 'report_status':
        // Own report status change
        final reportId = data['reportId'];
        final reportType = data['reportType'];
        if (reportId != null) {
          if (reportType == 'emergency') {
            _navigateToEmergencyReport(reportId);
          } else if (reportType == 'aid') {
            _navigateToAidRequest(reportId);
          }
        }
        break;

      case 'public_report':
        // Report from another citizen
        final reportId = data['reportId'];
        final reportType = data['reportType'];
        if (reportId != null && reportType != null) {
          _navigateToPublicReport(reportId, reportType);
        }
        break;

      case 'aid_program':
        // New program activation
        final programId = data['programId'];
        if (programId != null) {
          _navigateToProgram(programId);
        }
        break;

      case 'weather_alert':
        // Weather alert - navigate to map or alerts view
        _navigateToWeatherAlerts();
        break;

      default:
        break;
    }
  }

  /// Navigate to public report from another citizen
  void _navigateToPublicReport(String reportId, String reportType) {
    print('Navigating to public $reportType report: $reportId');
    Navigator.of(context).pushNamed(
      '/view-public-reports',
      arguments: {'reportType': reportType, 'reportId': reportId},
    );
  }

  /// Navigate to aid program details
  void _navigateToProgram(String programId) {
    print('Navigating to program: $programId');
    Navigator.of(
      context,
    ).pushNamed('/program-details', arguments: {'programId': programId});
  }

  /// Navigate to weather alerts
  void _navigateToWeatherAlerts() {
    print('Navigating to weather alerts');
    Navigator.of(context).pushNamed('/weather-alerts');
  }

  /// Navigate to emergency report details
  void _navigateToEmergencyReport(String reportId) {
    print('Navigating to emergency report: $reportId');
    // Navigate to my reports screen
    Navigator.of(context).pushNamed(
      '/view-reports',
      arguments: {'reportType': 'emergency', 'reportId': reportId},
    );
  }

  /// Navigate to aid request details
  void _navigateToAidRequest(String reportId) {
    print('Navigating to aid request: $reportId');
    // Navigate to my reports screen
    Navigator.of(
      context,
    ).pushNamed('/view-aid-requests', arguments: {'requestId': reportId});
  }

  /// Build test notification section for UI testing
  Widget _buildTestNotificationSection(Color primaryGreen) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Color(0xFFF57C00), size: 18),
              SizedBox(width: 8),
              Text(
                'Test Notifications',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF57C00),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Click below to create sample notifications for UI testing:',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          SizedBox(height: 10),
          // Weather Alert Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createTestFloodAlert(),
                  icon: Text('🌧️', style: TextStyle(fontSize: 14)),
                  label: Text('Flood Alert', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0277BD),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createTestThunderstormAlert(),
                  icon: Text('⛈️', style: TextStyle(fontSize: 14)),
                  label: Text('Thunderstorm', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Create test flood alert notification
  void _createTestFloodAlert() {
    final notificationsProvider = Provider.of<NotificationsProvider>(
      context,
      listen: false,
    );
    final weatherDetails = notificationsProvider.getWeatherAlertDetails();

    final location =
        weatherDetails != null && weatherDetails['location'] != null
        ? weatherDetails['location']
        : 'your area';

    notificationsProvider.sendNotification(
      title: '🌧️ Heavy Rainfall Warning',
      body: 'Heavy rainfall expected in $location',
      type: 'weather_alert',
      data: {
        'alertType': 'flood',
        'temperature': '28.5',
        'windSpeed': '15.2',
        'weatherCode': '80',
        'description': 'Heavy rainfall expected',
        'location': location,
        'detailedInfo':
            'Heavy rainfall expected\n\nTemperature: 28.5°C\nWind Speed: 15.2 km/h\nLocation: $location',
      },
      icon: '🌧️',
      actionUrl: '/alerts/weather',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Test flood alert created!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Create test thunderstorm alert notification
  void _createTestThunderstormAlert() {
    final notificationsProvider = Provider.of<NotificationsProvider>(
      context,
      listen: false,
    );
    final weatherDetails = notificationsProvider.getWeatherAlertDetails();

    final location =
        weatherDetails != null && weatherDetails['location'] != null
        ? weatherDetails['location']
        : 'your area';

    notificationsProvider.sendNotification(
      title: '⛈️ Thunderstorm Alert',
      body: 'Severe thunderstorm warning for $location',
      type: 'weather_alert',
      data: {
        'alertType': 'thunderstorm',
        'temperature': '26.3',
        'windSpeed': '22.8',
        'weatherCode': '95',
        'description': 'Severe thunderstorm with heavy rainfall',
        'location': location,
        'detailedInfo':
            'Severe thunderstorm with heavy rainfall\n\nTemperature: 26.3°C\nWind Speed: 22.8 km/h\nLocation: $location',
      },
      icon: '⛈️',
      actionUrl: '/alerts/weather',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Test thunderstorm alert created!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
