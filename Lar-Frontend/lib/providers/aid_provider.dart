import 'package:flutter/material.dart';
import '../models/aid_request.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AidProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<AidRequest> requests = [];
  bool isLoading = false;

  // Fetch resident's aid requests
  Future<void> fetchMyRequests() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.myAidRequests);
      requests = (response.data['data'] as List)
          .map((e) => AidRequest.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching aid requests: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // Submit a new aid request
  Future<bool> submitAid(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.submitAid, data);
      isLoading = false;
      notifyListeners();
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error submitting aid request: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
