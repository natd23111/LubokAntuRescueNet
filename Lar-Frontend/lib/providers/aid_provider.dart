import 'package:flutter/material.dart';
import '../models/aid_request.dart';

class AidProvider with ChangeNotifier {
  List<AidRequest> requests = [];
  bool isLoading = false;

  // Fetch resident's aid requests
  Future<void> fetchMyRequests() async {
    isLoading = true;
    notifyListeners();

    try {
      // Firebase migration: This is deprecated in favor of aid_program_provider
      requests = [];
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
      // Firebase migration: This is deprecated in favor of aid_program_provider
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error submitting aid request: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
