import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/aid_request_provider.dart';
import '../../providers/aid_program_provider.dart';
import '../../providers/weather_provider.dart';
import 'citizen/view_aid_program_screen.dart';
import 'citizen/weather_details_screen.dart';
import 'citizen/map_warnings_screen.dart';
import 'citizen/ai_chatbot_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notification_settings_screen.dart';
import 'citizen/view_reports_screen.dart';
import 'citizen/submit_emergency_screen.dart';
import 'citizen/submit_aid_request_screen.dart';
import 'citizen/view_aid_request_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _menuOpen = false;

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  @override
  void initState() {
    super.initState();
    // Load aid requests, reports, and programs data when dashboard initializes
    Future.microtask(() {
      final aidRequestProvider = Provider.of<AidRequestProvider>(context, listen: false);
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      final aidProgramProvider = Provider.of<AidProgramProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      aidRequestProvider.fetchUserAidRequests();
      reportsProvider.fetchReports();
      aidProgramProvider.fetchPrograms();
      weatherProvider.fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);

    // Set status bar color to green
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryGreen,
        statusBarIconBrightness: Brightness.light,
      ),
    );

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
          // Header with SafeArea to protect from punch-out but extend color behind status bar
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              color: primaryGreen,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 12,
                left: 12,
                right: 12,
              ),
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
            child: RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: primaryGreen,
              backgroundColor: Colors.white,
              strokeWidth: 3,
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

                // Alert card - Weather
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Consumer<WeatherProvider>(
                    builder: (context, weatherProvider, _) {
                      if (weatherProvider.isLoading) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Loading weather data...', style: TextStyle(color: Colors.black87)),
                              )
                            ],
                          ),
                        );
                      }

                      if (weatherProvider.error != null) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
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
                                    Text(weatherProvider.error!, style: TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }

                      if (weatherProvider.currentWeather == null) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_off, color: Colors.grey),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Weather data unavailable', style: TextStyle(color: Colors.black87)),
                              )
                            ],
                          ),
                        );
                      }

                      final shouldShowAlert = weatherProvider.shouldShowAlert();
                      final alertColor = shouldShowAlert ? Colors.orange : Colors.blue;
                      final alertBgColor = shouldShowAlert ? Colors.orange.shade50 : Colors.blue.shade50;
                      final alertBorderColor = shouldShowAlert ? Colors.orange.shade200 : Colors.blue.shade200;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WeatherDetailsScreen()),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: alertBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: alertBorderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                shouldShowAlert ? Icons.warning_amber_rounded : weatherProvider.getWeatherIcon(),
                                color: alertColor,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shouldShowAlert ? 'Weather Alert' : 'Weather Update',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      weatherProvider.getAlertMessage(),
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Last updated: ${DateTime.now().toString().split('.')[0]}',
                                      style: TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 12),

                // Stat tiles
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Consumer<ReportsProvider>(
                          builder: (context, reportsProvider, _) {
                            final activeCount = reportsProvider.activeReports.length;
                            return GestureDetector(
                              onTap: () async {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                      create: (_) => ReportsProvider(authProvider: authProvider),
                                      child: ViewReportsScreen(),
                                    ),
                                  ),
                                );
                                // Refresh the data when returning
                                reportsProvider.fetchReports();
                              },
                              child: statTile(activeCount.toString(), 'Active Reports', Colors.green.shade300),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Consumer<AidRequestProvider>(
                          builder: (context, aidRequestProvider, _) {
                            final pendingCount = aidRequestProvider.aidRequests
                                .where((request) => request.status.toLowerCase() == 'pending')
                                .length;
                            return GestureDetector(
                              onTap: () async {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                      create: (_) => AidRequestProvider(authProvider: authProvider),
                                      child: ViewAidRequestScreen(),
                                    ),
                                  ),
                                );
                                // Refresh the data when returning
                                aidRequestProvider.fetchUserAidRequests();
                              },
                              child: statTile(pendingCount.toString(), 'Aid Requests', Colors.blue.shade200),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Consumer<AidProgramProvider>(
                          builder: (context, aidProgramProvider, _) {
                            final newProgramsCount = aidProgramProvider.newPrograms.length;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewAidProgramScreen(),
                                  ),
                                );
                              },
                              child: statTile(newProgramsCount.toString(), 'New Programs', Colors.purple.shade100),
                            );
                          },
                        ),
                      ),
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
                      quickAction(Icons.report_problem, 'Submit Emergency', () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitEmergencyScreen(onBack: () => Navigator.pop(context)))), Colors.redAccent),
                      quickAction(Icons.description_rounded, 'View Reports', () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => ReportsProvider(authProvider: authProvider),
                              child: ViewReportsScreen(),
                            ),
                          ),
                        );
                      }, Colors.blueAccent),
                      quickAction(Icons.volunteer_activism, 'Request Aid', () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final aidRequestProvider = Provider.of<AidRequestProvider>(context, listen: false);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => AidRequestProvider(authProvider: authProvider),
                              child: SubmitAidRequestScreen(),
                            ),
                          ),
                        );
                        // Refresh aid requests when returning
                        aidRequestProvider.fetchUserAidRequests();
                      }, Colors.purpleAccent),
                      quickAction(Icons.notification_important, 'Aid Programs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewAidProgramScreen())), Colors.green),
                      quickAction(Icons.map_rounded, 'Map Warnings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapWarningsScreen())), Colors.orange),
                      quickAction(Icons.chat_rounded, 'AI Chatbot', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatbotScreen())), Colors.teal),
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
                  child: Consumer2<ReportsProvider, AidRequestProvider>(
                    builder: (context, reportsProvider, aidRequestProvider, _) {
                      // Get most recent report
                      final reports = reportsProvider.allReports;
                      final recentReport = reports.isNotEmpty ? reports.first : null;

                      // Get most recent aid request
                      final requests = aidRequestProvider.aidRequests;
                      final recentRequest = requests.isNotEmpty ? requests.first : null;

                      return Column(
                        children: [
                          if (recentReport != null)
                            GestureDetector(
                              onTap: () async {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                      create: (_) => ReportsProvider(authProvider: authProvider),
                                      child: ViewReportsScreen(),
                                    ),
                                  ),
                                );
                                reportsProvider.fetchReports();
                              },
                              child: _activityCard(
                                'Report ${recentReport.reportId}',
                                recentReport.status,
                                _getReportStatusBgColor(recentReport.status),
                                recentReport.title,
                                recentReport.formattedDate,
                              ),
                            ),
                          if (recentReport != null && recentRequest != null)
                            SizedBox(height: 8),
                          if (recentRequest != null)
                            GestureDetector(
                              onTap: () async {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                      create: (_) => AidRequestProvider(authProvider: authProvider),
                                      child: ViewAidRequestScreen(),
                                    ),
                                  ),
                                );
                                aidRequestProvider.fetchUserAidRequests();
                              },
                              child: _activityCard(
                                'Request ${recentRequest.requestId}',
                                recentRequest.status,
                                _getRequestStatusBgColor(recentRequest.status),
                                recentRequest.aidType,
                                recentRequest.formattedDate,
                              ),
                            ),
                          if (recentReport == null && recentRequest == null)
                            Container(
                              padding: EdgeInsets.all(16),
                              child: Text('No recent activity', style: TextStyle(color: Colors.grey[600])),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  /// Refresh all dashboard data
  Future<void> _refreshDashboard() async {
    try {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      final aidRequestProvider = Provider.of<AidRequestProvider>(context, listen: false);
      final aidProgramProvider = Provider.of<AidProgramProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);

      // Refresh all data in parallel
      await Future.wait([
        reportsProvider.fetchReports(),
        aidRequestProvider.fetchUserAidRequests(),
        aidProgramProvider.fetchPrograms(),
        weatherProvider.fetchWeather(),
      ]);

      print('✅ Dashboard refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing dashboard'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

  Color _getReportStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return Colors.red.shade100;
      case 'in-progress':
        return Colors.amber.shade100;
      case 'resolved':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getRequestStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue.shade50;
      case 'approved':
        return Colors.green.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }
}
