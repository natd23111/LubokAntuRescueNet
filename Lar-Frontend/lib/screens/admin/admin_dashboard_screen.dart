import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/aid_request_provider.dart';
import 'manage_aid_programs_screen.dart';
import 'manage_reports_screen.dart';
import 'manage_aid_requests_screen.dart';
import '../../widgets/app_footer.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _menuOpen = false;

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  @override
  void initState() {
    super.initState();
    // Load reports and aid requests data when dashboard initializes
    Future.microtask(() {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      final aidRequestProvider = Provider.of<AidRequestProvider>(context, listen: false);
      // For admin dashboard, only fetch ALL reports (not user-filtered reports)
      reportsProvider.fetchReports();
      aidRequestProvider.fetchUserAidRequests();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshDashboardData();
    }
  }

  void _refreshDashboardData() {
    Future.microtask(() {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      final aidRequestProvider = Provider.of<AidRequestProvider>(context, listen: false);
      reportsProvider.fetchReports();
      aidRequestProvider.fetchUserAidRequests();
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
                          'RescueNet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Admin Dashboard',
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

          // Dropdown menu
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
                    Icons.dashboard,
                    'Dashboard',
                    selected: true,
                    onTap: () => _toggleMenu(),
                  ),
                  Divider(),
                  _menuItem(
                    Icons.logout,
                    'Logout',
                    color: Colors.red,
                    onTap: () {
                      _logout(context);
                      _toggleMenu();
                    },
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Text(
                      'Welcome back, Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Here's what's happening today",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 24),

                    // Report Types Chart
                    Consumer<ReportsProvider>(
                      builder: (context, reportsProvider, _) {
                        return Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📊 Report Types Distribution',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildSimpleBarChart(reportsProvider.allReports),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 16),

                    // Status Distribution
                    Consumer<ReportsProvider>(
                      builder: (context, reportsProvider, _) {
                        final unresolvedCount = reportsProvider.allReports
                            .where((r) => r.status.toLowerCase() == 'unresolved')
                            .length;
                        final inProgressCount = reportsProvider.allReports
                            .where((r) => r.status.toLowerCase() == 'in-progress')
                            .length;
                        final resolvedCount = reportsProvider.allReports
                            .where((r) => r.status.toLowerCase() == 'resolved')
                            .length;
                        
                        return Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🥧 Status Distribution',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildPieChart(unresolvedCount, inProgressCount, resolvedCount),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 16),

                    // Weekly Trend
                    Consumer<ReportsProvider>(
                      builder: (context, reportsProvider, _) {
                        return Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📈 Weekly Reports Trend',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 24),
                              _buildWeeklyChart(reportsProvider.allReports),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: [
                        _buildQuickAction(context, '📋', 'Manage\nReports', Color(0xFF3B82F6), 'reports'),
                        _buildQuickAction(context, '🤝', 'Aid\nRequests', Color(0xFFA855F7), 'requests'),
                        _buildQuickAction(context, '📢', 'Aid\nPrograms', Color(0xFF10B981), 'programs'),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Recent Activity
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Consumer2<ReportsProvider, AidRequestProvider>(
                      builder: (context, reportsProvider, aidRequestProvider, _) {
                        final recentReport = reportsProvider.allReports.isNotEmpty 
                            ? reportsProvider.allReports.first 
                            : null;
                        final recentRequest = aidRequestProvider.aidRequests.isNotEmpty 
                            ? aidRequestProvider.aidRequests.first 
                            : null;
                        
                        return Column(
                          children: [
                            if (recentReport != null)
                              _buildActivityCard(
                                '🚨 New emergency report',
                                recentReport.title,
                                _getTimeAgo(recentReport.dateReported),
                                recentReport.status.toUpperCase(),
                                _getStatusColor(recentReport.status),
                              ),
                            if (recentRequest != null) ...[
                              SizedBox(height: 8),
                              _buildActivityCard(
                                '📋 Aid request submitted',
                                '${recentRequest.aidType} by ${recentRequest.applicantName ?? "Applicant"}',
                                _getTimeAgo(DateTime.now()), // Use current time for requests
                                recentRequest.status.toUpperCase(),
                                _getRequestStatusColor(recentRequest.status),
                              ),
                            ],
                            if (recentReport == null && recentRequest == null)
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Text('No recent activity', style: TextStyle(color: Colors.grey[600])),
                              ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Priority Alerts
                    Consumer<ReportsProvider>(
                      builder: (context, reportsProvider, _) {
                        final unresolvedCount = reportsProvider.allReports
                            .where((r) => r.status.toLowerCase() == 'unresolved')
                            .length;
                        
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              // Background and border
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                ),
                              ),
                              // Red left border
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              // Content
                              Padding(
                                padding: EdgeInsets.all(16).copyWith(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'High Priority Reports',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF7F1D1D),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '$unresolvedCount emergency report${unresolvedCount != 1 ? 's' : ''} require${unresolvedCount != 1 ? '' : 's'} immediate attention',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFB91C1C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => ChangeNotifierProvider(
                                                create: (_) => ReportsProvider(authProvider: authProvider),
                                                child: ManageReportsScreen(
                                                  onBack: () {
                                                    Navigator.of(context).pop();
                                                    _refreshDashboardData();
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFDC2626),
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Text(
                                          'View Reports',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    const AppFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(List<Report> reports) {
    // Count reports by type
    Map<String, int> typeCounts = {};
    for (var report in reports) {
      typeCounts[report.type] = (typeCounts[report.type] ?? 0) + 1;
    }

    // Get top 5 types
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTypes = sortedTypes.take(5).toList();

    if (topTypes.isEmpty) {
      return Center(child: Text('No reports data available'));
    }

    // Create bar chart data
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < topTypes.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: topTypes[i].value.toDouble(),
              color: Color(0xFF10B981),
              width: 20,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < topTypes.length) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          topTypes[index].key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
                reservedSize: 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topTypes[groupIndex].key}\n${rod.toY.toInt()} reports',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLegend(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<Report> reports) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    // Count reports for each day of the week (last 7 days)
    List<int> values = [];
    List<String> dayLabels = [];
    final now = DateTime.now();
    
    // DEBUG: Print all report dates
    print('=== WEEKLY CHART DEBUG ===');
    print('Total reports: ${reports.length}');
    print('Today: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    for (var r in reports.take(10)) {
      print('Report: ${r.title}, date: ${r.dateReported.year}-${r.dateReported.month.toString().padLeft(2, '0')}-${r.dateReported.day.toString().padLeft(2, '0')}');
    }
    
    for (int i = 0; i < 7; i++) {
      final dayDate = now.subtract(Duration(days: 5 - i));
      
      // Create label with day name and date
      final dayName = dayNames[dayDate.weekday % 7];
      dayLabels.add('$dayName\n${dayDate.day}');
      
      final count = reports.where((r) {
        try {
          // dateReported is already a DateTime from Firebase
          final reportDate = r.dateReported;
          return reportDate.year == dayDate.year &&
              reportDate.month == dayDate.month &&
              reportDate.day == dayDate.day;
        } catch (e) {
          return false;
        }
      }).length;
      print('Day ${i} (${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}): $count reports');
      values.add(count);
    }

    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b).toDouble();
    final interval = maxValue > 0 ? (maxValue / 4).ceil().toDouble() : 1.0;

    // Create line chart spots
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i].toDouble()));
    }

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Color(0xFF10B981),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Color(0xFF10B981).withOpacity(0.2),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barAreaData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Color(0xFF10B981),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dayLabels.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toInt()} reports',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String icon, String label, Color color, String action) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (action == 'programs') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageAidProgramsScreen(),
                ),
              );
            } else if (action == 'reports') {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => ReportsProvider(authProvider: authProvider),
                    child: ManageReportsScreen(
                      onBack: () {
                        Navigator.of(context).pop();
                        _refreshDashboardData();
                      },
                    ),
                  ),
                ),
              );
            } else if (action == 'requests') {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => AidRequestProvider(authProvider: authProvider),
                    child: ManageAidRequestsScreen(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(icon, style: TextStyle(fontSize: 24)),
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String detail,
    String time,
    String status,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
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

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return Color(0xFFFEF3C7);
      case 'in-progress':
        return Color(0xFFBFDBFE);
      case 'resolved':
        return Color(0xFFD1FAE5);
      default:
        return Color(0xFFF3F4F6);
    }
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Color(0xFFFEF3C7);
      case 'approved':
        return Color(0xFFD1FAE5);
      case 'rejected':
        return Color(0xFFFEE2E2);
      default:
        return Color(0xFFF3F4F6);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes != 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() != 1 ? 's' : ''} ago';
    }
  }

  Widget _buildPieChart(int unresolved, int inProgress, int resolved) {
    final total = unresolved + inProgress + resolved;
    
    if (total == 0) {
      return Center(child: Text('No status data available'));
    }

    return StatefulBuilder(
      builder: (context, setState) {
        int? touchedIndex;
        
        return Column(
          children: [
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: unresolved.toDouble(),
                      title: '',
                      radius: 120,
                      color: Color(0xFFF59E0B),
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: inProgress.toDouble(),
                      title: '',
                      radius: 120,
                      color: Color(0xFF3B82F6),
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: resolved.toDouble(),
                      title: '',
                      radius: 120,
                      color: Color(0xFF10B981),
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (pieTouchResponse?.touchedSection != null) {
                          touchedIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                        } else {
                          touchedIndex = null;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Hover Tooltip
            if (touchedIndex != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  touchedIndex == 0
                      ? 'Unresolved: $unresolved'
                      : touchedIndex == 1
                          ? 'In Progress: $inProgress'
                          : 'Resolved: $resolved',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            if (touchedIndex == null) SizedBox(height: 10),
            // Legend
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Unresolved',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      Text(
                        '$unresolved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'In Progress',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      Text(
                        '$inProgress',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Resolved',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      Text(
                        '$resolved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
