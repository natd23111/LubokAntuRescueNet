import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
import '../../widgets/app_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
      final aidRequestProvider = Provider.of<AidRequestProvider>(
        context,
        listen: false,
      );
      final reportsProvider = Provider.of<ReportsProvider>(
        context,
        listen: false,
      );
      final aidProgramProvider = Provider.of<AidProgramProvider>(
        context,
        listen: false,
      );
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      aidRequestProvider.fetchUserAidRequests();
      reportsProvider.fetchReports();
      aidProgramProvider.fetchPrograms();
      weatherProvider.fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);
    final l10n = AppLocalizations.of(context)!;

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
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget quickAction(
        IconData icon,
        String label,
        VoidCallback onTap,
        Color bgColor,
        ) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: bgColor,
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
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
                        Text(
                          l10n.rescueNet,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          l10n.citizenDashboard,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleMenu,
                    icon: Icon(
                      _menuOpen ? Icons.close : Icons.menu,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dropdown menu shown when header button is tapped
          if (_menuOpen)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuItem(
                    Icons.home,
                    l10n.dashboard,
                    selected: true,
                    onTap: () {
                      _toggleMenu();
                    },
                  ),
                  _menuItem(
                    Icons.person,
                    l10n.profile,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      );
                      _toggleMenu();
                    },
                  ),
                  _menuItem(
                    Icons.notifications,
                    l10n.notificationSettings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationSettingsScreen(),
                        ),
                      );
                      _toggleMenu();
                    },
                  ),
                  Divider(),
                  _menuItem(
                    Icons.logout,
                    l10n.logout,
                    color: Colors.red,
                    onTap: () {
                      _logout(context);
                      _toggleMenu();
                    },
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            final name = authProvider.userName ?? 'User';
                            return Text(
                              '${l10n.welcomeBack}, $name!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.checkAlerts,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.loadingWeatherData,
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
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
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.weatherAlert,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        weatherProvider.error!,
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
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
                                  child: Text(
                                    l10n.weatherUnavailable,
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final shouldShowAlert = weatherProvider
                            .shouldShowAlert();
                        final alertColor = shouldShowAlert
                            ? Colors.orange
                            : Colors.blue;
                        final alertBgColor = shouldShowAlert
                            ? Colors.orange.shade50
                            : Colors.blue.shade50;
                        final alertBorderColor = shouldShowAlert
                            ? Colors.orange.shade200
                            : Colors.blue.shade200;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeatherDetailsScreen(),
                              ),
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
                                  shouldShowAlert
                                      ? Icons.warning_amber_rounded
                                      : weatherProvider.getWeatherIcon(),
                                  color: alertColor,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shouldShowAlert
                                            ? l10n.weatherAlert
                                            : l10n.weatherUpdate,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        weatherProvider.getAlertMessage(),
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Last updated: ${DateTime.now().toString().split('.')[0]}',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                              final activeCount =
                                  reportsProvider.activeReports.length;
                              return GestureDetector(
                                onTap: () async {
                                  final authProvider =
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider(
                                        create: (_) => ReportsProvider(
                                          authProvider: authProvider,
                                        ),
                                        child: ViewReportsScreen(),
                                      ),
                                    ),
                                  );
                                  // Refresh the data when returning
                                  reportsProvider.fetchReports();
                                },
                                child: statTile(
                                  activeCount.toString(),
                                  l10n.activeReports,
                                  Colors.green.shade300,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Consumer<AidRequestProvider>(
                            builder: (context, aidRequestProvider, _) {
                              final pendingCount = aidRequestProvider
                                  .aidRequests
                                  .where(
                                    (request) =>
                                request.status.toLowerCase() ==
                                    'pending',
                              )
                                  .length;
                              return GestureDetector(
                                onTap: () async {
                                  final authProvider =
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider(
                                        create: (_) => AidRequestProvider(
                                          authProvider: authProvider,
                                        ),
                                        child: ViewAidRequestScreen(),
                                      ),
                                    ),
                                  );
                                  // Refresh the data when returning
                                  aidRequestProvider.fetchUserAidRequests();
                                },
                                child: statTile(
                                  pendingCount.toString(),
                                  l10n.aidRequests,
                                  Colors.blue.shade200,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Consumer<AidProgramProvider>(
                            builder: (context, aidProgramProvider, _) {
                              final newProgramsCount =
                                  aidProgramProvider.newPrograms.length;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ViewAidProgramScreen(),
                                    ),
                                  );
                                },
                                child: statTile(
                                  newProgramsCount.toString(),
                                  l10n.newPrograms,
                                  Colors.purple.shade100,
                                ),
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
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                        quickAction(
                          Icons.report_problem,
                          l10n.submitEmergency,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubmitEmergencyScreen(
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          Colors.redAccent,
                        ),
                        quickAction(
                          Icons.description_rounded,
                          l10n.viewReports,
                              () {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => ReportsProvider(
                                    authProvider: authProvider,
                                  ),
                                  child: ViewReportsScreen(),
                                ),
                              ),
                            );
                          },
                          Colors.blueAccent,
                        ),
                        quickAction(
                          Icons.volunteer_activism,
                          l10n.requestAid,
                              () async {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final aidRequestProvider =
                            Provider.of<AidRequestProvider>(
                              context,
                              listen: false,
                            );
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => AidRequestProvider(
                                    authProvider: authProvider,
                                  ),
                                  child: SubmitAidRequestScreen(),
                                ),
                              ),
                            );
                            // Refresh aid requests when returning
                            aidRequestProvider.fetchUserAidRequests();
                          },
                          Colors.purpleAccent,
                        ),
                        quickAction(
                          Icons.notification_important,
                          l10n.viewAidPrograms,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewAidProgramScreen(),
                            ),
                          ),
                          Colors.green,
                        ),
                        quickAction(
                          Icons.map_rounded,
                          l10n.mapWarnings,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapWarningsScreen(),
                            ),
                          ),
                          Colors.orange,
                        ),
                        quickAction(
                          Icons.chat_rounded,
                          l10n.aiChatbot,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AIChatbotScreen(),
                            ),
                          ),
                          Colors.teal,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Recent Activity
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      l10n.refreshing,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  SizedBox(height: 8),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Consumer2<ReportsProvider, AidRequestProvider>(
                      builder:
                          (context, reportsProvider, aidRequestProvider, _) {
                        // Get most recent report
                        final reports = reportsProvider.allReports;
                        final recentReport = reports.isNotEmpty
                            ? reports.first
                            : null;

                        // Get most recent aid request
                        final requests = aidRequestProvider.aidRequests;
                        final recentRequest = requests.isNotEmpty
                            ? requests.first
                            : null;

                        return Column(
                          children: [
                            if (recentReport != null)
                              GestureDetector(
                                onTap: () async {
                                  final authProvider =
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChangeNotifierProvider(
                                            create: (_) => ReportsProvider(
                                              authProvider: authProvider,
                                            ),
                                            child: ViewReportsScreen(),
                                          ),
                                    ),
                                  );
                                  reportsProvider.fetchReports();
                                },
                                child: _activityCard(
                                  'Report ${recentReport.reportId}',
                                  recentReport.status,
                                  _getReportStatusBgColor(
                                    recentReport.status,
                                  ),
                                  recentReport.title,
                                  recentReport.formattedDate,
                                  isRequest: false,
                                ),
                              ),
                            if (recentReport != null &&
                                recentRequest != null)
                              SizedBox(height: 8),
                            if (recentRequest != null)
                              GestureDetector(
                                onTap: () async {
                                  final authProvider =
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChangeNotifierProvider(
                                            create: (_) =>
                                                AidRequestProvider(
                                                  authProvider:
                                                  authProvider,
                                                ),
                                            child: ViewAidRequestScreen(),
                                          ),
                                    ),
                                  );
                                  aidRequestProvider.fetchUserAidRequests();
                                },
                                child: _activityCard(
                                  'Request ${recentRequest.requestId}',
                                  recentRequest.status,
                                  _getRequestStatusBgColor(
                                    recentRequest.status,
                                  ),
                                  recentRequest.aidType,
                                  recentRequest.formattedDate,
                                  isRequest: true,
                                ),
                              ),
                            if (recentReport == null &&
                                recentRequest == null)
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No recent activity',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const AppFooter(),
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
      final reportsProvider = Provider.of<ReportsProvider>(
        context,
        listen: false,
      );
      final aidRequestProvider = Provider.of<AidRequestProvider>(
        context,
        listen: false,
      );
      final aidProgramProvider = Provider.of<AidProgramProvider>(
        context,
        listen: false,
      );
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );

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

  Widget _activityCard(
      String title,
      String status,
      Color bg,
      String subtitle,
      String date, {
        bool isRequest = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
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
                Text(
                  date,
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              // Status in Sentence case (e.g., "Unresolved")
              _toSentenceCase(status),
              style: TextStyle(
                fontSize: 12,
                color: isRequest
                    ? _getRequestStatusTextColor(status)
                    : _getReportStatusTextColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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

  Widget _menuItem(
      IconData icon,
      String label, {
        VoidCallback? onTap,
        bool selected = false,
        Color? color,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? (selected ? Color(0xFF0E9D63) : Colors.black54),
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color ?? (selected ? Color(0xFF0E9D63) : Colors.black87),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getReportStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return Colors.amber.shade100; // show as yellow
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

  Color _getReportStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return const Color(0xFFD97706); // dark yellow/orange
      case 'in-progress':
        return const Color(0xFF1E3A8A); // dark blue
      case 'resolved':
        return const Color(0xFF059669); // dark green
      default:
        return Colors.black87;
    }
  }

  Color _getRequestStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'approved':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFF04438);
      default:
        return Colors.black87;
    }
  }

  String _toSentenceCase(String s) {
    if (s.isEmpty) return s;
    final lower = s.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
