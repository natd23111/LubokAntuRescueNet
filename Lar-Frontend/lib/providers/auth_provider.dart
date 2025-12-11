import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../utils/storage_util.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool isLoading = false;
  String? userName;
  String? userIc;
  String? userEmail;
  String? userPhone;
  String? userAddress;
  String? memberSince;
  String? userId;
  String? accountStatus;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final token = response.data['token'] ?? '';
        userName = response.data['user']['full_name'] ?? 'User';
        userIc = response.data['user']['ic_no'] ?? '';
        userEmail = response.data['user']['email'] ?? '';
        userPhone = response.data['user']['phone_no'] ?? '';
        userAddress = response.data['user']['address'] ?? '';
        await StorageUtil.saveToken(token);
        print('Token saved: $token');
        isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.register, data);
      isLoading = false;
      notifyListeners();
      return response.data['success'] ?? false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAccountInfo() async {
    try {
      final response = await _api.get(ApiConstants.userProfile);
      
      if (response.data['success']) {
        memberSince = response.data['account_info']['member_since'];
        userId = response.data['account_info']['user_id'];
        accountStatus = response.data['account_info']['status'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching account info: $e');
    }
  }

  Future<void> logout() async {
    try {
      await StorageUtil.clearToken();
      userName = null;
      userIc = null;
      userEmail = null;
      userPhone = null;
      userAddress = null;
      memberSince = null;
      userId = null;
      accountStatus = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }
}
