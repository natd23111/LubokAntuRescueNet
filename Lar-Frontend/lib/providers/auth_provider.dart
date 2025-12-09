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

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final token = response.data['user']['token'] ?? '';
        userName = response.data['user']['full_name'] ?? 'User';
        userIc = response.data['user']['ic_no'] ?? '';
        userEmail = response.data['user']['email'] ?? '';
        userPhone = response.data['user']['phone_no'] ?? '';
        await StorageUtil.saveToken(token);
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

  Future<void> logout() async {
    try {
      await StorageUtil.clearToken();
      userName = null;
      userIc = null;
      userEmail = null;
      userPhone = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }
}
