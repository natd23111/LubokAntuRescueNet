import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'emergency/emergency_list.dart';
import 'aid/aid_list.dart';
import 'bantuan/bantuan_list.dart';
import 'profile/profile_screen.dart';
import 'notifications/notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _menuOpen = false;

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);

    Widget statTile(String count, String label, Color borderColor) {
      return Container(
        height: 120,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: borderColor)),
            SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    Widget quickAction(IconData icon, String label, VoidCallback onTap, Color bgColor) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(backgroundColor: bgColor, child: Icon(icon, color: Colors.white)),
              SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      body: Column(
        children: [
          // Header
          Container(
            color: primaryGreen,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RescueNet', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Citizen Dashboard', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(onPressed: _toggleMenu, icon: Icon(_menuOpen ? Icons.close : Icons.menu, color: Colors.white)),
              ],
            ),
          ),

          // Dropdown menu shown when header button is tapped
          if (_menuOpen)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuItem(Icons.home, 'Dashboard', selected: true, onTap: () {
                    _toggleMenu();
                  }),
                  _menuItem(Icons.person, 'Profile', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
                    _toggleMenu();
                  }),
                  _menuItem(Icons.notifications, 'Notification Settings', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationSettingsScreen()));
                    _toggleMenu();
                  }),
                  Divider(),
                  _menuItem(Icons.logout, 'Logout', color: Colors.red, onTap: () {
                    _logout(context);
                    _toggleMenu();
                  }),
                ],
              ),
            ),

          // Scrollable body content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(12),
              children: [
                // Welcome
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            authProvider.userName ?? 'User',
                            style: TextStyle(color: Colors.black54),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Alert card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weather Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('Heavy rainfall expected in your area. Stay alert.', style: TextStyle(color: Colors.black87)),
                              SizedBox(height: 8),
                              Text('Dec 1, 2025 - 10:30 AM', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Stat tiles
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: statTile('2', 'Active Reports', Colors.green.shade300)),
                      SizedBox(width: 8),
                      Expanded(child: statTile('1', 'Aid Requests', Colors.blue.shade200)),
                      SizedBox(width: 8),
                      Expanded(child: statTile('5', 'New Programs', Colors.purple.shade100)),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Quick Actions label
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w600)),
                ),

                SizedBox(height: 8),

                // Quick action grid (2 columns)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      quickAction(Icons.report_problem, 'Submit Emergency', () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyListScreen())), Colors.redAccent),
                      quickAction(Icons.list_alt, 'View Reports', () {}, Colors.blueAccent),
                      quickAction(Icons.request_page, 'Request Aid', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AidListScreen())), Colors.purpleAccent),
                      quickAction(Icons.local_activity, 'Aid Programs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => BantuanListScreen())), Colors.green),
                      quickAction(Icons.map, 'Map Warnings', () {}, Colors.orange),
                      quickAction(Icons.chat, 'AI Chatbot', () {}, Colors.teal),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Recent Activity
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                ),

                SizedBox(height: 8),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      _activityCard('Emergency Report #ER2025001', 'In Progress', Colors.amber.shade100, 'Flood - Jalan Sungai Besar', 'Nov 29, 2025'),
                      SizedBox(height: 8),
                      _activityCard('Aid Request #AR2025012', 'Pending', Colors.blue.shade50, 'Disaster Relief Aid', 'Nov 28, 2025'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(String title, String status, Color bg, String subtitle, String date) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.black54)),
                SizedBox(height: 8),
                Text(date, style: TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _menuItem(IconData icon, String label, {VoidCallback? onTap, bool selected = false, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color ?? (selected ? Color(0xFF0E9D63) : Colors.black54)),
            SizedBox(width: 12),
            Text(label, style: TextStyle(color: color ?? (selected ? Color(0xFF0E9D63) : Colors.black87), fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
