import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/storage_util.dart';

class Report {
  final int id;
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
  final String? adminNotes;
  final String? imageUrl;

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
    this.adminNotes,
    this.imageUrl,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      type: json['type'] ?? 'Other',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'unresolved',
      priority: json['priority']?.toLowerCase() ?? 'low',
      reporterName: json['reporter_name'] ?? 'Unknown',
      reporterIC: json['reporter_ic'] ?? '',
      reporterContact: json['reporter_contact'] ?? '',
      dateReported: json['date_reported'] != null
          ? DateTime.parse(json['date_reported'])
          : DateTime.now(),
      dateUpdated: json['date_updated'] != null
          ? DateTime.parse(json['date_updated'])
          : null,
      adminNotes: json['admin_notes'],
      imageUrl: json['image_url'],
    );
  }

  String get reportId => 'ER${id.toString().padLeft(7, '0')}';

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
  List<Report> _filteredReports = [];
  bool _isLoading = false;
  String? _error;
  String _activeTab = 'unresolved';
  String _searchQuery = '';

  final String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator localhost

  List<Report> get reports => _filteredReports;
  List<Report> get allReports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeTab => _activeTab;

  ReportsProvider({dynamic authProvider}) {
    fetchReports();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> data = jsonData['data'] ?? jsonData;
        
        _reports = (data as List)
            .map((item) => Report.fromJson(item as Map<String, dynamic>))
            .toList();
        
        _applyFilters();
        _error = null;
      } else {
        _error = 'Failed to load reports: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Report?> fetchReportDetails(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Report.fromJson(jsonData['data'] ?? jsonData);
      }
    } catch (e) {
      _error = 'Error fetching report: ${e.toString()}';
      notifyListeners();
    }
    return null;
  }

  Future<bool> updateReport({
    required int reportId,
    required String status,
    required String priority,
    required String adminNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'priority': priority,
          'admin_notes': adminNotes,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Refresh reports after update
        await fetchReports();
        return true;
      } else {
        _error = 'Failed to update report: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating report: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchReports();
        return true;
      } else {
        _error = 'Failed to delete report: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error deleting report: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredReports = _reports.where((report) {
      // Filter by tab
      if (report.status != _activeTab) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return report.reportId.toLowerCase().contains(query) ||
               report.type.toLowerCase().contains(query) ||
               report.location.toLowerCase().contains(query) ||
               report.title.toLowerCase().contains(query) ||
               report.reporterName.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();

    // Sort by priority (high → medium → low)
    _filteredReports.sort((a, b) {
      const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriority = priorityOrder[a.priority.toLowerCase()] ?? 3;
      final bPriority = priorityOrder[b.priority.toLowerCase()] ?? 3;
      return aPriority.compareTo(bPriority);
    });
  }

  String getPriorityDisplayText(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return priority;
    }
  }

  String getStatusDisplayText(String status) {
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
}
