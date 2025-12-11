import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
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
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text('Notification Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
              Text(
                'Recent Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),

              SizedBox(height: 12),

              // Flood Warning Notification
              _buildNotificationCard(
                '🌧️ Flood Warning',
                'Heavy rainfall expected in Lubok Antu area',
                'Dec 1, 2025 - 10:30 AM',
                Color(0xFFFFF3CD),
                Colors.orange.shade700,
              ),

              SizedBox(height: 8),

              // Report Update Notification
              _buildNotificationCard(
                '📋 Report Update',
                'Your report ER2025001 status changed to "In Progress"',
                'Nov 29, 2025 - 4:15 PM',
                Color(0xFFF8F9FA),
                Colors.grey.shade700,
              ),

              SizedBox(height: 8),

              // Aid Program Notification
              _buildNotificationCard(
                '🤝 New Aid Program',
                'B40 Financial Assistance 2025 is now available',
                'Nov 28, 2025 - 9:00 AM',
                Color(0xFFF8F9FA),
                Colors.grey.shade700,
              ),

              SizedBox(height: 24),

              // Back Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
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

  Widget _buildNotificationCard(String title, String message, String time, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9)),
          ),
          SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
