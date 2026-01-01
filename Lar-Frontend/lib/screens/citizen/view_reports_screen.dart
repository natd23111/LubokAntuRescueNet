import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/auth_provider.dart';

class ViewReportsScreen extends StatefulWidget {
  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  String activeTab = 'all-reports';
  String? selectedReportId;
  String searchQuery = '';
  String selectedType = 'All';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch my reports for the logged-in user
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      
      print('DEBUG ViewReportsScreen: authProvider.userId = ${authProvider.userId}');
      print('DEBUG ViewReportsScreen: currentUser?.uid = ${authProvider.currentUser?.uid}');
      
      if (authProvider.userId != null) {
        // Set user ID in reports provider
        print('DEBUG: Setting userId in ReportsProvider: ${authProvider.userId}');
        reportsProvider.setUserId(authProvider.userId!);
        // Fetch the user's reports
        print('DEBUG: Calling fetchMyReports()');
        reportsProvider.fetchMyReports();
      } else {
        print('ERROR: authProvider.userId is null');
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return const Color(0xFFFCD34D); // yellow
      case 'in-progress':
        return const Color(0xFF93C5FD); // blue
      case 'resolved':
        return const Color(0xFF059669); // dark green
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return const Color(0xFFFEF08A);
      case 'in-progress':
        return const Color(0xFFDBEAFE);
      case 'resolved':
        return const Color(0xFFD1FAE5); // light green
      default:
        return Colors.grey[100]!;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'unresolved':
        return 'Unresolved';
      case 'in-progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBgColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Full-screen image with zoom capability
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        Report? selectedReport;
        if (selectedReportId != null) {
          try {
            selectedReport = provider.allReports
                .firstWhere((r) => r.id == selectedReportId);
          } catch (e) {
            selectedReport = null;
          }
        }

        if (selectedReportId != null && selectedReport != null) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              setState(() => selectedReportId = null);
            },
            child: _buildDetailView(selectedReport),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF059669),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Report Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          body: Column(
            children: [
              // Tabs
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => activeTab = 'my-reports'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: activeTab == 'my-reports'
                                ? Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFF059669),
                                      width: 2,
                                    ),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'My Reports',
                              style: TextStyle(
                                color: activeTab == 'my-reports'
                                    ? const Color(0xFF059669)
                                    : Colors.grey[600],
                                fontWeight: activeTab == 'my-reports'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => activeTab = 'all-reports'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: activeTab == 'all-reports'
                                ? Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFF059669),
                                      width: 2,
                                    ),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'All Reports',
                              style: TextStyle(
                                color: activeTab == 'all-reports'
                                    ? const Color(0xFF059669)
                                    : Colors.grey[600],
                                fontWeight: activeTab == 'all-reports'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) =>
                      setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by type or location',
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: activeTab == 'my-reports'
                    ? _buildMyReportsTab(provider)
                    : _buildAllReportsTab(provider),
              ),

              // Error display
              if (provider.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border(
                      top: BorderSide(color: Colors.red[200]!),
                    ),
                  ),
                  child: Text(
                    'Error: ${provider.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyReportsTab(ReportsProvider provider) {
    final myReports = provider.myReports
        .where((r) =>
            r.reporterName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            r.type.toLowerCase().contains(searchQuery.toLowerCase()) ||
            r.location.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
        ),
      );
    }

    if (myReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: myReports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = myReports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildAllReportsTab(ReportsProvider provider) {
    final allReports = provider.allReports
        .where((r) =>
            (selectedType == 'All' ||
                r.type.toLowerCase() == selectedType.toLowerCase()) &&
            (r.type.toLowerCase().contains(searchQuery.toLowerCase()) ||
                r.location.toLowerCase().contains(searchQuery.toLowerCase())))
        .toList();

    final types = [
      'All',
      'Flood',
      'Fire',
      'Accident',
      'Medical Emergency',
      'Landslide'
    ];

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Type',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Reports list
          if (allReports.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No reports found',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allReports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = allReports[index];
                  return _buildReportCardWithReporter(report);
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return GestureDetector(
      onTap: () => setState(() => selectedReportId = report.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.reportId,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.type,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.location,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(report.dateReported),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCardWithReporter(Report report) {
    return GestureDetector(
      onTap: () => setState(() => selectedReportId = report.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.reportId,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.type,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.location,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By ${report.reporterName} • ${_formatDate(report.dateReported)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(Report report) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => setState(() => selectedReportId = null),
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report ID',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.reportId,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 16),

            _buildDetailField('Type', report.type),
            const SizedBox(height: 16),

            _buildDetailField('Location', report.location),
            const SizedBox(height: 16),

            _buildDetailField('Date Reported', report.formattedDate),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image placeholder
            if (report.imageUrls != null && report.imageUrls!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.imageUrls!.length == 1 ? 'Image' : 'Images',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (report.imageUrls!.length == 1)
                    GestureDetector(
                      onTap: () => _showFullScreenImage(report.imageUrls!.first),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          report.imageUrls!.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: report.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(report.imageUrls![index]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.network(
                              report.imageUrls![index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              )
            else if (report.imageUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullScreenImage(report.imageUrl!),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        report.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Status Timeline
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Timeline',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Report Submitted - Always Active
                  _buildTimelineItem(
                    'Report Submitted',
                    _formatDetailDate(report.dateReported),
                    isActive: true,
                  ),
                  // Under Review - Active when status is in-progress or resolved
                  _buildTimelineItem(
                    'Under Review',
                    report.dateUnderReview != null
                        ? _formatDetailDate(report.dateUnderReview!)
                        : 'Pending',
                    isActive: report.status == 'in-progress' ||
                        report.status == 'resolved',
                  ),
                  // Response Team Dispatched - Active when status is resolved
                  _buildTimelineItem(
                    'Resolved',
                    report.dateDispatched != null
                        ? _formatDetailDate(report.dateDispatched!)
                        : 'Pending',
                    isActive: report.status == 'resolved',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => selectedReportId = null),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Back to Reports'),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String date,
      {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF059669)
                      : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatDetailDate(DateTime dateTime) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }
}
