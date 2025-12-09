import 'package:flutter/material.dart';
import '../models/emergency_report.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class EmergencyProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<EmergencyReport> reports = [];
  bool isLoading = false;

  // Fetch resident's emergency reports
  Future<void> fetchMyReports() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.myEmergencyReports);
      reports = (response.data['data'] as List)
          .map((e) => EmergencyReport.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching emergency reports: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // Submit a new emergency report
  Future<bool> submitEmergency(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.submitEmergency, data);
      isLoading = false;
      notifyListeners();
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error submitting emergency: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
