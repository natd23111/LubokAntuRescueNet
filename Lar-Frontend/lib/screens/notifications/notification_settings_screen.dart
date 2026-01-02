import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notifications_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _telegramEnabled = true;
  bool _floodAlerts = true;
  bool _fireAlerts = true;
  bool _landslideAlerts = true;
  bool _weatherWarnings = true;

  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    Future.microtask(() {
      Provider.of<NotificationsProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text('Notification Settings', style: TextStyle(color: Colors.white)),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),

              SizedBox(height: 12),

              // Flood Alerts
              _buildAlertToggle(
                'Flood Warnings',
                'Heavy rainfall & flood alerts',
                _floodAlerts,
                (value) => setState(() => _floodAlerts = value),
              ),

              SizedBox(height: 8),

              // Fire Alerts
              _buildAlertToggle(
                'Fire Alerts',
                'Fire incidents in your area',
                _fireAlerts,
                (value) => setState(() => _fireAlerts = value),
              ),

              SizedBox(height: 8),

              // Landslide Alerts
              _buildAlertToggle(
                'Landslide Warnings',
                'Landslide risk notifications',
                _landslideAlerts,
                (value) => setState(() => _landslideAlerts = value),
              ),

              SizedBox(height: 8),

              // Weather Warnings
              _buildAlertToggle(
                'Weather Warnings',
                'Severe weather updates',
                _weatherWarnings,
                (value) => setState(() => _weatherWarnings = value),
              ),

              SizedBox(height: 24),

              // Recent Notifications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  Consumer<NotificationsProvider>(
                    builder: (context, provider, _) {
                      if (provider.unreadCount > 0) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${provider.unreadCount} new',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                            Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade300),
                            SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: provider.recentNotifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final notification = entry.value;
                      return Column(
                        children: [
                          _buildDynamicNotificationCard(
                            notification: notification,
                            onDismiss: () {
                              Provider.of<NotificationsProvider>(context, listen: false)
                                  .deleteNotification(notification.id);
                            },
                            onRead: () {
                              Provider.of<NotificationsProvider>(context, listen: false)
                                  .markAsRead(notification.id);
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
                                    Provider.of<NotificationsProvider>(context, listen: false)
                                        .clearAllNotifications();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Clear All', style: TextStyle(color: Colors.red)),
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
                          style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w500),
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
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _telegramEnabled ? Icons.notifications_active : Icons.notifications_off,
                color: _telegramEnabled ? primaryGreen : Colors.grey.shade400,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telegram Alerts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Receive alerts via Telegram',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              _buildToggleSwitch(_telegramEnabled, (value) => setState(() => _telegramEnabled = value), primaryGreen),
            ],
          ),
          SizedBox(height: 12),
          if (_telegramEnabled)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected to Telegram',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '@rescuenet_bot',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Manage Connection',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0E9D63),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Connect Telegram',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
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

  Widget _buildToggleSwitch(bool value, Function(bool) onChanged, Color activeColor) {
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
    final bgColor = notification.isRead 
      ? Colors.white 
      : Color(0xFFF0F9FF);
    
    final borderColor = notification.isRead 
      ? Colors.grey.shade200 
      : Color(0xFF0E9D63).withOpacity(0.3);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${notification.typeIcon} ${notification.title}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(int.parse('0xFF${notification.typeColor.replaceFirst('#', '')}')),
                    ),
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(0xFF0E9D63),
                      shape: BoxShape.circle,
                    ),
                  )
              ],
            ),
            SizedBox(height: 6),
            Text(
              notification.body,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification.formattedTime,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Row(
                  children: [
                    if (!notification.isRead)
                      GestureDetector(
                        onTap: onRead,
                        child: Text(
                          'Mark as read',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0E9D63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle notification tap - navigate to the relevant report
  void _handleNotificationTap(dynamic notification) {
    if (notification.type != 'report_status' || notification.data == null) {
      return;
    }

    final data = notification.data as Map<String, dynamic>;
    final reportId = data['reportId'];
    final reportType = data['reportType'];

    if (reportId == null) return;

    // Mark as read if not already
    if (!notification.isRead) {
      Provider.of<NotificationsProvider>(context, listen: false)
          .markAsRead(notification.id);
    }

    // Navigate to the appropriate report screen
    if (reportType == 'emergency') {
      _navigateToEmergencyReport(reportId);
    } else if (reportType == 'aid') {
      _navigateToAidRequest(reportId);
    }
  }

  /// Navigate to emergency report details
  void _navigateToEmergencyReport(String reportId) {
    print('Navigating to emergency report: $reportId');
    // Navigate to my reports screen
    Navigator.of(context).pushNamed('/view-reports', arguments: {
      'reportType': 'emergency',
      'reportId': reportId,
    });
  }

  /// Navigate to aid request details
  void _navigateToAidRequest(String reportId) {
    print('Navigating to aid request: $reportId');
    // Navigate to my reports screen
    Navigator.of(context).pushNamed('/view-reports', arguments: {
      'reportType': 'aid',
      'reportId': reportId,
    });
  }
}
