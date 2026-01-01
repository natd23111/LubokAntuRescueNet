import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String title;
  final String type;
  final String location;
  final String description;
  final String status;
  final String priority;
  final String reporterName;
  final String reporterIC;
  final String reporterContact;
  final DateTime dateReported;
  final DateTime? dateUpdated;
  final DateTime? dateUnderReview;
  final DateTime? dateDispatched;
  final String? adminNotes;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? userId;

  Report({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.description,
    required this.status,
    required this.priority,
    required this.reporterName,
    required this.reporterIC,
    required this.reporterContact,
    required this.dateReported,
    this.dateUpdated,
    this.dateUnderReview,
    this.dateDispatched,
    this.adminNotes,
    this.imageUrl,
    this.imageUrls,
    this.userId,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      type: data['type'] ?? 'Other',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'unresolved',
      priority: (data['priority'] ?? 'low').toString().toLowerCase(),
      reporterName: data['reporter_name'] ?? 'Unknown',
      reporterIC: data['reporter_ic'] ?? '',
      reporterContact: data['reporter_contact'] ?? '',
      dateReported: data['date_reported'] != null
          ? (data['date_reported'] is Timestamp
              ? (data['date_reported'] as Timestamp).toDate()
              : DateTime.parse(data['date_reported']))
          : DateTime.now(),
      dateUpdated: data['date_updated'] != null
          ? (data['date_updated'] is Timestamp
              ? (data['date_updated'] as Timestamp).toDate()
              : DateTime.parse(data['date_updated']))
          : null,
      dateUnderReview: data['date_under_review'] != null
          ? (data['date_under_review'] is Timestamp
              ? (data['date_under_review'] as Timestamp).toDate()
              : DateTime.parse(data['date_under_review']))
          : null,
      dateDispatched: data['date_dispatched'] != null
          ? (data['date_dispatched'] is Timestamp
              ? (data['date_dispatched'] as Timestamp).toDate()
              : DateTime.parse(data['date_dispatched']))
          : null,
      adminNotes: data['admin_notes'],
      imageUrl: data['image_url'],
      imageUrls: data['image_urls'] != null
          ? List<String>.from((data['image_urls'] as List).map((e) => e.toString()))
          : (data['image_url'] != null ? [data['image_url'].toString()] : null),
      userId: data['user_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'location': location,
      'description': description,
      'status': status.toLowerCase(),
      'priority': priority.toLowerCase(),
      'reporter_name': reporterName,
      'reporter_ic': reporterIC,
      'reporter_contact': reporterContact,
      'date_reported': dateReported,
      'date_updated': dateUpdated,
      'date_under_review': dateUnderReview,
      'date_dispatched': dateDispatched,
      'admin_notes': adminNotes,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'user_id': userId,
    };
  }

  String get reportId => id;

  String get formattedDate {
    return '${dateReported.day} ${_monthName(dateReported.month)}, ${dateReported.year} - ${dateReported.hour.toString().padLeft(2, '0')}:${dateReported.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class ReportsProvider extends ChangeNotifier {
  List<Report> _reports = [];
  List<Report> _myReports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = false;
  String? _error;
  String _activeTab = 'unresolved';
  String _searchQuery = '';
  String? _userId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Report> get reports => _filteredReports;
  List<Report> get allReports => _reports;
  List<Report> get myReports => _myReports;
  List<Report> get activeReports => _reports
      .where((report) => report.status.toLowerCase() == 'unresolved' || report.status.toLowerCase() == 'in-progress')
      .toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeTab => _activeTab;

  ReportsProvider({dynamic authProvider}) {
    if (authProvider != null && authProvider.userId != null) {
      _userId = authProvider.userId.toString();
    }
    Future.delayed(Duration.zero, () {
      fetchReports();
      if (_userId != null) {
        fetchMyReports();
      }
    });
  }

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  Future<void> fetchReports() async {
    print('DEBUG: fetchReports() called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('emergency_reports')
          .orderBy('date_reported', descending: true)
          .get();

      print('DEBUG: Fetched ${snapshot.docs.length} reports from Firestore');

      _reports = snapshot.docs
          .map((doc) => Report.fromFirestore(doc))
          .toList();

      _applyFilters();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('ERROR fetching reports: $e');
      _error = 'Failed to fetch reports: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyReports() async {
    print('DEBUG: fetchMyReports() called for user: $_userId');
    if (_userId == null) {
      print('ERROR: _userId is null, cannot fetch my reports');
      _myReports = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('DEBUG: Fetching all reports first, then filtering for user_id = $_userId');
      
      // Get all reports ordered by date
      final snapshot = await _firestore
          .collection('emergency_reports')
          .orderBy('date_reported', descending: true)
          .get();

      print('DEBUG: Fetched ${snapshot.docs.length} total reports');
      
      // Filter by user_id locally to avoid composite index requirement
      final allReports = snapshot.docs
          .map((doc) => Report.fromFirestore(doc))
          .toList();

      // Filter by matching user_id
      _myReports = allReports.where((report) {
        final matches = report.userId == _userId;
        if (matches) {
          print('DEBUG: Report ${report.id} matches user_id $_userId');
        }
        return matches;
      }).toList();
      
      print('DEBUG: After filtering: ${_myReports.length} reports match user_id $_userId');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('ERROR fetching my reports: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateReport({
    required String reportId,
    required String status,
    required String priority,
    required String adminNotes,
  }) async {
    print('DEBUG: Updating report: $reportId with status: $status');

    try {
      final updateData = {
        'status': status.toLowerCase(),
        'priority': priority.toLowerCase(),
        'admin_notes': adminNotes,
        'date_updated': DateTime.now(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Track status transition dates
      final statusLower = status.toLowerCase();
      if (statusLower == 'in-progress') {
        updateData['date_under_review'] = DateTime.now();
      } else if (statusLower == 'resolved') {
        updateData['date_dispatched'] = DateTime.now();
      }

      await _firestore
          .collection('emergency_reports')
          .doc(reportId)
          .update(updateData);

      print('DEBUG: Report updated successfully: $reportId');

      // Refresh reports
      await fetchReports();
      if (_userId != null) {
        await fetchMyReports();
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR updating report: $e');
      _error = 'Failed to update report: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    print('DEBUG: Deleting report: $reportId');

    try {
      await _firestore.collection('emergency_reports').doc(reportId).delete();

      print('DEBUG: Report deleted successfully: $reportId');

      // Refresh reports
      await fetchReports();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR deleting report: $e');
      _error = 'Failed to delete report: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void setActiveTab(String tab) {
    print('DEBUG: Setting active tab: $tab');
    _activeTab = tab;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    print('DEBUG: Setting search query: $query');
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    print('DEBUG: Applying filters - tab: $_activeTab, search: $_searchQuery');

    _filteredReports = _reports.where((report) {
      // Filter by tab (status)
      if (_activeTab != 'all' && report.status != _activeTab) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return report.title.toLowerCase().contains(_searchQuery) ||
            report.location.toLowerCase().contains(_searchQuery) ||
            report.reporterName.toLowerCase().contains(_searchQuery) ||
            report.type.toLowerCase().contains(_searchQuery);
      }

      return true;
    }).toList();

    print(
        'DEBUG: Filtered to ${_filteredReports.length} reports (from ${_reports.length})');
  }

  Stream<List<Report>> getReportsStream({String? filterStatus}) {
    Query query = _firestore.collection('emergency_reports');

    if (filterStatus != null && filterStatus != 'all') {
      query = query.where('status', isEqualTo: filterStatus);
    }

    query = query.orderBy('date_reported', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  Future<String?> createEmergencyReport(Map<String, dynamic> reportData) async {
    print('DEBUG: Creating emergency report with data: $reportData');

    try {
      final year = DateTime.now().year;
      final counterDocId = 'report_counter_$year';

      // Get the current counter value
      final counterDoc = await _firestore
          .collection('_metadata')
          .doc(counterDocId)
          .get();

      int currentCounter = 0;
      if (counterDoc.exists) {
        currentCounter = (counterDoc.data()?['counter'] ?? 0) as int;
      }

      // Increment the counter
      final nextCounter = currentCounter + 1;

      // Update the counter in Firestore (atomically)
      await _firestore
          .collection('_metadata')
          .doc(counterDocId)
          .set({'counter': nextCounter});

      final reportId = 'ER$year${nextCounter.toString().padLeft(4, '0')}';
      print('DEBUG: Generated report ID: $reportId (counter: $nextCounter)');

      // Add the ID to the report data
      reportData['id'] = reportId;
      reportData['created_at'] = DateTime.now().toIso8601String();
      reportData['updated_at'] = DateTime.now().toIso8601String();

      // Save the report
      await _firestore
          .collection('emergency_reports')
          .doc(reportId)
          .set(reportData);

      print('DEBUG: Emergency report created successfully: $reportId');

      // Refresh reports
      await fetchReports();
      _error = null;
      notifyListeners();

      return reportId;
    } catch (e) {
      print('ERROR creating emergency report: $e');
      _error = 'Failed to create report: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
}
