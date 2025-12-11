import 'package:flutter/material.dart';
import '../models/aid_program.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AidProgramProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AidProgram> _programs = [];
  bool _isLoading = false;
  String? _error;

  List<AidProgram> get programs => _programs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all aid programs
  Future<void> fetchPrograms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/bantuan');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          final programsList = (data['data'] as List)
              .map((p) => AidProgram.fromJson(p as Map<String, dynamic>))
              .toList();
          _programs = programsList;
          _error = null;
        }
      } else {
        _error = 'Failed to fetch programs';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create new aid program
  Future<bool> createProgram(AidProgram program) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/admin/bantuan',
        {
          'title': program.title,
          'description': program.description,
          'criteria': program.eligibilityCriteria,
          'start_date': program.startDate.toIso8601String().split('T')[0],
          'end_date': program.endDate.toIso8601String().split('T')[0],
          'status': program.status == 'active' ? 'Active' : program.status == 'inactive' ? 'Inactive' : 'Active',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newProgram = AidProgram.fromJson(response.data['data'] as Map<String, dynamic>);
        _programs.add(newProgram);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create program';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update aid program
  Future<bool> updateProgram(AidProgram program) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/admin/bantuan/${program.id}',
        {
          'title': program.title,
          'description': program.description,
          'criteria': program.eligibilityCriteria,
          'start_date': program.startDate.toIso8601String().split('T')[0],
          'end_date': program.endDate.toIso8601String().split('T')[0],
          'status': program.status == 'active' ? 'Active' : program.status == 'inactive' ? 'Inactive' : 'Active',
        },
      );

      if (response.statusCode == 200) {
        final index = _programs.indexWhere((p) => p.id == program.id);
        if (index != -1) {
          _programs[index] = AidProgram.fromJson(response.data['data'] as Map<String, dynamic>);
        }
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update program';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete aid program
  Future<bool> deleteProgram(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete(
        '${ApiConstants.baseUrl}/admin/bantuan/$id',
      );

      if (response.statusCode == 200) {
        _programs.removeWhere((p) => p.id == id);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete program';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
