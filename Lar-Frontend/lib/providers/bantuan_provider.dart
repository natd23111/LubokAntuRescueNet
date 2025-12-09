import 'package:flutter/material.dart';
import '../models/bantuan_program.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class BantuanProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<BantuanProgram> programs = [];
  bool isLoading = false;

  // Fetch all programs (for residents)
  Future<void> fetchPrograms() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.bantuanList);
      programs = (response.data['data'] as List)
          .map((e) => BantuanProgram.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching bantuan programs: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // Admin actions (optional for later)
  Future<bool> createProgram(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.createBantuan, data);
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error creating program: $e');
      return false;
    }
  }

  Future<bool> updateProgram(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('${ApiConstants.updateBantuan}/$id', data);
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error updating program: $e');
      return false;
    }
  }

  Future<bool> deleteProgram(int id) async {
    try {
      final response = await _api.delete('${ApiConstants.deleteBantuan}/$id');
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error deleting program: $e');
      return false;
    }
  }
}
